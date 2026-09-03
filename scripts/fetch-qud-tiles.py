#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["pillow"]
# ///
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

from PIL import Image

API = "https://wiki.cavesofqud.com/api.php"
USER_AGENT = "nvim-dashboard-qud-tiles/1.0 (personal dashboard; tom.hooper@starboard.nz)"
OUT_DIR = Path.home() / ".local/share/qud-tiles"
TILE_W, TILE_H, UPSCALE, SCALE = 16, 24, 10, 2
REQUEST_GAP = 0.2


def fetch(url, params=None):
    if params:
        url = f"{url}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
    time.sleep(REQUEST_GAP)
    return data


def api(**params):
    params.update(format="json", formatversion=2)
    return json.loads(fetch(API, params))


def creature_pages():
    titles, cont = [], {}
    while True:
        res = api(action="query", list="embeddedin", eititle="Template:Character", einamespace=0, eilimit=500, **cont)
        titles += [p["title"] for p in res["query"]["embeddedin"]]
        cont = res.get("continue")
        if not cont:
            return titles


def image_names(titles):
    res = api(action="query", prop="revisions", rvprop="content", rvslots="main", titles="|".join(titles))
    out = {}
    for page in res["query"]["pages"]:
        text = page.get("revisions", [{}])[0].get("slots", {}).get("main", {}).get("content", "")
        m = re.search(r"^\|\s*image\s*=\s*(.+?\.png)\s*$", text, re.M | re.I)
        if m:
            out[page["title"]] = m.group(1).strip()
    return out


def image_urls(names):
    res = api(action="query", prop="imageinfo", iiprop="url|size", titles="|".join(f"File:{n}" for n in names))
    original = {n["to"]: n["from"] for n in res["query"].get("normalized", [])}
    urls = {}
    for page in res["query"]["pages"]:
        info = page.get("imageinfo")
        if not info:
            continue
        info = info[0]
        if (info["width"], info["height"]) != (TILE_W * UPSCALE, TILE_H * UPSCALE):
            continue
        title = original.get(page["title"], page["title"])
        urls[title.removeprefix("File:")] = info["url"]
    return urls


def render(png_bytes):
    img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    px = [[img.getpixel((x * UPSCALE + UPSCALE // 2, y * UPSCALE + UPSCALE // 2)) for x in range(TILE_W)] for y in range(TILE_H)]
    rows = [r for r in px for _ in range(SCALE)]
    lines = []
    for top, bottom in zip(rows[0::2], rows[1::2]):
        line = []
        for t, b in zip(top, bottom):
            t_on, b_on = t[3] >= 128, b[3] >= 128
            if t_on and b_on and t == b:
                cell = f"\x1b[38;2;{t[0]};{t[1]};{t[2]}m█\x1b[0m"
            elif t_on and b_on:
                cell = f"\x1b[38;2;{t[0]};{t[1]};{t[2]}m\x1b[48;2;{b[0]};{b[1]};{b[2]}m▀\x1b[0m"
            elif t_on:
                cell = f"\x1b[38;2;{t[0]};{t[1]};{t[2]}m▀\x1b[0m"
            elif b_on:
                cell = f"\x1b[38;2;{b[0]};{b[1]};{b[2]}m▄\x1b[0m"
            else:
                cell = " "
            line.append(cell * SCALE)
        lines.append("".join(line).rstrip())
    return "\n".join(lines) + "\n"


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    titles = creature_pages()
    print(f"{len(titles)} creature pages", file=sys.stderr)
    written = skipped = missing = 0
    for i in range(0, len(titles), 50):
        batch = titles[i : i + 50]
        names = image_names(batch)
        urls = image_urls(list(names.values()))
        for title, name in names.items():
            out = OUT_DIR / f"{title.replace('/', '-')}.txt"
            if out.exists():
                skipped += 1
                continue
            url = urls.get(name)
            if not url:
                missing += 1
                continue
            out.write_text(render(fetch(url)))
            written += 1
        print(f"{i + len(batch)}/{len(titles)} pages: {written} written, {skipped} already present, {missing} without a 16x24 tile", file=sys.stderr)


if __name__ == "__main__":
    main()

#!/bin/sh
WIDTH="${1:-60}"
TILES="$HOME/.local/share/qud-tiles"

tile="$(find "$TILES" -name '*.txt' 2>/dev/null | sort -R | head -n 1)"
if [ -z "$tile" ]; then
  echo "No Qud tiles found. Run: uv run $(dirname "$0")/fetch-qud-tiles.py"
  exit 0
fi

python3 -c "
import re, sys

width, path = int(sys.argv[1]), sys.argv[2]
name = path.rsplit('/', 1)[-1].removesuffix('.txt')
lines = open(path).read().rstrip('\n').splitlines()
while lines and not lines[-1].strip():
    lines.pop()
strip = lambda s: re.sub(r'\x1b\[[0-9;]*m', '', s)
center = lambda l, w: ' ' * max(0, (width - w) // 2) + l
sprite_w = max(len(strip(l)) for l in lines)
out = [center(l, sprite_w) for l in lines] + ['', center(f'\x1b[38;2;147;153;178m{name}\x1b[0m', len(name))]
sys.stdout.write('\n'.join(out) + '\n')
" "$WIDTH" "$tile"

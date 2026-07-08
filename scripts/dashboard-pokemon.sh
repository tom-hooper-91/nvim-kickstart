#!/bin/sh
# Random gen-1 pokemon for the snacks dashboard, centered to the pane width.
# Centering is done here because snacks terminal sections render raw pty
# output left-aligned (indent can only shift by a fixed amount, and sprite
# widths vary). Visible width is measured with ANSI color codes stripped.
WIDTH="${1:-60}"

python3 "$HOME/.local/share/pokemon-colorscripts/pokemon-colorscripts.py" -r 1 --no-title | python3 -c "
import re, sys

width = int(sys.argv[1])
lines = sys.stdin.read().splitlines()
strip = lambda s: re.sub(r'\x1b\[[0-9;]*m', '', s)
vis = max((len(strip(l)) for l in lines), default=0)
pad = ' ' * max(0, (width - vis) // 2)
sys.stdout.write('\n'.join(pad + l for l in lines) + '\n')
" "$WIDTH"

# let the pty flush before snacks captures the output
sleep .1

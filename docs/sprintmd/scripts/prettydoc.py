#!/usr/bin/env python3
"""prettydoc — align tab-delimited table blocks to fixed tab stops.

Type one tab between cells; this pads each cell with tabs so every column
starts at a shared stop, and the raw file lines up at tab width W (default 4).

  ./docs/sprintmd/scripts/prettydoc.py docs/guides/*.md   # rewrite in place
  ./docs/sprintmd/scripts/prettydoc.py -                  # stdin -> stdout

A block is consecutive lines that each contain a tab; blank/prose lines break
blocks, so keep one blank line around every table. See the "Doc Style" guide
(docs/sprintmd/guides/doc-style.md) for how to write docs this tool formats.
"""
import sys, re

W = 4

def _tabs_to(pos, target):
    n = 0
    while pos < target:
        pos = (pos // W + 1) * W
        n += 1
    return n

def _align_block(rows):
    grids = [re.split(r'\t+', r.rstrip('\n')) for r in rows]
    ncols = max(len(g) for g in grids)
    maxw = [0] * ncols
    for g in grids:
        for j, cell in enumerate(g):
            maxw[j] = max(maxw[j], len(cell))
    start = [0] * (ncols + 1)
    for j in range(ncols):
        start[j + 1] = ((start[j] + maxw[j]) // W + 1) * W
    out = []
    for g in grids:
        line = ''
        for j, cell in enumerate(g):
            line += cell
            if j < len(g) - 1:  # no trailing tabs after the last filled cell
                line += '\t' * _tabs_to(start[j] + len(cell), start[j + 1])
        out.append(line + '\n')
    return out

def align(text):
    out, block = [], []
    for ln in text.splitlines(keepends=True):
        if '\t' in ln:
            block.append(ln)
        else:
            if block:
                out += _align_block(block); block = []
            out.append(ln)
    if block:
        out += _align_block(block)
    return ''.join(out)

def main(argv):
    if not argv:
        print(__doc__); return 1
    for path in argv:
        if path == '-':
            sys.stdout.write(align(sys.stdin.read())); continue
        with open(path) as f:
            aligned = align(f.read())
        with open(path, 'w') as f:
            f.write(aligned)
        print(f'aligned {path}')
    return 0

sys.exit(main(sys.argv[1:]))

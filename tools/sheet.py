#!/usr/bin/env python3
"""Tile PNGs into one contact sheet: tools/sheet.py out.png cols cellpx a.png b.png ..."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build import png_read, png_write


def sheet(out, cols, cell, files):
    rows = (len(files) + cols - 1) // cols
    W, H = cols * (cell + 6) + 6, rows * (cell + 6) + 6
    buf = [[128] * W for _ in range(H)]
    for i, f in enumerate(files):
        if not os.path.exists(f):
            continue
        w, h, px = png_read(f)
        ox, oy = 6 + (i % cols) * (cell + 6), 6 + (i // cols) * (cell + 6)
        for y in range(cell):
            for x in range(cell):
                buf[oy + y][ox + x] = px[y * h // cell][x * w // cell]
    png_write(out, W, H, lambda x, y: (buf[y][x], buf[y][x], buf[y][x], 255))


if __name__ == "__main__":
    sheet(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4:])

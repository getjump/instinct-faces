#!/usr/bin/env python3
"""Build the static gallery for GitHub Pages into _site/.

  tools/gallery.py                      build into _site/
  tools/gallery.py --out DIR            build elsewhere
  tools/gallery.py --repo owner/name    repository for download and source links
  tools/gallery.py --sheet docs/faces.png   also tile every face for the README

The gallery runs every design live in a sandboxed iframe and shows the frames
captured from the watch build. Standard library only, no SDK needed.
"""

import argparse
import html
import json
import os
import re
import shutil
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build import ROOT, png_read, png_write
from check import faces

SECTIONS = [
    ("originals", "Originals"),
    ("dither", "Dither studies"),
    ("live", "Living things"),
    ("sky", "Sky and physics"),
    ("geek", "Geek"),
    ("type", "Type and geometry"),
    ("data", "Data as a picture"),
    ("algo", "Algorithms and math"),
    ("toys", "Toys"),
    ("nomad", "For the nomad"),
    ("dclassic", "Digital classics, reimagined"),
    ("aclassic", "Analog classics, reimagined"),
    ("jtype", "Japanese typography"),
    ("scripts", "Scripts and glyphs"),
]
EXTRA_SECTION = {"Ascent": "dither"}
DISPLAY = '<svg x="32" y="52" width="176" height="176"'
SIZE = 176
SCREEN = {"light": ((0x16, 0x17, 0x13), (0xC6, 0xC9, 0xBC)), "dark": ((0xD7, 0xDA, 0xCD), (0x14, 0x15, 0x12))}


def read(path):
    with open(path, encoding="utf8") as f:
        return f.read()


def parse_design(name):
    text = read(os.path.join(ROOT, "design", f"{name}.dc.html"))
    if "<x-dc>" not in text:
        return None
    helmet = text[text.index("<helmet>") + 8 : text.index("</helmet>")]
    template = text[text.index("</helmet>") + 9 : text.index("</x-dc>")].strip()
    template = template.replace("background: #e4e2dc", "background: transparent")
    template = re.sub(r' aria-label="[^"]*"', "", template, count=1)
    m = re.search(r"<script type=\"text/x-dc\" data-dc-script data-props='([^']*)'>(.*?)</script>", text, re.S)
    props, script = {}, ""
    if m:
        props = json.loads(html.unescape(m.group(1)))
        script = m.group(2).strip()
    props.pop("$preview", None)
    for spec in props.values():
        spec.pop("section", None)
    fonts = re.findall(r'<link rel="stylesheet" href="(https://fonts\.googleapis\.com/[^"]+)"', helmet)
    styles = re.findall(r"<style>(.*?)</style>", helmet, re.S)
    return {
        "fonts": [html.unescape(f) for f in fonts],
        "style": "\n".join(styles),
        "template": template,
        "script": script,
        "props": props,
    }


def split_display(template):
    start = template.index(DISPLAY)
    depth, pos = 0, start
    for m in re.finditer(r"<svg\b|</svg>", template[start:]):
        depth += 1 if m.group(0) == "<svg" else -1
        if depth == 0:
            pos = start + m.end()
            break
    return template[:start], template[start:pos], template[pos:]


def case_template(design):
    before, _, after = split_display(design["template"])
    case = before + "{{display}}" + after
    case = re.sub(r"^<div[^>]*>\s*|\s*</div>\s*$", "", case)
    case = case.replace(' role="img"', ' aria-hidden="true"')
    return case.replace(' width="480" height="560"', "", 1)


def canvas_sections():
    canvas = json.loads(read(os.path.join(ROOT, "design", "canvas.json")))
    notes = sorted(
        ((n["y"], key) for key, n in canvas["notes"].items() if key in dict(SECTIONS)),
        key=lambda item: item[0],
    )
    order = [b[: -len(".dc.html")] for b in canvas["order"]]
    out = {}
    for board, spec in canvas["boards"].items():
        name = board[: -len(".dc.html")]
        section = "originals"
        for y, key in notes:
            if spec["y"] >= y:
                section = key
        out[name] = section
    return out, order


def repo_slug(explicit):
    if explicit:
        return explicit
    if os.environ.get("GITHUB_REPOSITORY"):
        return os.environ["GITHUB_REPOSITORY"]
    try:
        url = subprocess.run(
            ["git", "remote", "get-url", "origin"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return None
    m = re.search(r"github\.com[:/]([^/]+/[^/.]+?)(?:\.git)?$", url)
    return m.group(1) if m else None


def write_frames(name, out):
    src = os.path.join(ROOT, "previews", f"{name}.png")
    w, h, px = png_read(src)
    scale = h // SIZE
    for label, x0 in (("awake", 0), ("asleep", w - h)):
        frame = [[px[y * scale][x0 + x * scale] >= 128 for x in range(SIZE)] for y in range(SIZE)]
        for mode, (ink, paper) in SCREEN.items():

            def rgba(x, y, frame=frame, ink=ink, paper=paper):
                return (*(paper if frame[y][x] else ink), 255)

            png_write(os.path.join(out, f"{name}.{label}.{mode}.png"), SIZE, SIZE, rgba)


def contact_sheet(index, path, cols=10, gap=12, mode="light"):
    names = [f["name"] for f in index["faces"]]
    rows = (len(names) + cols - 1) // cols
    width, height = cols * (SIZE + gap) - gap, rows * (SIZE + gap) - gap
    ink, paper = SCREEN[mode]
    cells = {}
    for i, name in enumerate(names):
        w, h, px = png_read(os.path.join(ROOT, "previews", f"{name}.png"))
        scale = h // SIZE
        cells[i] = [[px[y * scale][x * scale] >= 128 for x in range(SIZE)] for y in range(SIZE)]

    def rgba(x, y):
        cx, ox = divmod(x, SIZE + gap)
        cy, oy = divmod(y, SIZE + gap)
        cell = cells.get(cy * cols + cx)
        if cell is None or ox >= SIZE or oy >= SIZE:
            return (0, 0, 0, 0)
        return (*(paper if cell[oy][ox] else ink), 255)

    png_write(path, width, height, rgba)


def build(out, repo):
    shutil.rmtree(out, ignore_errors=True)
    shutil.copytree(os.path.join(ROOT, "site"), out)
    for sub in ("designs", "frames", "refs"):
        os.makedirs(os.path.join(out, sub))
    sections, order = canvas_sections()
    rank = {n: i for i, n in enumerate(order)}
    entries, fonts, case = [], set(), None
    for name in faces():
        meta = json.loads(read(os.path.join(ROOT, "faces", name, "face.json")))
        design = parse_design(name)
        if design:
            json.dump(design, open(os.path.join(out, "designs", f"{name}.json"), "w"), ensure_ascii=False)
            fonts.update(design["fonts"])
            if case is None and name == "Main":
                case = case_template(design)
        write_frames(name, os.path.join(out, "frames"))
        shutil.copy(os.path.join(ROOT, "refs", f"{name}.png"), os.path.join(out, "refs", f"{name}.png"))
        entries.append(
            {
                "name": name,
                "title": meta["title"],
                "section": sections.get(name) or EXTRA_SECTION.get(name, "originals"),
                "fake": meta.get("fake"),
                "permissions": meta.get("permissions", []),
                "design": bool(design),
                "animated": bool(design and re.search(r"\bDate\b|setInterval", design["script"])),
                "props": design["props"] if design else {},
            }
        )
    entries.sort(key=lambda e: ([k for k, _ in SECTIONS].index(e["section"]), rank.get(e["name"], len(rank))))
    index = {
        "repo": repo,
        "sections": [{"id": k, "title": t} for k, t in SECTIONS],
        "case": case,
        "faces": entries,
    }
    json.dump(index, open(os.path.join(out, "faces.json"), "w"), ensure_ascii=False, indent=1)
    return index


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "_site"))
    ap.add_argument("--repo")
    ap.add_argument("--sheet", metavar="PNG", help="also write a contact sheet of every face, e.g. docs/faces.png")
    args = ap.parse_args()
    index = build(args.out, repo_slug(args.repo))
    if args.sheet:
        contact_sheet(index, args.sheet)
    animated = sum(f["animated"] for f in index["faces"])
    out = os.path.relpath(args.out)
    print(f"site: {len(index['faces'])} faces, {animated} animated, repo={index['repo']} -> {out}")


if __name__ == "__main__":
    main()

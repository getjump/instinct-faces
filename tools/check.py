#!/usr/bin/env python3
"""Static checks for every face, runnable without the Connect IQ SDK.

  tools/check.py            check all faces, exit 1 on any problem
  tools/check.py Main LLife check these faces only

Standard library only.
"""

import json
import os
import re
import subprocess
import sys
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FACE_KEYS = {"title", "fonts", "permissions", "fake"}
FONT_KEYS = {"family", "size", "chars", "sx", "fit", "weight", "t", "tracking", "style"}
PERMISSIONS = {
    "Background",
    "Communications",
    "ComplicationPublisher",
    "ComplicationSubscriber",
    "FitContributor",
    "Positioning",
    "SensorHistory",
    "UserProfile",
}
STRING = re.compile(r'"(?:[^"\\\n]|\\.)*"')
SECRET = re.compile(r"(^|/)\.keys/|\.(der|pem|p12|key)$")


def faces():
    base = os.path.join(ROOT, "faces")
    return sorted(d for d in os.listdir(base) if os.path.isdir(os.path.join(base, d)))


def read(path):
    with open(path, encoding="utf8") as f:
        return f.read()


def font_families(name):
    path = os.path.join(ROOT, "design", f"{name}.dc.html")
    if not os.path.exists(path):
        return set()
    found = set()
    for href in re.findall(r'href="(https://fonts\.googleapis\.com/[^"]+)"', read(path)):
        query = urllib.parse.parse_qs(urllib.parse.urlparse(href.replace("&amp;", "&")).query)
        for fam in query.get("family", []):
            found.add(fam.split(":")[0].replace("+", " "))
    return found


def check_meta(name, meta):
    out = []
    unknown = set(meta) - FACE_KEYS
    if unknown:
        out.append(f"face.json: unknown keys {sorted(unknown)}")
    title = meta.get("title")
    if not isinstance(title, str) or not title.strip():
        out.append("face.json: title must be a non-empty string")
    elif not title.isascii():
        out.append("face.json: title must be ASCII, the watch face list has no other glyphs")
    perms = meta.get("permissions", [])
    if not isinstance(perms, list) or any(p not in PERMISSIONS for p in perms):
        out.append(f"face.json: permissions must be a list of {sorted(PERMISSIONS)}")
    if "fake" in meta and (not isinstance(meta["fake"], str) or not meta["fake"].strip()):
        out.append("face.json: fake must be a short non-empty string")
    fonts = meta.get("fonts", {})
    if not isinstance(fonts, dict):
        return out + ["face.json: fonts must be an object"]
    families = font_families(name)
    for fid, spec in fonts.items():
        where = f"face.json: font {fid}"
        if not re.fullmatch(r"[a-z][a-z0-9_]*", fid):
            out.append(f"{where}: id must be lower_snake_case")
        if not isinstance(spec, dict):
            out.append(f"{where}: must be an object")
            continue
        unknown = set(spec) - FONT_KEYS
        if unknown:
            out.append(f"{where}: unknown keys {sorted(unknown)}")
        if not isinstance(spec.get("family"), str):
            out.append(f"{where}: family is required")
        elif families and spec["family"] not in families:
            out.append(f"{where}: family {spec['family']!r} is not in the design's Google Fonts link")
        if not isinstance(spec.get("size"), (int, float)) or spec["size"] <= 0:
            out.append(f"{where}: size must be a positive number")
        fit = spec.get("fit")
        if fit is not None and not (
            isinstance(fit, list) and len(fit) == 2 and isinstance(fit[0], str) and isinstance(fit[1], (int, float))
        ):
            out.append(f'{where}: fit must be ["sample", width]')
    return out


def check_source(name):
    out = []
    src = os.path.join(ROOT, "faces", name, "source")
    view = os.path.join(src, "View.mc")
    if not os.path.exists(view):
        return ["source/View.mc is missing"]
    if not re.search(r"\bclass\s+FaceView\s+extends\s+BaseFace\b", read(view)):
        out.append("source/View.mc: FaceView must extend BaseFace")
    for fname in sorted(os.listdir(src)):
        if not fname.endswith(".mc"):
            continue
        for no, line in enumerate(read(os.path.join(src, fname)).splitlines(), 1):
            code = STRING.sub('""', line)
            if not code.isascii():
                out.append(f"source/{fname}:{no}: non-ASCII outside a string literal")
            if re.search(r"\bCOLOR_(BLACK|WHITE)\b", code):
                out.append(f"source/{fname}:{no}: use G.ink/G.paper, not COLOR_BLACK/COLOR_WHITE")
    return out


def check_art(name):
    out = []
    art = os.path.join(ROOT, "faces", name, "art")
    if not os.path.isdir(art):
        return out
    for fname in sorted(os.listdir(art)):
        if not fname.endswith(".svg"):
            continue
        rid = fname[:-6] if fname.endswith(".t.svg") else fname[:-4]
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", rid):
            out.append(f"art/{fname}: resource id must be an identifier")
        if not re.search(r'<svg[^>]*\bwidth="\d+"[^>]*\bheight="\d+"', read(os.path.join(art, fname))):
            out.append(f"art/{fname}: the root <svg> needs integer width and height")
    return out


def check_assets(name):
    want = [f"design/{name}.dc.html", f"refs/{name}.png", f"previews/{name}.png"]
    return [f"{rel} is missing" for rel in want if not os.path.exists(os.path.join(ROOT, rel))]


def check_face(name):
    path = os.path.join(ROOT, "faces", name, "face.json")
    if not os.path.exists(path):
        return ["face.json is missing"]
    try:
        meta = json.loads(read(path))
    except json.JSONDecodeError as e:
        return [f"face.json: {e}"]
    if not isinstance(meta, dict):
        return ["face.json: must be an object"]
    return check_meta(name, meta) + check_source(name) + check_art(name) + check_assets(name)


def check_repo():
    out = []
    try:
        tracked = subprocess.run(
            ["git", "ls-files", "-z"], cwd=ROOT, capture_output=True, text=True, check=True
        ).stdout.split("\0")
    except (OSError, subprocess.CalledProcessError):
        tracked = []
    out += [f"{p}: signing keys must never be committed" for p in tracked if p and SECRET.search(p)]
    for rel in ("core/source/Base.mc", "core/source/Data.mc"):
        for no, line in enumerate(read(os.path.join(ROOT, rel)).splitlines(), 1):
            if not STRING.sub('""', line).isascii():
                out.append(f"{rel}:{no}: non-ASCII outside a string literal")
    return out


def main(argv):
    names = argv or faces()
    problems = [(None, p) for p in check_repo()] if not argv else []
    for name in names:
        problems += [(name, p) for p in check_face(name)]
    for name, p in problems:
        print(f"{name}: {p}" if name else p)
    print(f"checked {len(names)} faces: {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

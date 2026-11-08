#!/usr/bin/env python3
"""Build Connect IQ watch faces: bake art and fonts in headless Chromium, generate
the project, compile to dist/<Name>.prg.

  tools/build.py Main LLife        build these faces
  tools/build.py --all             build every folder under faces/
  tools/build.py --dark Main       inverted variant, dist/<Name>-dark.prg
  tools/build.py --debug Main      keep debug info, for the simulator
  tools/build.py --no-bake Main    reuse art and fonts baked earlier

Standard library only.
"""

import argparse
import glob
import html
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import uuid
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEVICE = os.environ.get("CIQ_DEVICE", "instinct3solar45mm")
CIQ = os.path.expanduser(
    os.environ.get("CIQ_HOME")
    or ("~/Library/Application Support/Garmin/ConnectIQ" if sys.platform == "darwin" else "~/.Garmin/ConnectIQ")
)
UUID_NS = uuid.UUID("7d2f6a54-0c55-4f1e-9a57-3f6f1d1a2b10")
CHARSETS = {
    "$digits": "0123456789",
    "$time": "0123456789:",
    "$upper": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "$lower": "abcdefghijklmnopqrstuvwxyz",
    "$ascii": "".join(chr(c) for c in range(32, 127)),
}


def sdk_bin(tool):
    with open(os.path.join(CIQ, "current-sdk.cfg")) as f:
        return os.path.join(f.read().strip(), "bin", tool)


def chrome():
    if os.environ.get("CHROME_BIN"):
        return os.environ["CHROME_BIN"]
    found = []
    for cache in ("~/Library/Caches/ms-playwright", "~/.cache/ms-playwright"):
        pattern = f"{cache}/chromium_headless_shell-*/chrome-headless-shell-*/chrome-headless-shell"
        found += glob.glob(os.path.expanduser(pattern))
    if not found:
        sys.exit(
            "chrome-headless-shell not found: run `npx playwright install chromium-headless-shell` or set CHROME_BIN"
        )
    return sorted(found)[-1]


def chrome_args(extra):
    profile = os.path.join(ROOT, "build", ".chrome-profile")
    os.makedirs(profile, exist_ok=True)
    return [
        chrome(),
        "--hide-scrollbars",
        "--disable-gpu",
        "--disable-lcd-text",
        "--no-first-run",
        "--force-device-scale-factor=1",
        "--font-render-hinting=none",
        f"--user-data-dir={profile}",
        "--virtual-time-budget=20000",
    ] + extra


def png_read(path):
    with open(path, "rb") as f:
        data = f.read()
    pos, idat, w, h, ct, bd = 8, b"", 0, 0, 0, 0
    palette = None
    while pos < len(data):
        n, typ = struct.unpack(">I4s", data[pos : pos + 8])
        chunk = data[pos + 8 : pos + 8 + n]
        if typ == b"IHDR":
            w, h, bd, ct = struct.unpack(">IIBB", chunk[:10])
        elif typ == b"IDAT":
            idat += chunk
        elif typ == b"PLTE":
            palette = chunk
        pos += 12 + n
    if bd != 8:
        sys.exit(f"{path}: unsupported bit depth {bd}")
    ch = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ct]
    raw = zlib.decompress(idat)
    stride = w * ch
    prev = bytearray(stride)
    rows, p = [], 0
    for _ in range(h):
        flt = raw[p]
        line = bytearray(raw[p + 1 : p + 1 + stride])
        p += 1 + stride
        for i in range(stride):
            a = line[i - ch] if i >= ch else 0
            b = prev[i]
            c = prev[i - ch] if i >= ch else 0
            if flt == 1:
                line[i] = (line[i] + a) & 255
            elif flt == 2:
                line[i] = (line[i] + b) & 255
            elif flt == 3:
                line[i] = (line[i] + (a + b) // 2) & 255
            elif flt == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(line)
        prev = line
    px = []
    for line in rows:
        row = []
        for x in range(w):
            if ct == 3:
                i = line[x] * 3
                r, g, b = palette[i], palette[i + 1], palette[i + 2]
            elif ct in (0, 4):
                r = g = b = line[x * ch]
            else:
                r, g, b = line[x * ch], line[x * ch + 1], line[x * ch + 2]
            row.append((r * 299 + g * 587 + b * 114) // 1000)
        px.append(row)
    return w, h, px


def png_write(path, w, h, rgba):
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            raw += bytes(rgba(x, y))
    with open(path, "wb") as f:
        f.write(
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b"")
        )


def design_font_link(name):
    path = os.path.join(ROOT, "design", f"{name}.dc.html")
    if not os.path.exists(path):
        return ""
    m = re.search(r'<link rel="stylesheet" href="(https://fonts\.googleapis[^"]+)"', open(path, encoding="utf8").read())
    return f'<link rel="stylesheet" href="{m.group(1)}">' if m else ""


def bake_art(name, face_dir, out, dark):
    entries = []
    for svg in sorted(glob.glob(os.path.join(face_dir, "art", "*.svg"))):
        base = os.path.basename(svg)[:-4]
        transparent = base.endswith(".t")
        rid = base[:-2] if transparent else base
        text = open(svg, encoding="utf8").read()
        m = re.search(r'<svg[^>]*\bwidth="(\d+)"[^>]*\bheight="(\d+)"', text)
        if not m:
            sys.exit(f"{svg}: the root <svg> needs integer width and height")
        w, h = int(m.group(1)), int(m.group(2))
        page = (
            f'<!doctype html><html><head><meta charset="utf-8">{design_font_link(name)}'
            f"<style>html,body{{margin:0;padding:0;background:#fff}}svg{{display:block;color:#000}}</style>"
            f"</head><body>{text}</body></html>"
        )
        with tempfile.TemporaryDirectory() as tmp:
            hp, shot = os.path.join(tmp, "p.html"), os.path.join(tmp, "s.png")
            open(hp, "w", encoding="utf8").write(page)
            subprocess.run(
                chrome_args([f"--window-size={max(w, 64)},{max(h, 64)}", f"--screenshot={shot}", f"file://{hp}"]),
                check=True,
                capture_output=True,
                timeout=120,
            )
            _, _, px = png_read(shot)

        def rgba(x, y, px=px, transparent=transparent):
            ink = px[y][x] < 128
            if transparent and not ink:
                return (0, 0, 0, 0)
            if dark:
                ink = not ink
            return (0, 0, 0, 255) if ink else (255, 255, 255, 255)

        png_write(os.path.join(out, f"{rid}.png"), w, h, rgba)
        entries.append(f'  <bitmap id="{rid}" filename="{rid}.png" dithering="none"/>')
    return entries


FONT_PAGE = """<!doctype html><html><head><meta charset="utf-8">%s</head><body><pre id="out"></pre><script>
const specs = %s;
(async () => {
  const res = {};
  for (const id of Object.keys(specs)) {
    const s = specs[id], css = `${s.style || 'normal'} ${s.weight || 400} ${s.size}px "${s.family}"`;
    await document.fonts.load(css, s.chars);
    const mg = document.createElement('canvas').getContext('2d'); mg.font = css; mg.fontKerning = 'none';
    const sx = s.fit ? s.fit[1] / mg.measureText(s.fit[0]).width : (s.sx || 1), pad = Math.ceil(s.size * 0.5);
    const W = Math.ceil(s.size * 2.5 * sx) + 2 * pad, H = Math.ceil(s.size * 2.4), B = Math.ceil(s.size * 1.6);
    const c = document.createElement('canvas'); c.width = W; c.height = H;
    const g = c.getContext('2d', {willReadFrequently: true});
    const glyphs = [];
    for (const ch of s.chars) {
      g.setTransform(1, 0, 0, 1, 0, 0); g.clearRect(0, 0, W, H);
      g.setTransform(sx, 0, 0, 1, pad, B);
      g.font = css; g.fontKerning = 'none'; g.textBaseline = 'alphabetic'; g.fillStyle = '#000';
      g.fillText(ch, 0, 0);
      const adv = g.measureText(ch).width * sx, d = g.getImageData(0, 0, W, H).data, t = 255 * (s.t || 0.5);
      let x0 = W, y0 = H, x1 = -1, y1 = -1;
      for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) if (d[(y * W + x) * 4 + 3] >= t) {
        if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
      }
      const rows = [];
      if (x1 >= 0) for (let y = y0; y <= y1; y++) {
        let r = '';
        for (let x = x0; x <= x1; x++) r += d[(y * W + x) * 4 + 3] >= t ? '1' : '0';
        rows.push(r);
      }
      glyphs.push({code: ch.codePointAt(0), adv, x: x1 >= 0 ? x0 - pad : 0, y: x1 >= 0 ? y0 - B : 0, rows});
    }
    res[id] = glyphs;
  }
  document.getElementById('out').textContent = JSON.stringify(res);
})();
</script></body></html>"""


def unique_chars(spec):
    chars = spec.get("chars", "$ascii")
    for key, val in CHARSETS.items():
        chars = chars.replace(key, val)
    seen = []
    for ch in chars:
        if ch not in seen:
            seen.append(ch)
    if " " not in seen:
        seen.append(" ")
    return "".join(seen)


def bake_fonts(name, fonts, out, gen):
    if not fonts:
        return [], "module F {\n  function load() as Void {}\n}\n"
    specs = {}
    for fid, sp in fonts.items():
        specs[fid] = dict(sp, chars=unique_chars(sp))
    page = FONT_PAGE % (design_font_link(name), json.dumps(specs, ensure_ascii=False))
    with tempfile.TemporaryDirectory() as tmp:
        hp = os.path.join(tmp, "p.html")
        open(hp, "w", encoding="utf8").write(page)
        run = subprocess.run(chrome_args(["--dump-dom", f"file://{hp}"]), check=True, capture_output=True, timeout=180)
    m = re.search(r'<pre id="out">(.*?)</pre>', run.stdout.decode("utf8"), re.S)
    if not m or not m.group(1):
        sys.exit(f"{name}: font render returned nothing")
    res = json.loads(html.unescape(m.group(1)))
    xml, consts, decl, load = [], [], [], []
    for fid, glyphs in res.items():
        sp = fonts[fid]
        base = max([-g["y"] for g in glyphs if g["rows"]] + [0])
        descent = max([g["y"] + len(g["rows"]) for g in glyphs if g["rows"]] + [0])
        line = base + descent
        tracking = sp.get("tracking", 0)
        sw = 256
        x = y = shelf = 0
        placed = []
        for g in glyphs:
            gw = len(g["rows"][0]) if g["rows"] else 0
            gh = len(g["rows"])
            if x + gw + 1 > sw:
                x, y, shelf = 0, y + shelf + 1, 0
            placed.append((g, x, y, gw, gh))
            x += gw + 1
            shelf = max(shelf, gh)
        sh = max(1, y + shelf + 1)
        ink = [[0] * sw for _ in range(sh)]
        for g, gx, gy, _gw, _gh in placed:
            for r, row in enumerate(g["rows"]):
                for c, bit in enumerate(row):
                    if bit == "1":
                        ink[gy + r][gx + c] = 1
        png_write(
            os.path.join(out, f"{fid}.png"),
            sw,
            sh,
            lambda px, py, ink=ink: (255, 255, 255, 255) if ink[py][px] else (0, 0, 0, 0),
        )
        lines = [
            f'info face="{fid}" size={sp["size"]} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 '
            "padding=0,0,0,0 spacing=0,0",
            f"common lineHeight={line} base={base} scaleW={sw} scaleH={sh} pages=1 packed=0",
            f'page id=0 file="{fid}.png"',
            f"chars count={len(placed)}",
        ]
        for g, gx, gy, gw, gh in placed:
            lines.append(
                f"char id={g['code']} x={gx} y={gy} width={gw} height={gh} xoffset={g['x']} "
                f"yoffset={g['y'] + base if g['rows'] else 0} xadvance={round(g['adv']) + tracking} page=0 chnl=15"
            )
        open(os.path.join(out, f"{fid}.fnt"), "w", encoding="utf8").write("\n".join(lines) + "\n")
        xml.append(f'  <font id="{fid}" filename="{fid}.fnt" antialias="false"/>')
        consts.append(f"  const {fid}_b = {base};")
        decl.append(f"  var {fid} as FontResource or Null = null;")
        load.append(f"    {fid} = WatchUi.loadResource(Rez.Fonts.{fid}) as FontResource;")
    src = (
        "import Toybox.Graphics;\nimport Toybox.WatchUi;\nimport Toybox.Lang;\n\nmodule F {\n"
        + "\n".join(consts + decl)
        + "\n  function load() as Void {\n"
        + "\n".join(load)
        + "\n  }\n}\n"
    )
    return xml, src


def launcher_icon(out, size=62):
    def rgba(x, y):
        d = max(abs(2 * x + 1 - size), abs(2 * y + 1 - size))
        return (0, 0, 0, 255) if d >= size - 6 or d <= size // 3 else (255, 255, 255, 255)

    png_write(os.path.join(out, "launcher.png"), size, size, rgba)


def build_face(name, args):
    face_dir = os.path.join(ROOT, "faces", name)
    meta = json.load(open(os.path.join(face_dir, "face.json"), encoding="utf8"))
    suffix = "-dark" if args.dark else ""
    bdir = os.path.join(ROOT, "build", name + suffix)
    res = os.path.join(bdir, "resources")
    gen = os.path.join(bdir, "gen")
    fragments = os.path.join(bdir, "fragments.json")
    if not args.no_bake or not os.path.exists(fragments):
        shutil.rmtree(bdir, ignore_errors=True)
        os.makedirs(res)
        os.makedirs(gen)
        art = bake_art(name, face_dir, res, args.dark)
        fxml, fsrc = bake_fonts(name, meta.get("fonts", {}), res, gen)
        open(os.path.join(gen, "F.mc"), "w", encoding="utf8").write(fsrc)
        launcher_icon(res)
        json.dump({"art": art, "fonts": fxml}, open(fragments, "w"))
    frag = json.load(open(fragments))
    drawables = "\n".join(['  <bitmap id="LauncherIcon" filename="launcher.png" dithering="none"/>'] + frag["art"])
    open(os.path.join(res, "drawables.xml"), "w", encoding="utf8").write(f"<drawables>\n{drawables}\n</drawables>\n")
    if frag["fonts"]:
        open(os.path.join(res, "fonts.xml"), "w", encoding="utf8").write(
            "<fonts>\n" + "\n".join(frag["fonts"]) + "\n</fonts>\n"
        )
    title = html.escape(meta["title"] + (" D" if args.dark else ""))
    open(os.path.join(res, "strings.xml"), "w", encoding="utf8").write(
        f'<strings>\n  <string id="AppName">{title}</string>\n</strings>\n'
    )
    bg, fg = ("COLOR_BLACK", "COLOR_WHITE") if args.dark else ("COLOR_WHITE", "COLOR_BLACK")
    open(os.path.join(gen, "Theme.mc"), "w", encoding="utf8").write(
        f"import Toybox.Graphics;\n\nmodule Theme {{\n  const BG = Graphics.{bg};\n  const FG = Graphics.{fg};\n"
        f"  const DARK = {str(args.dark).lower()};\n}}\n"
    )
    app_id = uuid.uuid5(UUID_NS, name + suffix).hex
    source = "".join(
        open(os.path.join(face_dir, "source", f), encoding="utf8").read()
        for f in os.listdir(os.path.join(face_dir, "source"))
    )
    needed = set(meta.get("permissions", []))
    if re.search(r"\bD\.(sunTimes|location)\b", source):
        needed.add("Positioning")
    perms = "".join(f'<iq:uses-permission id="{p}"/>' for p in sorted(needed))
    open(os.path.join(bdir, "manifest.xml"), "w", encoding="utf8").write(
        '<?xml version="1.0"?>\n<iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">\n'
        f'  <iq:application id="{app_id}" type="watchface" name="@Strings.AppName" entry="FaceApp" '
        f'launcherIcon="@Drawables.LauncherIcon" minApiLevel="5.0.0" version="1.0.0">\n'
        f'    <iq:products><iq:product id="{DEVICE}"/></iq:products>\n'
        f"    <iq:permissions>{perms}</iq:permissions>\n"
        "    <iq:languages><iq:language>eng</iq:language></iq:languages>\n"
        "    <iq:barrels/>\n  </iq:application>\n</iq:manifest>\n"
    )
    src_dirs = [os.path.join(ROOT, "core", "source"), os.path.join(face_dir, "source"), gen]
    open(os.path.join(bdir, "monkey.jungle"), "w", encoding="utf8").write(
        f"project.manifest = manifest.xml\nbase.sourcePath = {';'.join(src_dirs)}\nbase.resourcePath = resources\n"
    )
    os.makedirs(os.path.join(ROOT, "dist"), exist_ok=True)
    outdir = os.path.join(bdir, "out")
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, f"{name}{suffix}.prg")
    cmd = [
        sdk_bin("monkeyc"),
        "-f",
        os.path.join(bdir, "monkey.jungle"),
        "-d",
        DEVICE,
        "-o",
        out,
        "-y",
        os.path.join(ROOT, ".keys", "developer_key.der"),
        "-w",
    ]
    if not args.debug:
        cmd += ["-r", "-O", "2"]
    run = subprocess.run(cmd, capture_output=True, text=True)
    text = "\n".join(l for l in (run.stdout + run.stderr).splitlines() if "launcher" not in l.lower())
    if run.returncode != 0:
        print(f"FAIL {name}\n{text}")
        return False
    if not args.debug:
        shutil.copy(out, os.path.join(ROOT, "dist", f"{name}{suffix}.prg"))
    warnings = [l for l in text.splitlines() if l.startswith("WARNING")]
    print(f"ok   {name}{suffix}  {os.path.getsize(out)} B" + (f"  warnings={len(warnings)}" if warnings else ""))
    for w in warnings[: args.show_warnings]:
        print("     " + w.replace(ROOT + "/", ""))
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("faces", nargs="*")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--dark", action="store_true")
    ap.add_argument("--debug", action="store_true")
    ap.add_argument("--no-bake", action="store_true")
    ap.add_argument("--show-warnings", type=int, default=5)
    args = ap.parse_args()
    key = os.path.join(ROOT, ".keys", "developer_key.der")
    if not os.path.exists(key):
        os.makedirs(os.path.dirname(key), exist_ok=True)
        pem = key[:-4] + ".pem"
        subprocess.run(["openssl", "genrsa", "-out", pem, "4096"], check=True, capture_output=True)
        subprocess.run(
            ["openssl", "pkcs8", "-topk8", "-inform", "PEM", "-outform", "DER", "-in", pem, "-out", key, "-nocrypt"],
            check=True,
        )
        os.chmod(pem, 0o600)
        os.chmod(key, 0o600)
    names = args.faces or sorted(
        d
        for d in os.listdir(os.path.join(ROOT, "faces"))
        if os.path.exists(os.path.join(ROOT, "faces", d, "face.json"))
    )
    if not args.faces and not args.all:
        sys.exit("name faces or pass --all")
    fails = [n for n in names if not build_face(n, args)]
    print(f"built {len(names) - len(fails)}/{len(names)}" + (f"; failed: {' '.join(fails)}" if fails else ""))
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()

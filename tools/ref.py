#!/usr/bin/env python3
"""Render the original design of a face to refs/<Name>.png (176x176, 1 bit, 3x upscale), running its JS
through a small DCLogic shim so the live values are filled in.

  tools/ref.py Main LLife ...      or      tools/ref.py --all
"""

import json
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build import ROOT, chrome_args, png_read, png_write

PAGE = """<!doctype html><html><head><meta charset="utf-8">%(link)s
<style>html,body{margin:0;padding:0;background:#fff}svg{display:block}</style></head><body><div id="root"></div>
<script>
class DCLogic { constructor(){this.props={};this.state={};} setState(s){Object.assign(this.state,s);} }
%(js)s
const tpl = %(tpl)s;
const c = new Component();
if (c.componentDidMount) c.componentDidMount();
setTimeout(() => {
  const v = c.renderVals();
  v.bg = '#ffffff'; v.ink = '#000000';
  document.getElementById('root').innerHTML = tpl.replace(/\\{\\{\\s*([\\w.]+)\\s*\\}\\}/g, (m, k) => {
    let o = v; for (const p of k.split('.')) o = o == null ? o : o[p];
    return o == null ? '' : String(o);
  });
}, 1500);
</script></body></html>"""


def ref(name):
    t = open(os.path.join(ROOT, "design", f"{name}.dc.html"), encoding="utf8").read()
    m = re.search(r'<svg x="32" y="52".*?</svg>(?=\s*</svg>)', t, re.S)
    svg = m.group(0)
    svg = re.sub(r'<svg x="32" y="52" width="176" height="176"', '<svg width="176" height="176"', svg)
    svg = re.sub(r"<rect [^>]*url\(#[\w-]*grid\)[^>]*></rect>", "", svg)
    svg = re.sub(r'<circle cx="144" cy="32" r="34.5" fill="#111210"></circle>', "", svg)
    link = re.search(r'<link rel="stylesheet" href="(https://fonts\.googleapis[^"]+)"', t)
    js = t[t.find("class Component") : t.rfind("</script>")]
    page = PAGE % {
        "link": f'<link rel="stylesheet" href="{link.group(1)}">' if link else "",
        "js": js,
        "tpl": json.dumps(svg),
    }
    os.makedirs(os.path.join(ROOT, "refs"), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        hp, shot = os.path.join(tmp, "p.html"), os.path.join(tmp, "s.png")
        open(hp, "w", encoding="utf8").write(page)
        subprocess.run(
            chrome_args(["--window-size=176,176", f"--screenshot={shot}", f"file://{hp}"]),
            check=True,
            capture_output=True,
            timeout=120,
        )
        w, h, px = png_read(shot)
    k = 3

    def rgba(x, y):
        v = 0 if px[y // k][x // k] < 128 else 255
        return (v, v, v, 255)

    png_write(os.path.join(ROOT, "refs", f"{name}.png"), 176 * k, 176 * k, rgba)


if __name__ == "__main__":
    names = sys.argv[1:]
    if names == ["--all"]:
        names = [f[:-8] for f in sorted(os.listdir(os.path.join(ROOT, "design"))) if f.endswith(".dc.html")]
    for n in names:
        try:
            ref(n)
            print("ok", n)
        except Exception as e:
            print("FAIL", n, e)

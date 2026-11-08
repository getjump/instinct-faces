#!/usr/bin/env python3
"""Print the display part of designs without the watch case, LCD grid and clip paths, plus their JS.

tools/strip_design.py design Main LLife
"""

import os
import re
import sys


def strip(root, name):
    text = open(os.path.join(root, f"{name}.dc.html"), encoding="utf8").read()
    m = re.search(r'<svg x="32" y="52".*?</svg>\s*</svg>', text, re.S)
    if not m:
        return f"=== {name}\n(no inline design: {name}.dc.html has no display svg)\n"
    body = m.group(0)
    body = re.sub(r'<pattern id="[\w-]*grid".*?</pattern>\s*', "", body, flags=re.S)
    body = re.sub(r"<rect [^>]*url\(#[\w-]*grid\)[^>]*></rect>\s*", "", body)
    body = re.sub(r'<clipPath id="[\w-]*(main|sub)">.*?</clipPath>\s*', "", body, flags=re.S)
    js = text[text.find("class Component") : text.rfind("</script>")]
    return f"=== {name}\n{body}\n--- JS\n{js}"


if __name__ == "__main__":
    for face in sys.argv[2:]:
        print(strip(sys.argv[1], face))

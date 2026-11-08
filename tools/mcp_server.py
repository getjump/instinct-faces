#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.10,<2"]
# ///
"""MCP server for this repository: list and inspect faces, read designs, run checks,
build with the Connect IQ SDK and capture simulator frames.

  uv run --script tools/mcp_server.py      stdio transport, see .mcp.json
"""

import json
import os
import subprocess
import sys

from mcp.server.fastmcp import FastMCP, Image

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)

import check  # noqa: E402
from strip_design import strip  # noqa: E402

mcp = FastMCP("instinct-faces")


def face_dir(name):
    if name not in check.faces():
        raise ValueError(f"unknown face {name!r}; call list_faces")
    return os.path.join(ROOT, "faces", name)


def run(args, timeout):
    proc = subprocess.run(
        [sys.executable, *args], cwd=ROOT, capture_output=True, text=True, timeout=timeout, check=False
    )
    return proc.returncode, (proc.stdout + proc.stderr)[-6000:]


@mcp.tool()
def list_faces() -> list[dict]:
    """List every face with its title, simulated-data note and permissions."""
    out = []
    for name in check.faces():
        meta = json.load(open(os.path.join(ROOT, "faces", name, "face.json"), encoding="utf8"))
        out.append(
            {
                "name": name,
                "title": meta.get("title"),
                "fake": meta.get("fake"),
                "permissions": meta.get("permissions", []),
                "fonts": sorted(meta.get("fonts", {})),
            }
        )
    return out


@mcp.tool()
def face_info(name: str) -> dict:
    """face.json, source and art files, build output and static-check problems of one face."""
    path = face_dir(name)
    prg = os.path.join(ROOT, "dist", f"{name}.prg")
    return {
        "face_json": json.load(open(os.path.join(path, "face.json"), encoding="utf8")),
        "source": sorted(os.listdir(os.path.join(path, "source"))),
        "art": sorted(os.listdir(os.path.join(path, "art"))) if os.path.isdir(os.path.join(path, "art")) else [],
        "prg_bytes": os.path.getsize(prg) if os.path.exists(prg) else None,
        "problems": check.check_face(name),
    }


@mcp.tool()
def read_design(name: str) -> str:
    """The design's 176x176 display SVG and its JS logic, without the watch case and LCD grid."""
    face_dir(name)
    return strip(os.path.join(ROOT, "design"), name)


@mcp.tool()
def check_faces(names: list[str] | None = None) -> dict:
    """Run the static checks (schema, ASCII source, colors, assets, keys). Empty names checks everything."""
    problems = {} if names else {"repo": check.check_repo()}
    for name in names or check.faces():
        problems[name] = check.check_face(name)
    return {k: v for k, v in problems.items() if v} or {"ok": True}


@mcp.tool()
def build_face(name: str, dark: bool = False, debug: bool = False) -> dict:
    """Compile a face with the Connect IQ SDK into dist/<Name>.prg. Needs the SDK and headless Chromium."""
    face_dir(name)
    args = [os.path.join(TOOLS, "build.py"), name] + (["--dark"] if dark else []) + (["--debug"] if debug else [])
    code, log = run(args, timeout=600)
    return {"ok": code == 0, "log": log}


@mcp.tool()
def shoot_face(name: str, preview: bool = False) -> list:
    """Run a debug build in the Connect IQ simulator (macOS) and return the comparison strip:
    design, awake, awake 2.5 s later, asleep. preview=True also rewrites previews/<Name>.png."""
    face_dir(name)
    code, log = run([os.path.join(TOOLS, "shot.py"), name] + (["--preview"] if preview else []), timeout=900)
    result = [{"ok": code == 0, "log": log}]
    cmp = os.path.join(ROOT, "build", "shots", f"{name}.cmp.png")
    if os.path.exists(cmp):
        result.append(Image(path=cmp))
    return result


@mcp.tool()
def build_site(repo: str | None = None) -> dict:
    """Build the GitHub Pages gallery into _site/. repo is owner/name for download links."""
    code, log = run([os.path.join(TOOLS, "gallery.py")] + (["--repo", repo] if repo else []), timeout=300)
    return {"ok": code == 0, "log": log}


if __name__ == "__main__":
    mcp.run()

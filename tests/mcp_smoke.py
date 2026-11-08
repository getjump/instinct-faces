#!/usr/bin/env python3
"""Start the MCP server over stdio, list its tools and call the read-only ones."""

import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXPECTED = {"list_faces", "face_info", "read_design", "check_faces", "build_face", "shoot_face", "build_site"}


def main():
    proc = subprocess.Popen(
        ["uv", "run", "--quiet", "--script", os.path.join(ROOT, "tools", "mcp_server.py")],
        cwd=ROOT,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
    )

    def send(msg):
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()

    def recv(want_id):
        for line in proc.stdout:
            msg = json.loads(line)
            if msg.get("id") == want_id:
                if "error" in msg:
                    sys.exit(f"error: {msg['error']}")
                return msg["result"]
        sys.exit("server closed the stream")

    try:
        send(
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "protocolVersion": "2025-06-18",
                    "capabilities": {},
                    "clientInfo": {"name": "smoke", "version": "0"},
                },
            }
        )
        recv(1)
        send({"jsonrpc": "2.0", "method": "notifications/initialized"})
        send({"jsonrpc": "2.0", "id": 2, "method": "tools/list"})
        names = {t["name"] for t in recv(2)["tools"]}
        missing = EXPECTED - names
        if missing:
            sys.exit(f"missing tools: {sorted(missing)}")
        calls = [("list_faces", {}), ("face_info", {"name": "Main"}), ("check_faces", {"names": ["Main"]})]
        for i, (tool, args) in enumerate(calls, start=3):
            send({"jsonrpc": "2.0", "id": i, "method": "tools/call", "params": {"name": tool, "arguments": args}})
            result = recv(i)
            if result.get("isError"):
                sys.exit(f"{tool} failed: {result['content']}")
        print(f"mcp ok: {len(names)} tools, read-only calls succeeded")
    finally:
        proc.stdin.close()
        proc.terminate()
        proc.wait(timeout=10)


if __name__ == "__main__":
    main()

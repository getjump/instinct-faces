#!/usr/bin/env python3
import argparse
import fcntl
import json
import os
import re
import signal
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build import CIQ, DEVICE, ROOT, png_read, png_write, sdk_bin

LOCK = os.path.expanduser("~/Library/Caches/ciq-shot.lock")
WINDOW_X = 1
WINDOW_Y = 29
SIZE = 176
WINDOW_JS = r"""
ObjC.import('CoreGraphics'); ObjC.import('Foundation');
var l = ObjC.castRefToObject($.CGWindowListCopyWindowInfo(16, 0));
var out = '';
for (var i = 0; i < l.count; i++) {
  var w = l.objectAtIndex(i);
  if ((ObjC.unwrap(w.objectForKey('kCGWindowOwnerName')) || '') == 'Connect IQ Device Simulator'
      && /CIQ Simulator/.test(ObjC.unwrap(w.objectForKey('kCGWindowName')) || '')) {
    out = '' + ObjC.unwrap(w.objectForKey('kCGWindowNumber'));
  }
}
out;
"""
ERRORS = re.compile(r"Error:|Encountered app crash|Unhandled Exception|Out Of Memory|Watchdog|Too Long", re.I)


def window_id():
    run = subprocess.run(["osascript", "-l", "JavaScript", "-e", WINDOW_JS], capture_output=True, text=True)
    return run.stdout.strip()


def restart_simulator():
    subprocess.run(["pkill", "-f", "MacOS/simulator"], capture_output=True)
    time.sleep(0.8)
    subprocess.run(["open", "-g", sdk_bin("ConnectIQ.app")], check=True)
    for _ in range(40):
        time.sleep(0.5)
        if window_id():
            return
    sys.exit("simulator window not found; screen recording permission may be missing")


def wait_probe(logpath, timeout):
    end = time.time() + timeout
    while time.time() < end:
        if re.search(r"^P \d+ ", open(logpath, errors="replace").read(), re.M):
            return True
        time.sleep(0.25)
    return False


def display_mode(item):
    script = (
        f'tell application "System Events" to tell process "simulator" to click menu item "{item}" '
        'of menu 1 of menu item "Display Mode" of menu 1 of menu bar item "Settings" of menu bar 1'
    )
    subprocess.run(["osascript", "-e", script], check=True, capture_output=True)


def display_origin():
    loc = json.load(open(os.path.join(CIQ, "Devices", DEVICE, "simulator.json")))["display"]["location"]
    return loc["x"] + WINDOW_X, loc["y"] + WINDOW_Y


def grab(path):
    tmp = path + ".win.png"
    subprocess.run(["screencapture", "-x", "-o", "-l", window_id(), tmp], check=True)
    w, h, px = png_read(tmp)
    os.remove(tmp)
    ox, oy = display_origin()
    frame = [[1 if px[oy + y][ox + x] >= 128 else 0 for x in range(SIZE)] for y in range(SIZE)]

    def rgba(x, y):
        v = 255 * frame[y][x]
        return v, v, v, 255

    png_write(path, SIZE, SIZE, rgba)
    return frame


def ref_frame(name):
    path = os.path.join(ROOT, "refs", name + ".png")
    if not os.path.exists(path):
        return None
    w, h, px = png_read(path)
    k = w // SIZE
    return [[1 if px[y * k + k // 2][x * k + k // 2] >= 128 else 0 for x in range(SIZE)] for y in range(SIZE)]


def compare(path, frames, scale=2, gap=6):
    n = len(frames)
    width = n * SIZE * scale + (n - 1) * gap
    height = SIZE * scale

    def rgba(x, y):
        slot, off = divmod(x, SIZE * scale + gap)
        if off >= SIZE * scale:
            return 255, 0, 0, 255
        v = 255 * frames[slot][y // scale][off // scale]
        return v, v, v, 255

    png_write(path, width, height, rgba)


def preview(name, awake, asleep, scale=2, gap=8):
    side = SIZE * scale

    def rgba(x, y):
        if side <= x < side + gap:
            return 128, 128, 128, 255
        frame = awake if x < side else asleep
        v = 255 * frame[y // scale][(x % (side + gap)) // scale]
        return v, v, v, 255

    png_write(os.path.join(ROOT, "previews", name + ".png"), 2 * side + gap, side, rgba)


def shoot(name, args):
    if not args.no_build:
        cmd = [sys.executable, os.path.join(ROOT, "tools", "build.py"), name, "--debug", "--show-warnings", "0"]
        run = subprocess.run(cmd, capture_output=True, text=True)
        if run.returncode != 0:
            print(run.stdout[-3000:] + run.stderr[-1000:])
            return False
    prg = os.path.join(ROOT, "build", name, "out", name + ".prg")
    outdir = os.path.join(ROOT, "build", "shots")
    os.makedirs(outdir, exist_ok=True)
    logpath = os.path.join(outdir, name + ".log")
    base = os.path.join(outdir, name)
    with open(LOCK, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        restart_simulator()
        with open(logpath, "w") as log:
            proc = subprocess.Popen(
                [sdk_bin("monkeydo"), prg, DEVICE], stdout=log, stderr=subprocess.STDOUT, start_new_session=True
            )
        try:
            wait_probe(logpath, args.load_timeout)
            time.sleep(args.wait)
            awake = grab(base + ".png")
            time.sleep(args.gap)
            later = grab(base + ".b.png")
            display_mode("Always-Active")
            time.sleep(args.sleep_wait)
            asleep = grab(base + ".sleep.png")
            display_mode("High Power")
        finally:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            proc.wait()
    text = open(logpath, errors="replace").read()
    probes = re.findall(r"^P (\d+) (\d+) (\d+)$", text, re.M)
    errors = [l for l in text.splitlines() if ERRORS.search(l)]
    frames = [f for f in [ref_frame(name)] if f] + [awake, later, asleep]
    compare(base + ".cmp.png", frames)
    if args.preview:
        preview(name, awake, asleep)
    if probes:
        ms = max(int(p[0]) for p in probes)
        used = max(int(p[1]) for p in probes)
        total = int(probes[-1][2])
        stats = f"frame_max={ms}ms frames={len(probes)} mem={used}/{total} ({100 * used // total}%)"
    else:
        stats = "no probes: onUpdate never finished"
    moved = "moved" if awake != later else "still"
    sleep_state = (
        f"slept partial={len(re.findall(r'^PART$', text, re.M))}"
        if re.search(r"^SLEEP$", text, re.M)
        else "NEVER-SLEPT"
    )
    failed = errors or not probes or sleep_state == "NEVER-SLEPT"
    print(f"{'FAIL' if failed else 'ok  '} {name}  {stats}  {moved}  {sleep_state}  build/shots/{name}.cmp.png")
    for line in errors[:12]:
        print("     " + line[:160])
    if errors:
        for line in text.splitlines()[-25:]:
            print("     | " + line[:160])
    return not failed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("faces", nargs="+")
    ap.add_argument("--no-build", action="store_true")
    ap.add_argument("--preview", action="store_true", help="also write previews/<Name>.png")
    ap.add_argument("--load-timeout", type=float, default=20.0)
    ap.add_argument("--wait", type=float, default=1.5)
    ap.add_argument("--gap", type=float, default=2.5)
    ap.add_argument("--sleep-wait", type=float, default=2.5)
    args = ap.parse_args()
    fails = [n for n in args.faces if not shoot(n, args)]
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()

---
name: check-face
description: Verify a face in the Connect IQ simulator against its design: frame time, memory, sleep behaviour and pixel comparison. Use after changing a face, before calling a port done, or when a face looks wrong or crashes.
---

# Check a face

Needs macOS, the Connect IQ SDK and Screen Recording permission for the terminal. Only one simulator run at a time: `tools/shot.py` takes a lock and restarts the simulator; do not drive the simulator by other means while it runs.

1. Static checks: `python3 tools/check.py <Name>` must print 0 problems.
2. Simulator run: `python3 tools/shot.py <Name>` (or MCP `shoot_face`). It builds with debug output and prints one line:
   `ok|FAIL <Name> frame_max=<ms> frames=<n> mem=<used>/<total> moved|still slept partial=<n>|NEVER-SLEPT`.
3. Pass criteria:
   - `ok`, no error lines below it;
   - `frame_max` under 30 ms (the watch is several times slower than the Mac);
   - `mem` under 80% of the total;
   - an animated face prints `moved`;
   - `slept`, and `partial=0` unless the face shows live seconds or another value that changes while asleep.
4. Read `build/shots/<Name>.cmp.png`. Panels: design, awake, awake 2.5 s later, asleep. Compare position, size, stroke width, missing elements and inverted areas. Sample values differ on purpose; thinner text than in the design is expected (the design renders at 3x).
5. The asleep panel must look finished: no half-drawn animation frames, no stale seconds.

Report the printed line and what differs from the design. A release build has no debug output, so `--no-build` on it prints `no probes` and `NEVER-SLEPT`: that is not a failure.

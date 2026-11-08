---
name: port-face
description: Port a design from design/<Name>.dc.html to a Connect IQ watch face in faces/<Name>/ (face.json, View.mc, art). Use when adding a new face, porting a design, or redoing a face so it matches its design.
---

# Port a design to a watch face

`docs/PORTING.md` is the contract: file layout, face.json schema, the power model, data sources, fidelity rules. Read it fully before writing code. This skill is the order of work.

1. Read the design: `python3 tools/strip_design.py design <Name>` (or MCP `read_design`). It prints the 176x176 display SVG and the JS that fills its `{{holes}}`. `refs/<Name>.png` is the same design at 1 bit.
2. Pick a close existing face as a template: `faces/Main` (fonts, seconds in partial updates), `faces/DitherSun` (baked art, moving object), `faces/LLife` (animation).
3. Write `faces/<Name>/face.json`: title, fonts copied from the design's `<text>` (family, size, `fit` for `textLength`), `permissions`, and `fake` when a value cannot be real on the watch.
4. Bake everything static into `faces/<Name>/art/*.svg` (integer width and height on the root; `.t.svg` for transparent overlays).
5. Write `faces/<Name>/source/View.mc`: `class FaceView extends BaseFace`, `render` draws a complete frame from state, `renderPartial` only inside `partialBox`. Real data from `D.*`, guarded for null. No comments, ASCII outside strings, never `COLOR_BLACK`/`COLOR_WHITE`.
6. Build: `python3 tools/build.py <Name>`. Fix every error; warnings are allowed.
7. Verify with the `check-face` skill. Iterate until the frames match the design.
8. When it matches, refresh the gallery frame: `python3 tools/shot.py <Name> --preview`, then `python3 tools/check.py <Name>`.

Do not edit `design/*.dc.html` or `refs/`: they are the source of truth. Changes to `core/` or `tools/` affect every face; rebuild all faces and compare `dist/*.prg` hashes before and after.

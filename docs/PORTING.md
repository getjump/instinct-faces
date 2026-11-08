# Porting a design to a Connect IQ face

Target: Garmin Instinct 3 Solar (`instinct3solar45mm`), 176x176, 1 bit, API 6. One `.prg` per face.

## Files of a face

```
design/<Name>.dc.html      original design, read-only source of truth
refs/<Name>.png            that design rendered to 1 bit, 3x upscale
faces/<Name>/face.json     title, fonts, permissions
faces/<Name>/source/View.mc   class FaceView extends BaseFace
faces/<Name>/art/<id>.svg     baked to a bitmap, Rez.Drawables.<id>
```

`python3 tools/strip_design.py design <Name>` prints the design without the watch case and grid: the 176x176
SVG and its JS. Build: `python3 tools/build.py <Name>`. Good examples: `faces/Main` (static, fonts, seconds through partial
updates), `faces/DitherSun` (baked art, moving object under an erased and redrawn layer), `faces/LLife` (animation).
Shared code: `core/source/Base.mc` (BaseFace, Now, U, G) and `core/source/Data.mc` (D). Do not change `core/` or `tools/`:
put what you need into your View.mc and report it.

## face.json

```json
{"title": "07 Game of Life",
 "permissions": [],
 "fonts": {"time": {"family": "Jersey 10", "size": 46, "sx": 1.0, "chars": "$time", "tracking": 0, "weight": 400, "t": 0.5}}}
```

- `title`: the number and name of the design in Latin letters, shown in the watch's face list.
- Each font becomes `F.<id>` plus the constant `F.<id>_b`, its baseline offset. Call `F.load()` in `onLayout`.
- Draw text with `G.t(dc, F.time, F.time_b, x, y, G.C, str)`: `x`, `y` are the SVG x and baseline y, justification `G.L`, `G.C`, `G.R`.
- `chars`: only what is really drawn, because every glyph costs memory. Shorthands: `$digits`, `$time`, `$upper`, `$lower`, `$ascii`. Any Unicode works, Cyrillic and CJK included.
- `family`, `size`, `weight`: copy from the design's `<text>`. Families are loaded from the design's own Google Fonts link.
- `textLength` with `lengthAdjust="spacingAndGlyphs"` stretches text. Copy it as `"fit": ["14:32", 108]`: sample string and target width; the build computes the scale. Never ignore a `textLength`: without it the text comes out far too narrow. `"sx"` sets a scale by hand.
- Fractional advances are rounded, `tracking` adds whole pixels per glyph.
- `t` is the coverage threshold, 0.5 by default. Lower it if thin strokes disappear.
- `permissions`: Connect IQ permission ids, for example `SensorHistory`. `Positioning` is added automatically when the source uses `D.sunTimes` or `D.location`; without it the location is null.

## art/*.svg

Standalone SVG with integer `width` and `height` on the root. Baked with the same Chromium and fonts, thresholded to 1 bit. Use `#000` for ink, `#fff` for paper. Do not use `{{holes}}`.

- `<id>.svg`: opaque. `<id>.t.svg`: white becomes transparent, for dithers and sprites over other content.
- Set `shape-rendering="crispEdges"` on dither patterns and rectangles. Leave out the design's `*-grid` pattern overlay: it only imitates LCD pixels. Leave out the `#111210` circle around the sub-window: that is the bezel.
- Bake everything static. Text that never changes belongs in art, not in a font.
- Load with `WatchUi.loadResource(Rez.Drawables.<id>) as BitmapResource` in `onLayout`, draw with `dc.drawBitmap(x, y, bmp)`.

The display has no pattern fill. Dithered shapes: bake them. A shape with a dither that sits over moving content: erase it with `G.paper` + `fillPolygon`, then draw a `.t.svg` of the same shape, as DitherSun does with its hills. Never fill dithers pixel by pixel at runtime.

## The watch is not a browser

- Asleep (most of the time): `render` runs once per minute. `animMs` timers do not run. Awake (about 10 s after a wrist raise): `render` runs every second, and timers run if `animMs > 0`.
- Animation: set `animMs` in `initialize` (not below 150 for full redraws; 250-500 is the normal range), advance state in `step()`. Web timers of 40-120 ms do not carry over: scale velocities so the motion looks right at the watch's frame rate. `frame` counts ticks.
- `render` must always draw a complete frame from state. When `awake` is false it must look finished and correct, so hide transient effects such as blinks, scrambled text and mid-flip frames, and show their settled state.
- Seconds: when `awake` is false a stale second is a lie. For a seconds readout in a small box set `partialBox = [x, y, w, h]` in `initialize`, implement `renderPartial(dc, n)` drawing only inside that box (it is cleared to paper first), and call the same code from `render`. Show `--` when `secLive()` is false. Analog second hands are not drawn asleep. The box is small and text only: budget is about 30 ms per second.
- Time always comes from `n` (`Now`), 24-hour as in the design. Never hard-code the design's sample values such as 14:32.
- CPU: there is a watchdog and this is a slow interpreter. Keep any frame under about 15000 loop-body operations: no per-pixel loops, precompute tables once, use bit tricks as LLife does. Prefer integer math. Allocate as little as possible per frame. `fillPolygon` takes at most 64 points.
- Memory: the limit is 61248 bytes for code, fonts and state together, and running out crashes the face. `tools/shot.py` prints `mem=used/total`: stay under 80%. Keep state small (arrays of Number, not of objects). Every glyph of every font costs memory, so `$ascii` and CJK sets are the usual cause.

## Data: real over demo

Designs show sample or demo numbers. Use real values wherever the watch has them:

| Value | Source |
|---|---|
| heart rate, steps, goal, 7-day steps | `D.hr()`, `D.steps()`, `D.stepGoal()`, `D.stepHistory()` |
| battery %, days, solar 0-100 | `D.batt()`, `D.battDays()`, `D.solar()` |
| moon | `D.moonAge(n.epoch)`, `D.moonIllum(age)`, `D.moonName(age)`, `G.moon(dc, x, y, r, age / 29.530588853)` fills the lit part with the current color, so on a dark disc call `G.paper` first |
| sunrise, sunset, location | `D.sunTimes()` (epoch seconds, may be null), `D.location()` (may be null) |
| floors, calories, active minutes | `ActivityMonitor.getInfo()`, fields may be null |
| HR history, altitude, pressure, temperature, stress, body battery | `Toybox.SensorHistory` iterators, needs permission `SensorHistory`, `has` checks |
| weather | `Toybox.Weather.getCurrentConditions()`, may be null |

Every source can return null or 0: guard it and show `--`, never crash. If the watch has no real source (a joke metric, simulated network, a data set that must come from the user), keep the design's fake or simulated behaviour and add to face.json: `"fake": "what is fake, one short line"`.

Map labels to what is really shown. A label that would now be false must change.

## Fidelity

Match geometry from the SVG numerically: positions, sizes, stroke widths, the same fonts. `currentColor`/`{{ink}}` = `G.ink(dc)`, `{{bg}}` = `G.paper(dc)`. Dark mode is handled by the build: never write `COLOR_BLACK` or `COLOR_WHITE`, use `Theme.FG`, `Theme.BG` through `G.ink` and `G.paper`.

`opacity` in the design only shows or hides (0 or 1). Stroke widths: `dc.setPenWidth(n)`, and reset it to 1 after use. Circles: `dc.fillCircle`, `dc.drawCircle`. Arcs: `dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, startDeg, endDeg)` where 0 degrees is 3 o'clock.

The sub-window is the circle of radius 31 at (144, 31) inside the box (113, 0, 62, 62), from `WatchUi.getSubscreen()`. Anything outside that circle in the box is hidden by hardware, so keep content inside the chord at that height. A physical bezel ring also hides the main display out to about 44.5 px from (144, 31), and the display corners are cut: black there in a screenshot is hardware, not a bug. The design knows only the radius 31, so its coordinates can run under the ring. On a black background the ring is invisible and silently eats digits. Keep text outside radius 44.5, and check the widest value (`22:28`, `20:08`), not the narrow sample in the design. The designs center the circle at y=32: keep their coordinates, a 1 px shift does not matter. `partialBox` is `[113, 0, 62, 62]`.

## Code style

No comments in code. ASCII only in `.mc` source except inside strings. Do not add features the design does not have.

## Done means

1. `python3 tools/build.py <Name>` passes with no errors.
2. `python3 tools/shot.py <Name>` rebuilds with debug output, restarts the simulator, runs the face and prints `ok` or `FAIL`, `frame_max`, `mem` and whether the screen `moved` between two awake frames. It waits for a shared lock, so it can take a while when others use the simulator. Do not touch the simulator by other means.
3. Read the image `build/shots/<Name>.cmp.png`. Panels left to right: the design, awake, awake 2.5 s later, asleep. Compare them against each other and fix what differs: position, size, width, missing elements, inverted colors. Sample values differ on purpose. Text looks thinner than in the design: the design is drawn at 3x, this is the true 1x result, and that is fine.
4. The asleep panel must look finished and correct. A face with an animation must print `moved`. `FAIL` lines must be gone. `frame_max` must stay under 30 ms on the simulator: the watch is far slower.

`Now.doy()` is a method and costs two calendar calls, so call it only in `render`.

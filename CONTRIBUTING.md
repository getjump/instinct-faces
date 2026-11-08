# Contributing

Issues and pull requests are welcome: a face that misbehaves on a real watch, a port that drifts from its design, a new design, tooling fixes.

## Before you start

- Read [docs/PORTING.md](docs/PORTING.md) for anything under `faces/` or `core/`. It covers the power model, data sources, the sub-display and bezel, and what "done" means for a face.
- `design/` and `refs/` are the source of truth and are not edited. A changed design is a new design file.
- Reports from real hardware are the most useful thing you can send: model, firmware, face, what you saw, and a photo if the screen is wrong.

## Setup

```bash
pre-commit install
npm ci
```

Without the Connect IQ SDK you can still run every check, the tests and the gallery. Building and the simulator harness need the SDK and headless Chromium, see [Build from source](README.md#build-from-source).

## A pull request

1. One face or one tooling change per pull request.
2. `python3 tools/check.py`, `uvx pytest`, `uvx ruff check .` and `npm run lint` pass. CI runs the same.
3. For a face: build it, run `python3 tools/shot.py <Name>`, and attach `build/shots/<Name>.cmp.png`. If the look changed, refresh the gallery frame with `python3 tools/shot.py <Name> --preview`.
4. For `core/` or `tools/build.py`: rebuild every face and compare `shasum dist/*.prg` before and after. Builds are deterministic, so only faces you meant to change may differ. Say which ones did.
5. Describe anything a face shows that is not real data in `face.json` `fake`.

## Style

- Monkey C: no comments, ASCII outside string literals, `G.ink` and `G.paper` instead of `COLOR_BLACK` and `COLOR_WHITE`.
- Python: standard library only in `tools/` (the MCP server declares its own dependencies), ruff with line length 120.
- JavaScript in `site/`: ES modules, no build step, ESLint and Prettier.

Never commit `.keys/`, `*.der` or `*.pem`. `tools/check.py` fails if a key is tracked.

By contributing you agree that your contribution is licensed under the MIT License of this repository.

# Third-party notices

## Fonts

The repository contains no font files. `tools/build.py` downloads the fonts named in each `faces/<Name>/face.json` from [Google Fonts](https://fonts.google.com/) at build time and rasterizes the needed glyphs into 1-bit bitmaps inside the `.prg`. The gallery loads the same fonts from Google Fonts in the browser.

All of them are licensed under the [SIL Open Font License 1.1](https://openfontlicense.org/):

| Family | Used by |
|---|---|
| Anton | builds |
| Cormorant Garamond | builds |
| Dela Gothic One | builds |
| DotGothic16 | builds |
| Jersey 10 | builds, gallery |
| Jost | builds |
| Noto Sans Runic | builds |
| Orbitron | builds |
| Playfair Display | builds |
| Shippori Mincho | builds |
| Silkscreen | builds |
| Space Grotesk | builds, gallery |
| VT323 | builds, gallery |

Each family's copyright holders and license text are on its Google Fonts page.

## Build and lint tools

Development tools (Connect IQ SDK, Chromium, ruff, pytest, ESLint, Prettier, pre-commit, the MCP Python SDK) are installed separately and are not part of this repository or its releases. The Connect IQ SDK is subject to the Garmin Connect IQ license agreement.

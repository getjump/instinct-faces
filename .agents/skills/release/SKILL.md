---
name: release
description: Build every face and publish the .prg files as a GitHub release, then refresh the Pages gallery. Use when asked to cut, tag or publish a release, or to update the download links.
---

# Release

Publishing is an outward action: tag and release only after the maintainer asked for this release.

The SDK and device files need a Garmin login and cannot be redistributed, so CI does not compile faces. Releases are built locally.

1. Clean tree on `main`, CI green.
2. `python3 tools/check.py` and `uvx pytest` pass.
3. `python3 tools/build.py --all` prints `built N/N`. Builds are deterministic: an unchanged face gives a byte-identical `.prg`.
4. Pick the version `vYYYY.MM.DD` (add `.N` for a second release that day).
5. `gh release create <version> dist/*.prg --title <version> --generate-notes`.
6. The gallery links to `releases/latest/download/<Name>.prg`, so it needs no rebuild for a new release. If previews changed, push them: the Pages workflow rebuilds the site on every push to `main`.
7. Check one link: `curl -sIL https://github.com/<owner>/<repo>/releases/latest/download/Main.prg | head -1`.

Never upload `.keys/` or a `.prg.debug.xml`.

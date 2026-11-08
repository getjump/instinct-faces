---
name: install-face
description: Sideload a built face onto an Instinct 3 Solar over USB. Use when asked to install, copy or put a face on the watch, or when a sideloaded face does not show up.
---

# Install a face on the watch

1. Build or download `dist/<Name>.prg` (`python3 tools/build.py <Name>`).
2. Quit Garmin Express: it holds the device.
3. Connect the watch with a data cable. It is an MTP device: Windows and most Linux file managers mount it directly; macOS needs an MTP client such as OpenMTP.
4. Copy the `.prg` into `GARMIN/APPS/` on the watch. Copy only the faces you want: each takes storage and appears in the face list.
5. Unplug. The face appears in the watch face list under its title from `face.json`.

Do not delete or overwrite other files on the watch without the owner's explicit request. If a face is missing after unplugging, check that the file landed in `GARMIN/APPS/` (not a subfolder) and that the watch model matches the build target `instinct3solar45mm`.

Sideloaded apps have no settings page in Garmin Connect. To remove a face, delete its `.prg` from `GARMIN/APPS/` or uninstall it from the watch menu.

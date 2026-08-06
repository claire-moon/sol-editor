# E1M1 Map Workspace

Store the editable E1M1 UDMF map source in this directory during `v0.1.0` development.

Required conventions:

- Map name: `E1M1`.
- Format: UDMF using the UZDoom/GZDoom namespace selected by the project configuration.
- Do not embed commercial IWAD textures, flats, sprites, sounds, or music.
- Use stable IDs for story events, encounters, objectives, and transition anchors.
- Keep temporary test geometry visibly marked and documented.
- Exported or packaged map artifacts belong under `build/sol`, not in source control.

The first playable graybox must implement the zones and exit gates described in `docs/sol/e1m1-graybox.md`.
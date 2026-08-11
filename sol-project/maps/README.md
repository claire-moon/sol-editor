# SOL map sources

`tools/sol-generate-e1m1.py` is the source of truth for the first playable **Hangar: Arrival** graybox. It generates an editable UDMF PWAD, readable `TEXTMAP.txt`, statistics, and a layout overview. The fixture has one map-authored SOL phase portal: 9001 is the physical entrance to the local dead-end Phase Room and carries the teleport-style `Line_SetPortal`; 9002 is its destination-only remote anchor and deliberately has no portal special, so it remains a real two-sided local doorway. The retained `user_sol_phase_*` UDMF properties declare its group, side-0 room interior required by teleport traversal, arm depth, and deterministic entry/reveal thresholds. The independent 9011/9012 lab remains a conventional reciprocal linked portal.

The phase approach and its two-cell local room intentionally keep an unobstructed route from the source through the arm depth, with no lateral connection out of the dead end. This prevents scenery or an alternate physical route from disguising the direction-sensitive local/backward regression as a portal failure. Reuse the documented authoring recipe in [phase-portals.md](phase-portals.md) for later SOL levels rather than copying TESTMAP IDs or coordinates.

Committed review artifacts:

- `e1m1/stats.json` records structural and encounter budgets.
- `e1m1/layout.svg` documents the zone sequence from Arrival Lock through Exit Control.

Generate and validate:

```bash
python3 tools/sol-generate-e1m1.py --output build/sol/generated/e1m1
python3 tools/sol-validate-e1m1.py --directory build/sol/generated/e1m1
bash tools/sol-build.sh
```

E1M1 ends through a normal Doom exit. Episode statistics and the Episode 1 world map are controlled by `sol-engine` MAPINFO rather than by an attached-map transition.

The generated WAD contains geometry and references to IWAD texture names. It contains no copied commercial textures, sounds, sprites, music, or other IWAD lumps.

# SOL map sources

`tools/sol-generate-e1m1.py` is the source of truth for the first playable **Hangar: Arrival** graybox. It generates an editable UDMF PWAD, readable `TEXTMAP.txt`, statistics, and a layout overview. The fixture has one map-authored SOL phase portal: 9001 is the physical entrance to the local dead-end Phase Room and 9002 is its destination-only remote anchor. The retained `user_sol_phase_*` UDMF properties declare its group, local inside side, arm depth, and deterministic entry/reveal thresholds. The independent 9011/9012 lab remains a conventional reciprocal linked portal.

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

# SOL map sources

`tools/sol-generate-e1m1.py` is the source of truth for the first playable **Hangar: Arrival** graybox. It generates an editable UDMF PWAD, readable `TEXTMAP.txt`, statistics, and a layout overview.

Committed review artifacts:

- `e1m1/stats.json` records structural and encounter budgets.
- `e1m1/layout.svg` documents the connected zone sequence.

Generate and validate:

```bash
python3 tools/sol-generate-e1m1.py --output build/sol/generated/e1m1
python3 tools/sol-validate-e1m1.py --directory build/sol/generated/e1m1
bash tools/sol-build.sh
```

The generated WAD contains geometry and references to IWAD texture names. It contains no copied commercial textures, sounds, sprites, music, or other IWAD lumps.

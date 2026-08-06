# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder. It coordinates map authoring, DoomTools automation, validation, packaging, and test launches against `sol-engine`.

## Current release

`v0.1.0-dev` contains the generated E1M1 graybox, shared branding, reproducible packaging, and repaired inherited CI.

```bash
python3 tools/sol-generate-e1m1.py --output build/sol/generated/e1m1
python3 tools/sol-validate-e1m1.py --directory build/sol/generated/e1m1
bash tools/sol-build.sh
SOL_ENGINE=/path/to/sol-engine DOOM_IWAD=/path/to/doom.wad bash tools/sol-test.sh E1M1
```

Build the editor itself with the existing upstream build process:

```bash
make linux
```

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-generate-e1m1.py`: E1M1 UDMF source generator.
- `sol-project/maps/e1m1/`: map budget and layout review artifacts.
- `tools/sol-*`: generation, validation, build, and launch commands.
- `docs/sol/`: release and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

Do not commit commercial IWAD resources. Local configuration may reference a legally obtained IWAD.

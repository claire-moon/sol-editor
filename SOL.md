# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder. It coordinates map authoring, DoomTools automation, validation, packaging, and test launches against the locally built `sol-engine` fork.

## Current release

`v0.1.0-dev` contains the generated E1M1 graybox, classic Doom episode progression, shared branding, reproducible packaging, and repaired inherited CI.

Initialize the sibling workspace and user-owned IWAD directory:

```bash
bash tools/sol-init-workspace.sh --primary-iwad /path/to/DOOM.WAD
source .sol-env
```

The initializer creates or updates `../vend/iwads`, packages the sibling `../sol-engine` runtime, records IWAD checksums, and writes the exact local engine executable and package paths to `.sol-env`. It never downloads commercial Doom data.

Generate, validate, and test E1M1:

```bash
python3 tools/sol-generate-e1m1.py --output build/sol/generated/e1m1
python3 tools/sol-validate-e1m1.py --directory build/sol/generated/e1m1
bash tools/sol-build.sh
bash tools/sol-test.sh E1M1
```

`tools/sol-test.sh` requires the configured `sol-engine` executable and does not fall back to a generic system UZDoom installation.

Build the editor itself with the existing upstream build process:

```bash
make linux
```

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-init-workspace.sh`: local engine/IWAD/vendor initialization.
- `tools/sol-generate-e1m1.py`: E1M1 UDMF source generator.
- `sol-project/maps/e1m1/`: map budget and layout review artifacts.
- `tools/sol-*`: generation, validation, build, and launch commands.
- `docs/sol/`: release and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

Do not commit commercial IWAD resources. Local configuration references a legally obtained IWAD stored under the sibling `vend` directory.

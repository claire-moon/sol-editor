# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder.
It coordinates map authoring, DoomTools automation, validation, packaging, and
test launches against the locally built `sol-engine` fork.

## Current release

`v0.1.0` establishes the deterministic E1M1 graybox, classic Doom progression,
shared SOL branding, guided local setup, and the fourteen-resource locked
visual/audio contract used by both authoring and test launches.

## First run

```text
sol/
├── sol-engine/
├── sol-editor/
└── vend/
```

```bash
cd sol-editor
bash tools/sol-cockpit.sh
```

The cockpit configures the sibling repositories and a user-owned IWAD. The first
play or editor launch then opens the locked wadpack importer when the required
visual/audio stack is incomplete.

After setup:

```bash
sol          # setup/status cockpit
sol-play     # launch E1M1 with the locked wadpack
sol-edit     # edit and test with the locked wadpack
```

## Locked resource stack

`sol-project/wadpack.json` defines the exact fourteen-resource load order copied
from the approved Rocket Launcher configuration. The importer normalizes nested
archives into `../vend/wadpack`, records hashes, and refuses a launch when a
required resource is absent or changed.

The resource binaries remain local because several components require a full
redistribution audit. They are not committed to the public repository. The
v0.1.0 source release therefore defines and enforces the stack without bundling
third-party payloads.

When the editor is launched with `sol-edit`, the fourteen locked resources are
added to its in-memory authoring resource list in manifest order. Their textures,
sprites, actors, and definitions are available while mapping without changing
the user's normal Ultimate Doom Builder resource configuration.

Editor playtests use this stable test-engine executable automatically:

```text
tools/sol-editor-engine.sh
```

`sol-edit` exposes the wrapper through `SOL_EDITOR_TEST_ENGINE`; the SOL editor
fork temporarily substitutes it for the configured test executable without
rewriting the user's normal editor settings. The authoring-only injected
resources are excluded from UDB's generated test arguments, and the wrapper is
the single runtime injection point for the same locked wadpack and SOL runtime.
See `docs/sol/wadpack.md`.

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-cockpit.sh`: first-run setup and ongoing MC cockpit.
- `tools/sol-wadpack.py`: deterministic import, normalization, locking, and verification.
- `tools/sol-wadpack-setup.sh`: guided wadpack source selector.
- `tools/sol-editor-engine.sh`: fixed-resource editor test-engine wrapper.
- `tools/sol-generate-e1m1.py`: E1M1 UDMF source generator.
- `sol-project/wadpack.json`: authoritative load order and source hashes.
- `sol-project/maps/e1m1/`: map budget and layout review artifacts.
- `docs/sol/`: setup, release, wadpack, and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

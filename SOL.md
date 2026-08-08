# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder.
It coordinates map authoring, DoomTools automation, validation, packaging, and
test launches against the locally built `sol-engine` fork.

## Current release

`v0.1.0` establishes the deterministic E1M1 graybox, classic Doom progression,
shared SOL branding, guided local setup, and the eighteen-resource locked
visual/audio contract used by both authoring and test launches.

The physical SOL runtime payload is now one file:

```text
sol.pk3
```

`sol.pk3` contains the eighteen normalized WAD/PK3 resources as intact embedded
archives, the SOL-owned engine runtime component, the current E1M1 content
component, `SOLPACK.json`, and `THIRD_PARTY.md`. The embedded archives are kept
separate inside the container so conflicting root resources in different mods
retain the same behavior and precedence they have when loaded individually.

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
bash tools/sol-wadpack-setup.sh
bash tools/sol-package.sh
```

`vend/wadpack` is the build-time source for the locked third-party resources.
Once a valid `sol.pk3` has been generated, normal SOL launches can materialize
all required runtime components from that single file without depending on the
loose `vend/wadpack/runtime` files.

After setup:

```bash
sol          # setup/status cockpit
sol-play     # launch E1M1 from sol.pk3
sol-edit     # edit and test using resources materialized from sol.pk3
```

## Locked resource stack

`sol-project/wadpack.json` defines the exact eighteen-resource load order used by
SOL. The importer normalizes source archives into `../vend/wadpack` and records
source/runtime hashes. Wadpack contract 2 preserves the original positions 1–14
and appends Universal Ambience, CosmoAmbience Script edited, Ambient decorations,
and TargetSpy v3.1.0 at positions 15–18.

`tools/sol-bundle.py` verifies the locked runtime files and creates bundle
contract 1. The bundle contains these ordered components:

```text
01–18  third-party WAD/PK3 resources
19     SOL runtime component
20     SOL E1M1 content component
```

`sol-play` materializes all twenty components from `sol.pk3` and mounts them in
that exact order. `sol-edit` materializes entries 1–18 for authoring, while its
editor test wrapper materializes entries 1–19 and lets UDB's temporary map follow
them on the command line.

The same `sol.pk3` is copied into `sol-editor/build/sol`, the editor `Build`
directory when present, `sol-engine/build/sol`, and the configured local engine
build directory. This makes the bundle part of both local package outputs.

## Attribution and redistribution

`THIRD_PARTY.md` is committed in the repository and is also embedded inside
`sol.pk3`. Each normalized upstream archive remains intact, preserving any
license/readme files it contains.

Attribution does not itself grant redistribution rights. Several resources are
still recorded as `review-required`, and the HQ PlayStation music/sound effects
are recorded as local-only proprietary audio. For that reason `sol.pk3` is
currently a local-build runtime artifact and must not be published or committed
as a public release binary until the third-party audit is complete.

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-cockpit.sh`: first-run setup and ongoing MC cockpit.
- `tools/sol-wadpack.py`: deterministic import, normalization, locking, and verification.
- `tools/sol-wadpack-setup.sh`: guided wadpack source selector.
- `tools/sol-bundle.py`: deterministic `sol.pk3` build, verification, and materialization.
- `tools/sol-bundle.sh`: workspace-level final package builder.
- `tools/sol-package.sh`: user-facing editor package command for `sol.pk3`.
- `tools/sol-editor-engine.sh`: fixed-resource editor test-engine wrapper.
- `tools/sol-generate-e1m1.py`: E1M1 UDMF source generator.
- `sol-project/wadpack.json`: authoritative load order and source hashes.
- `THIRD_PARTY.md`: attribution, license-status, and provenance inventory.
- `docs/sol/`: setup, release, wadpack, and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

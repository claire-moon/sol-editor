# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder.
It coordinates map authoring, DoomTools automation, validation, packaging, and
test launches against the locally built `sol-engine` fork.

## Current release

`v0.1.0` establishes the deterministic E1M1 graybox, classic Doom progression,
shared SOL branding, guided local setup, and the nineteen-resource locked
visual/audio contract used by both authoring and test launches.

The physical SOL runtime payload is one file:

```text
sol.pk3
```

`sol.pk3` contains the nineteen normalized third-party WAD/PK3 resources, the
SOL-owned engine runtime component, the current E1M1 content component,
`SOLPACK.json`, and `THIRD_PARTY.md`.

Each archive is stored byte-for-byte under a numbered root-level `.wad` carrier
name. This uses UZDoom's native embedded-resource mechanism: UZDoom recognizes
those root members as embedded archives, opens them by their actual file
contents, and recursively mounts them in lexical 01→21 order. Gameplay therefore
passes exactly one resource argument, `-file sol.pk3`.

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
Once a valid `sol.pk3` has been generated, normal SOL gameplay no longer depends
on the loose `vend/wadpack/runtime` files.

After setup:

```bash
sol          # setup/status cockpit
sol-play     # UZDoom loads one sol.pk3 and mounts its embedded stack natively
sol-edit     # editor authoring + tests use the same bundle contract
```

## Locked resource stack

`sol-project/wadpack.json` defines the exact nineteen-resource load order used by
SOL. Wadpack contract 3 preserves positions 1–18 from contract 2 and appends
Precise Crosshair v1.5.0 at position 19.

Bundle contract 1 adds the SOL-owned components after that stack:

```text
01–19  third-party WAD/PK3 resources
20     SOL runtime component
21     SOL E1M1 content component
```

The carrier names inside `sol.pk3` are numbered root-level `.wad` names solely
to activate UZDoom's existing embedded-resource handling. The bytes inside each
carrier retain the original normalized WAD or PK3 format.

`sol-play` passes only `sol.pk3` to the engine. The editor still materializes
entries 1–19 to their original normalized filenames for UDB's authoring-resource
view, because UDB expects direct resource paths. In-editor playtests pass the
single `sol.pk3` first and UDB's temporary map afterward, preserving test-map
precedence.

The same `sol.pk3` is copied into `sol-editor/build/sol`, the editor `Build`
directory when present, `sol-engine/build/sol`, and the configured engine build
directory. Local engine builds also install the self-contained `sol-engine`
launcher beside UZDoom; that launcher loads the adjacent `sol.pk3` by default.

## Attribution and redistribution

`THIRD_PARTY.md` is committed and embedded in `sol.pk3`. The manifest also
records source hashes when pinned and known upstream source pages. Universal
Ambience, Cosmo ambience, Ambient decorations, TargetSpy, Precise Crosshair,
FinalCustomDoom, NashGore, and Voxel Doom provenance is recorded there.

Precise Crosshair v1.5.0 is GPL-3.0-only upstream. Its public source identifies
v1.5.0 directly; the user-supplied package is not committed here and its exact
SHA-256 is captured by the local wadpack lock on import.

Attribution does not itself grant redistribution rights. Several resources still
need asset-level review, and the HQ PlayStation music/sound effects remain
local-only proprietary audio. The complete `sol.pk3` is therefore a local-build
runtime artifact and must not be published as a public SOL binary until the
third-party audit is complete.

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-cockpit.sh`: first-run setup and ongoing MC cockpit.
- `tools/sol-wadpack.py`: deterministic import, normalization, locking, and verification.
- `tools/sol-wadpack-setup.sh`: guided wadpack source selector.
- `tools/sol-bundle.py`: deterministic `sol.pk3` build, verification, and editor materialization.
- `tools/sol-bundle.sh`: workspace-level final package builder.
- `tools/sol-package.sh`: user-facing editor package command for `sol.pk3`.
- `tools/sol-editor-engine.sh`: native-bundle editor test-engine wrapper.
- `tools/sol-generate-e1m1.py`: E1M1 UDMF source generator.
- `sol-project/wadpack.json`: authoritative load order, hashes, and provenance.
- `THIRD_PARTY.md`: attribution, license-status, and provenance inventory.
- `docs/sol/`: setup, release, wadpack, and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

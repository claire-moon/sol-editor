# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder.
It coordinates map authoring, DoomTools automation, validation, packaging, and
test launches against the locally built `sol-engine` fork.

## Current release

`v0.2.0` preserves the deterministic E1M1 graybox, classic Doom progression,
story contract 1 foundation, wadpack contract 2, and bundle contract 1. Story
and production-map work are now parked during the engine-first roadmap.

The editor remains at contract version 0.2.0 while it integrates with native
SOL Engine v0.3.0. `sol/version.json` therefore records `bundle_version` 0.3.0
separately: it is the version written to and verified in `SOLPACK.json`, not an
editor or content-contract version bump.

Story contract 1 adds a canonical authoring manifest, stable typed IDs, strict
cross-reference validation, and packaging of the exact manifest into the map
content component. The foundation intentionally contains no invented E1M1
narrative text or triggers.

The physical SOL runtime payload remains one file:

```text
sol.pk3
```

`sol.pk3` contains the eighteen normalized third-party WAD/PK3 resources, the
SOL-owned engine runtime component, the current E1M1 content component,
`SOLPACK.json`, and `THIRD_PARTY.md`.

Each archive is stored byte-for-byte under a numbered root-level `.wad` carrier
name. This uses the inherited native embedded-resource mechanism: SOL Engine
recognizes those root members as embedded archives, opens them by their actual
file contents, and recursively mounts them in lexical 01→20 order. The v0.3
native engine validates and mounts the adjacent bundle without a
`-file sol.pk3` argument.

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

SOL Engine v0.3 accepts a user-owned registered Doom IWAD named `DOOM.WAD` or
`DOOMU.WAD`. The setup cockpit selects only those filenames and does not select
known Doom II, Freedoom, TNT, or Plutonia filenames. The native engine remains
the authority that inspects the IWAD contents and rejects shareware, renamed
unsupported IWADs, and other non-Doom-1 data before play begins.

After setup:

```bash
sol          # setup/status cockpit
sol-play     # native SOL Engine validates and mounts adjacent sol.pk3
sol-edit     # editor authoring + tests use the same bundle contract
```

## Story authoring contract

The canonical E1M1 story manifest is:

```text
sol-project/story/story.json
```

Story contract 1 has four independent namespaces: `events`, `objectives`,
`subtitles`, and `radio`. IDs are integers from 1 through 65535. Each namespace
also uses stable lowercase keys. Once an ID is assigned to shipped content it is
append-only and must not be silently reused for a different meaning.

`tools/sol-story.py` validates the manifest and rejects invalid IDs or keys,
duplicates, and event references to missing objective/subtitle/radio IDs. The
initial manifest is deliberately empty until the E1M1 narrative beats are
authored.

`tools/sol-build.sh` validates the manifest before every content build and embeds
the exact file as `SOLSTORY.json` beside `SOLINFO` and `maps/E1M1.wad`. The
v0.2.0 content component is:

```text
build/sol/sol-e1m1-v0.2.0.pk3
```

The matching engine runtime stores save-persistent story state under the same
story contract. Trigger actors, HUD objective presentation, subtitle timing,
radio playback, and concrete map narrative remain subsequent Phase 2 work.

## Locked resource stack

`sol-project/wadpack.json` defines the exact eighteen-resource load order used by
SOL. Wadpack contract 2 preserves positions 1–14 and appends Universal Ambience,
CosmoAmbience Script edited, Ambient decorations, and TargetSpy v3.1.0 at
positions 15–18.

Bundle contract 1 adds the SOL-owned components after that stack:

```text
01–18  third-party WAD/PK3 resources
19     SOL runtime component
20     SOL E1M1 content component
```

The carrier names inside `sol.pk3` are numbered root-level `.wad` names solely
to activate the embedded-resource handling inherited from UZDoom. The bytes
inside each carrier retain the original normalized WAD or PK3 format.

`sol-play` lets native SOL Engine mount adjacent `sol.pk3`. The editor still
materializes entries 1–18 to their original normalized filenames for UDB's
authoring-resource view, because UDB expects direct resource paths. In-editor
playtests invoke the native engine and append UDB's temporary map afterward,
preserving test-map precedence. A `-file` compatibility path remains only for
pre-v0.3 UZDoom development binaries.

The same `sol.pk3` is copied into `sol-editor/build/sol`, the editor `Build`
directory when present, `sol-engine/build/sol`, and the configured engine build
directory. Current engine builds produce the native `sol-engine` executable;
editor tooling never overwrites it with the obsolete shell launcher.

## Attribution and redistribution

`THIRD_PARTY.md` is committed and embedded in `sol.pk3`. The manifest also
records exact source hashes and known upstream source pages. Universal Ambience,
Cosmo ambience, Ambient decorations, TargetSpy, FinalCustomDoom, NashGore, and
Voxel Doom provenance has been expanded from upstream project pages.

Attribution does not itself grant redistribution rights. Several resources still
need asset-level review. HQ PlayStation music is an accidental contract-2 input
scheduled for retirement in engine v0.4.0; PlayStation sound effects remain a
local placeholder pending original SOL replacements. Neither file is cleared
for redistribution while present. The complete `sol.pk3` is therefore a
local-build runtime artifact and must not be published as a public SOL binary
until the third-party audit is complete.

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
- `tools/sol-story.py`: story contract validator.
- `sol-project/story/story.json`: canonical E1M1 story authoring manifest.
- `sol-project/wadpack.json`: authoritative load order, hashes, and provenance.
- `THIRD_PARTY.md`: attribution, license-status, and provenance inventory.
- `docs/sol/`: setup, release, wadpack, and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

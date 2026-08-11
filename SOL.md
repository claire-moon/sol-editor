# SOL! Editor

`sol-editor` is the SOL! content-development fork based on Ultimate Doom Builder.
During the engine-first roadmap it remains a compatibility/authoring consumer of
contracts owned by `sol-engine`.

## Current compatibility release

`v0.4.0` consumes SOL! Engine v0.4 bundle contract 2, wadpack contract 3,
SOLDEFAULTS contract 1, and geometry contract 1 while preserving story contract
1. Story authoring and production level design remain parked.

The current E1M1 is deliberately non-production regression content. It is
presented as `TESTMAP` and exercises engine/editor geometry, impossible-space
portal traversal, lighting, ambience, renderer, resource, weapon, and object
coverage without monsters.

## Engine-owned resource authority

The authoritative v0.4 resource files live in the sibling engine checkout:

```text
sol-engine/sol/wadpack.json
sol-engine/tools/sol-wadpack.py
sol-engine/tools/sol-wadpack-setup.sh
sol-engine/tools/sol-bundle.py
sol-engine/tools/sol-bundle.sh
sol-engine/THIRD_PARTY.md
```

The editor's `sol-bundle.sh`, `sol-wadpack.py`, and `sol-wadpack-setup.sh` are
compatibility entry points that delegate to the engine. The old
`sol-project/wadpack.json` is a deprecation pointer rather than an authoritative
manifest.

The v0.4 slot contract is:

```text
01–10  active wadpack resources
11     retired/unmounted HQ PSX music
12–18  active wadpack resources
19     active PreciseCrosshair v1.5.0
20     reserved/unmounted
21     SOL! runtime component
22     SOL! content component
```

The complete local runtime remains one physical `sol.pk3`. Retired/reserved
slots appear only in `SOLPACK.json`; no dummy archive is mounted for them.

## Workspace and build

The supported source workspace is:

```text
sol/
├── sol-engine/
├── sol-editor/
└── vend/
```

From either repository, compatibility commands converge on the engine-owned
bundle workflow. From the editor:

```bash
bash tools/sol-wadpack-setup.sh
bash tools/sol-package.sh
```

The editor builds `build/sol/sol-e1m1-v0.4.0.pk3`. The engine builds the
SOL!-owned runtime component and constructs/validates final `sol.pk3`.

`vend/wadpack` remains local build input containing user-supplied or third-party
source/runtime files. The complete bundle is local-only until every bundled
asset has documented redistribution permission.

## TESTMAP systems testbed

`tools/sol-generate-e1m1.py` is the deterministic source of the test map. E1M1
is presented to the player as `TESTMAP`. The v0.4 fixture contains thirteen
functional room themes represented by 43 connected sectors across a
two-dimensional layout rather than a linear strip.

Coverage includes:

- stock Doom/Ultimate Doom placeholder wall, floor, ceiling, sky, and liquid
  materials;
- broad light-level and floor/ceiling-height variation;
- no monsters;
- one stateful SOL phase source (9001) at the physical entrance to a local
  dead-end room, with a destination-only teleport-style anchor (9002), plus an
  independent reciprocal 9011/9012 linked-portal laboratory;
- shotgun, chaingun, chainsaw, rocket launcher, plasma rifle, and BFG;
- ammunition, health, armor, powerups, and multiplayer starts;
- 129 stock barrels, torches/candelabras, corpses, and other decorations to
  exercise ReLite and Universal Ambience behavior;
- a normal player-use exit and connected-sector validation.

Tracked `stats.json` and `layout.svg` must match deterministic generator output.
`tools/sol-validate-e1m1.py` rejects monsters, malformed phase or linked
portals, disconnected geometry, reduced material or lighting coverage, missing
weapons/starts, inadequate prop coverage, invalid bounds, and contract drift.

This fixture is test infrastructure, not a resumed production level.

## Story contract

The canonical story manifest remains:

```text
sol-project/story/story.json
```

Story contract 1 keeps typed `events`, `objectives`, `subtitles`, and `radio`
namespaces with stable IDs in 1–65535. The canonical manifest may remain empty
while story work is parked. `tools/sol-story.py` continues to validate it before
content packaging and `tools/sol-build.sh` embeds it as `SOLSTORY.json`.

## Native playtesting

Native SOL! Engine owns discovery and validation of adjacent `sol.pk3`; editor
launchers do not add another `-file sol.pk3`. UDB's temporary map is appended
after the canonical bundle so the map being edited retains override precedence.

SOL! Engine accepts registered Doom/Ultimate Doom IWAD data and rejects
shareware, Doom II-family, and unrelated IWADs. Commercial IWAD data is never
stored in this repository.

## Canonical defaults

SOLDEFAULTS contract 1 is engine-owned and embedded in the SOL! runtime. The
editor does not copy personal paths, recent-file history, bindings, saves, or
identity into that contract.

## Attribution and redistribution

The engine-owned `THIRD_PARTY.md` is the canonical v0.4 bundle inventory.
Attribution is not a relicensing mechanism. HQ PlayStation music is retired at
slot 11, PlayStation sound effects remain a local placeholder at slot 12, and
PreciseCrosshair occupies slot 19 with its GPL/libeye provenance recorded for
review. The complete `sol.pk3` remains a local development artifact.

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `tools/sol-generate-e1m1.py`: deterministic TESTMAP generator.
- `tools/sol-validate-e1m1.py`: TESTMAP geometry/testbed validator.
- `tools/sol-build.sh`: story validation and SOL! content-component packaging.
- `tools/sol-story.py`: story contract validator.
- `tools/sol-bundle.sh`: compatibility delegate to engine bundle authority.
- `tools/sol-wadpack.py`: compatibility delegate to engine wadpack authority.
- `tools/sol-wadpack-setup.sh`: compatibility delegate to engine setup.
- `tools/sol-editor-engine.sh`: native SOL! editor test-engine wrapper.
- `sol-project/story/story.json`: canonical story authoring manifest.
- `sol-project/maps/e1m1/`: tracked deterministic TESTMAP metadata/layout.

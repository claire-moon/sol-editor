# SOL third-party resources

SOL uses third-party Doom resources as part of its presentation baseline. The
canonical order, exact source hashes, normalization rules, and known source
pages are recorded in `sol-project/wadpack.json`.

The generated `sol.pk3` preserves each normalized third-party WAD/PK3 byte-for-
byte inside a numbered native UZDoom embedded-resource carrier. License/readme
files contained by an upstream package therefore remain with that package.

This file is an attribution and provenance inventory. It does **not** convert a
resource with unknown, restricted, proprietary, or mixed terms into a
redistributable asset, and the SOL project license does not relicense third-party
content. Public redistribution of the complete bundle remains blocked until
every component has a documented redistribution basis and all corresponding
notice/source obligations are satisfied.

| # | Component | Materialized name | Recorded status |
|---:|---|---|---|
| 1 | Voxel Doom 2.4 | `01-voxel-doom-v2.4.pk3` | code reported as GPLv3; package contains graphics/assets requiring separate redistribution review |
| 2 | Universal Weapon Sway 1.0 | `02-universal-weapon-sway.pk3` | MIT |
| 3 | Troo Cullers 2.5 | `03-troo-cullers-2.5.pk3` | review-required |
| 4 | Tilt++ | `04-tilt-plus-plus.pk3` | BSD-3-Clause |
| 5 | Relighting 0.7.3b | `05-relite-0.7.3b.pk3` | review-required |
| 6 | Angled Doom Lite 1.2.1 | `06-angled-doom-lite-1.2.1.pk3` | permission-included; redistribution terms require preservation/review |
| 7 | NashGore NEXT | `07-nashgore-next.pk3` | Nash Muhandes; redistribution terms require review |
| 8 | NashGore official voxels | `08-nashgore-voxels-official.pk3` | Cheello and Nash Muhandes; redistribution terms require review |
| 9 | Final Custom Doom 1.0.0 beta | `09-final-custom-doom-v1.0.0-beta.pk3` | GPL-3.0-only, Alexander Kromm; bundled non-code assets still preserved/reviewed separately |
| 10 | Vanilla Essence 4.3 | `10-vanilla-essence-4.3.pk3` | review-required |
| 11 | HQ PSX music | `11-hq-psx-music.wad` | local-only proprietary PlayStation-derived audio |
| 12 | PlayStation sound effects | `12-psx-sfx.wad` | local-only proprietary PlayStation-derived audio |
| 13 | Flashlight++ 9.1 | `13-flashlight-plus-plus-v9_1.pk3` | review-required |
| 14 | WW Alpha HUD | `14-ww-alpha-hud.wad` | review-required |
| 15 | Universal Ambience | `15-universal-ambience.pk3` | distribution page lists GPL; third-party audio sources still require asset-level review |
| 16 | CosmoAmbience Script edited | `16-cosmoambience-script-edited.pk3` | upstream Universal Ambience distribution lists GPL; this supplied copy is an edited variant and its local changes/source obligations must remain documented |
| 17 | Ambient decorations | `17-ambient-decorations.pk3` | distribution page lists GPL; third-party audio sources still require asset-level review |
| 18 | TargetSpy v3.1.0 | `18-targetspy-v3.1.0.pk3` | GPL-3.0-only, © 2026 Alexander Kromm (mmaulwurff) |

## Recorded upstream credits

### Universal Ambience / Cosmo ambience / Ambient decorations

Source: https://www.moddb.com/addons/universal-ambience

The Universal Ambience 1.71 distribution page identifies the ZIP as GPL and
explicitly lists these three pieces as its numbered package components. Its
published credits include:

- McTed — compilation, editing, code and sounds.
- Heydoomer — idle ambience base and original inspiration.
- Agent Ash — code assistance, fixes, and optimization.
- Boondorl — ZScript CVar assistance.
- Dr_Cosmobyte — random-sound code used with permission by the package author.
- Senn_ and Valve — remastered Half-Life 1 sound sources as credited upstream.
- Valve — Half-Life 2 sound sources as credited upstream.
- GSC Game World — STALKER: Shadow of Chernobyl sound sources as credited upstream.
- Additional Freesound contributors are enumerated on the upstream page.

The GPL label on the package does not establish that every externally sourced
sound asset is independently GPL-compatible. SOL therefore records the package
license while retaining an explicit audio-asset review requirement. Entry 16 is
also a locally edited supplied variant; its exact SHA-256 is locked in the SOL
manifest so the edited artifact cannot be silently substituted.

### TargetSpy v3.1.0

Source: https://mmaulwurff.github.io/doom-toolbox/add-ons/TargetSpy.html

TargetSpy v3.1.0 declares:

```text
SPDX-FileCopyrightText: © 2026 Alexander Kromm <mmaulwurff@gmail.com>
SPDX-License-Identifier: GPL-3.0-only
```

The embedded upstream archive is preserved intact so its notices remain part of
the SOL bundle.

### FinalCustomDoom

Source: https://mmaulwurff.github.io/doom-toolbox/add-ons/FinalCustomDoom.html

FinalCustomDoom declares GPL-3.0-only and © 2025 Alexander Kromm. SOL preserves
the supplied archive intact and records its exact source hash in the manifest.

### NashGore NEXT and official voxel pack

Source: https://www.moddb.com/mods/nashgore-next

The published project identifies Nash Muhandes as the developer. The official
voxel pack is credited to Cheello and Nash Muhandes. The pages inspected for
this inventory do not establish a redistribution license for the supplied
archives, so these remain review-required for a public SOL binary.

### Voxel Doom 2.4

Source: https://www.moddb.com/addons/voxel-doom-ii-with-parallax-textures

The v2.4 release notes state that its code was relicensed to GPLv3 because it
contains GZDoom-derived code. The same download page labels the overall addon as
proprietary, so SOL does not treat that code-license statement as clearance for
all voxel/graphics assets in the package.

## SOL bundle layout

A complete local build produces one physical runtime file:

```text
sol.pk3
├── SOLPACK.json
├── THIRD_PARTY.md
├── 01-voxel-doom.wad
├── 02-universal-weapon-sway.wad
├── ...
├── 18-targetspy.wad
├── 19-sol-runtime.wad
└── 20-sol-content.wad
```

The `.wad` suffixes above are **carrier names**, not format conversions. Each
carrier contains the original normalized WAD/PK3 bytes. UZDoom identifies
root-level `.wad` members as embedded resources, opens each member by its actual
file contents, and recursively mounts them in lexical order. This allows the
engine to load only `sol.pk3` while preserving the same 01→20 resource
precedence as separate archives.

The editor may materialize entries 1–18 back to their original normalized
filenames for authoring-resource inspection. Gameplay and editor playtests do
not need that extraction path; UZDoom mounts the embedded carriers natively.

## Distribution status

`sol.pk3` is currently a **local-build runtime artifact**. It may be copied into
local SOL engine/editor build packages for development and testing. It must not
be attached to a public release or committed to this public repository until
every component has a documented redistribution basis and all required notices,
source offers/source code, modification records, and asset permissions have been
satisfied.

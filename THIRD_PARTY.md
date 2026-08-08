# SOL third-party resources

SOL uses third-party Doom resources as part of its presentation baseline. The
canonical order and exact source hashes are recorded in `sol-project/wadpack.json`.
The generated `sol.pk3` preserves every normalized third-party WAD/PK3 as an
intact embedded archive, so license notices and credits contained inside an
upstream package remain with that package.

This file is an attribution and provenance inventory. It does **not** convert a
resource with unknown, restricted, or proprietary terms into a redistributable
asset, and the SOL project license does not relicense third-party content.
Public redistribution remains blocked for entries marked `review-required` or
`local-only-proprietary-audio` until their rights are documented separately.

| # | Component | Runtime member | Recorded status |
|---:|---|---|---|
| 1 | Voxel Doom 2.4 | `01-voxel-doom-v2.4.pk3` | review-required |
| 2 | Universal Weapon Sway 1.0 | `02-universal-weapon-sway.pk3` | MIT |
| 3 | Troo Cullers 2.5 | `03-troo-cullers-2.5.pk3` | review-required |
| 4 | Tilt++ | `04-tilt-plus-plus.pk3` | BSD-3-Clause |
| 5 | Relighting 0.7.3b | `05-relite-0.7.3b.pk3` | review-required |
| 6 | Angled Doom Lite 1.2.1 | `06-angled-doom-lite-1.2.1.pk3` | permission-included; redistribution terms require preservation/review |
| 7 | NashGore NEXT | `07-nashgore-next.pk3` | review-required |
| 8 | NashGore official voxels | `08-nashgore-voxels-official.pk3` | review-required |
| 9 | Final Custom Doom 1.0.0 beta | `09-final-custom-doom-v1.0.0-beta.pk3` | GPL-3.0-only code; bundled assets require review |
| 10 | Vanilla Essence 4.3 | `10-vanilla-essence-4.3.pk3` | review-required |
| 11 | HQ PSX music | `11-hq-psx-music.wad` | local-only-proprietary-audio |
| 12 | PlayStation sound effects | `12-psx-sfx.wad` | local-only-proprietary-audio |
| 13 | Flashlight++ 9.1 | `13-flashlight-plus-plus-v9_1.pk3` | review-required |
| 14 | WW Alpha HUD | `14-ww-alpha-hud.wad` | review-required |
| 15 | Universal Ambience | `15-universal-ambience.pk3` | review-required; supplied PK3 contains no standalone license/readme metadata |
| 16 | CosmoAmbience Script edited | `16-cosmoambience-script-edited.pk3` | review-required; supplied PK3 contains no standalone license/readme metadata |
| 17 | Ambient decorations | `17-ambient-decorations.pk3` | review-required; supplied PK3 contains no standalone license/readme metadata |
| 18 | TargetSpy v3.1.0 | `18-targetspy-v3.1.0.pk3` | GPL-3.0-only project license; preserve bundled notices |

## SOL bundle layout

A local complete build produces one physical runtime file:

```text
sol.pk3
├── SOLPACK.json
├── THIRD_PARTY.md
└── components/
    ├── 01-voxel-doom-v2.4.pk3
    ├── ...
    ├── 18-targetspy-v3.1.0.pk3
    ├── 19-sol-runtime.pk3
    └── 20-sol-content.pk3
```

The numbered component archives are mounted in that order by the SOL launch
wrappers. Keeping them as embedded archives instead of flattening their contents
prevents identically named root files such as `ZSCRIPT`, `MAPINFO`, `DECORATE`,
`MENUDEF`, sprites, or sounds from destroying one another during packaging.

## Distribution status

`sol.pk3` is currently a **local-build runtime artifact**. It may be copied into
local SOL engine/editor build packages for testing. It must not be attached to a
public release or committed to this public repository until every component has
a documented redistribution basis and all required notices/source obligations
have been satisfied.

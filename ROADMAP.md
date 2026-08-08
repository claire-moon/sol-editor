# SOL Development Roadmap

## Completed

- `v0.0.1`: repository foundation, pinned DoomTools, shared launch contract, package validation.
- `v0.1.0`: deterministic E1M1 graybox, classic Doom progression, Midnight Commander setup cockpit, shared SOL branding, eighteen-resource wadpack contract 2, editor authoring/test injection, and bundle contract 1 with canonical `sol.pk3` local runtime packaging.

The original fourteen-resource baseline remains positions 1–14. Wadpack contract
2 appends Universal Ambience, CosmoAmbience Script edited, Ambient decorations,
and TargetSpy v3.1.0 in positions 15–18.

A complete local build now stores all eighteen normalized resources, the SOL
runtime component, current E1M1 content, component hashes, and attribution in one
physical `sol.pk3`. Numbered root-level `.wad` carrier names activate UZDoom's
existing embedded-resource loader, so gameplay/test launches pass one `sol.pk3`
and UZDoom recursively mounts the complete 01→20 stack natively. Only the UDB
authoring view materializes entries 1–18 to direct resource paths.

Local engine builds place `sol.pk3` beside UZDoom and install a `sol-engine`
launcher that loads that bundle by default.

`THIRD_PARTY.md` records attribution/provenance and is embedded in `sol.pk3`.
The bundle remains a local development/test artifact until each third-party
redistribution basis and asset obligation is documented; HQ PlayStation
music/sound effects remain local-only proprietary inputs.

## Active — Phase 2: Story Authoring (`v0.2.0`)

Add stable event IDs, objectives, subtitles, radio events, save/load validation,
and reusable story prefabs within individual maps. Begin tuning wadpack settings
into SOL-owned defaults.

Foundation status:

- story contract 1 defines typed `events`, `objectives`, `subtitles`, and `radio` namespaces;
- stable IDs use 1–65535 and are validated for duplicates and dangling references;
- the canonical E1M1 manifest is packaged as `SOLSTORY.json`;
- map-specific narrative entries remain unassigned until authored;
- wadpack contract 2 and bundle contract 1 remain unchanged.

## Phase 3 — Classic Episode Authoring (`v0.3.0`)

Add map title patches, par times, secret exits, world-map markers,
episode-complete screens, and editor validation for Doom-style progression.

## Phase 4 — Finished Vertical Slice (`v0.5.0`)

Replace graybox content with production mapping, original assets, final combat
pacing, lighting, soundscape, benchmarks, and tester packages.

## Phase 5 — Campaign Pipeline (`v0.6.0–v0.8.0`)

Automate map linting, packaging, campaign-state inspection, asset provenance,
license auditing, and regression coverage.

## Phase 6 — Standalone Toolset (`v0.9.0`)

Complete SOL identity, defaults, project creation, custom launcher/menu,
installers, diagnostics, and redistribution-cleared replacement or embedding of
the approved resource stack. Move the current shell packaging contract into the
standalone binary/installer once the tuned resource set and rights are stable.

## Phase 7 — Release (`v1.0.0`)

Stabilize project formats, campaign production support, licenses, credits,
source distribution, and maintenance policy.

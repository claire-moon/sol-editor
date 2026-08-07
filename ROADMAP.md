# SOL Development Roadmap

## Completed

- `v0.0.1`: repository foundation, pinned DoomTools, shared launch contract, package validation.
- `v0.1.0`: deterministic E1M1 graybox, classic Doom episode progression contract, Midnight Commander setup cockpit, shared SOL branding, fourteen-resource locked wadpack tooling, editor authoring-resource injection, strict editor test-engine wrapper, and green Linux/Windows/Flatpak/SOL CI.

The v0.1.0 source release does not redistribute the third-party wadpack. Local
play is intentionally blocked until all fourteen required resources are present
and verified under `vend/wadpack`; HQ PSX music remains a local deployment input.

## Active — Phase 2: Story Authoring (`v0.2.0`)

Add stable event IDs, objectives, subtitles, radio events, save/load validation,
and reusable story prefabs within individual maps. Begin tuning wadpack settings
into SOL-owned defaults.

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
installers, diagnostics, and redistribution-safe replacement or embedding of the
approved resource stack.

## Phase 7 — Release (`v1.0.0`)

Stabilize project formats, campaign production support, licenses, credits,
source distribution, and maintenance policy.

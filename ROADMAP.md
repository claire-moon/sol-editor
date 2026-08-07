# SOL Development Roadmap

## Completed

- `v0.0.1`: repository foundation, pinned DoomTools, shared launch contract, package validation.

## Active — Phase 1: E1M1 Graybox (`v0.1.0`)

- Generate and validate the complete E1M1 critical path.
- Keep the map editable as UDMF and testable in the local `sol-engine` fork.
- Preserve the normal Doom statistics and Episode 1 world-map intermission.
- Provide the Midnight Commander setup cockpit.
- Lock the approved fourteen-resource wadpack and inject it into every SOL launch.
- Normalize wrapper archives and detect missing or changed resources.
- Provide a stable SOL Editor test-engine wrapper using the same load order.
- Keep inherited Linux, Windows, and Flatpak CI green.

Exit gate: a clean sibling checkout can configure its IWAD and complete wadpack,
build both applications, launch E1M1 with the exact locked resources, complete
the classic intermission, and repeat the process without manual command lines.

## Phase 2 — Story Authoring (`v0.2.0`)

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

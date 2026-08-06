# SOL Development Roadmap

## Completed

- `v0.0.1`: repository foundation, pinned DoomTools, shared launch contract, package validation.

## Active — Phase 1: E1M1 Graybox (`v0.1.0`)

- Generate and validate the complete E1M1 critical path.
- Keep the map editable as UDMF and directly testable in the locally built `sol-engine` fork.
- End E1M1 through a normal Doom exit and preserve the statistics/world-map intermission.
- Establish story, standard, and horde population profiles.
- Repair inherited Linux and Windows CI.
- Integrate the shared application icon.

Exit gate: E1M1 launches through `sol-engine`, can be completed repeatedly, shows the classic Doom intermission, contains no progression blockers, and all required workflows pass.

## Phase 2 — Story Authoring (`v0.2.0`)

Add stable event IDs, objectives, subtitles, radio events, save/load validation, and reusable story prefabs within individual maps.

## Phase 3 — Classic Episode Authoring (`v0.3.0`)

Add map title patches, par times, secret exits, world-map markers, episode-complete screens, and editor validation for Doom-style episode progression.

## Phase 4 — Finished Vertical Slice (`v0.5.0`)

Replace graybox content with production mapping, original assets, final combat pacing, lighting, soundscape, benchmarks, and tester packages.

## Phase 5 — Campaign Pipeline (`v0.6.0–v0.8.0`)

Automate map linting, packaging, campaign-state inspection, asset provenance, and regression coverage.

## Phase 6 — Standalone Toolset (`v0.9.0`)

Complete SOL editor identity, defaults, project creation, local `sol-engine` discovery, installers, and diagnostics.

## Phase 7 — Release (`v1.0.0`)

Stabilize project formats, campaign production support, licenses, credits, source distribution, and maintenance policy.

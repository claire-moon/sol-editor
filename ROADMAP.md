# SOL Development Roadmap

This roadmap is shared with `sol-engine`. Each phase must remain buildable and testable before the next phase begins.

## Phase 0 — Foundation (`v0.0.1`)

- Pin DoomTools to a known commit.
- Add one-command bootstrap, build, and test scripts.
- Establish the SOL project workspace and UDMF policy.
- Document the expanded E1M1 vertical slice.
- Reserve shared engine/editor branding paths.
- Add automated foundation validation.

Exit gate: a clean checkout validates, DoomTools can be reproduced, a development package can be built, and the launch contract matches `sol-engine`.

## Phase 1 — E1M1 Graybox (`v0.1.0`)

- Build the complete critical path.
- Establish arrival, hangar, security, maintenance, reactor, exterior, command, and transition zones.
- Add navigation landmarks, optional loops, locked returns, and shortcuts.
- Implement temporary story markers and encounter triggers.
- Support `story`, `standard`, and `horde` population profiles.

Exit gate: the level can be completed repeatedly without progression blockers or unresolved editor errors.

## Phase 2 — Story Authoring (`v0.2.0`)

- Add editor conventions for campaign variables, event channels, objectives, subtitles, radio messages, and environmental sequences.
- Add validation for duplicate event IDs and one-shot story state.
- Create reusable story and encounter prefabs.

Exit gate: scripted events survive save/load and can be inspected from documented map metadata.

## Phase 3 — Seam Authoring (`v0.3.0`)

- Add paired transition anchors.
- Validate position, angle, geometry, lighting direction, audio, and door-state continuity.
- Export transition metadata consumed by `sol-engine`.
- Add a two-map regression project.

Exit gate: E1M1 and E1M2 test maps feel spatially connected and produce no state-transfer errors.

## Phase 4 — Vertical Slice (`v0.5.0`)

- Replace temporary geometry and markers with production-quality mapping.
- Finalize combat pacing, environmental storytelling, lighting, soundscape, and performance budgets.
- Add benchmark saves and automated map checks.
- Package Linux and Windows development builds.

Exit gate: external testers can install, launch, complete, and report the slice without developer intervention.

## Phase 5 — Campaign Pipeline (`v0.6.0–v0.8.0`)

- Automated map linting and packaging.
- Campaign state inspector.
- Asset provenance manifest.
- Regression maps for transitions, saves, scripts, portals, and high enemy counts.
- Documented process for producing connected levels.

## Phase 6 — Standalone Toolset (`v0.9.0`)

- SOL editor identity and defaults.
- Engine discovery and project creation workflow.
- Installable editor packages.
- Original branding integrated without removing required upstream attribution.

## Phase 7 — Release (`v1.0.0`)

- Complete campaign production support.
- Stable project format and migration policy.
- Final licenses, credits, source distribution, and maintenance documentation.

## Workflow rules

- Keep `master` usable as the upstream-compatible base.
- Develop releases on `sol/vX.Y.Z-*` branches.
- Keep upstream synchronization commits separate from SOL feature commits.
- Do not commit commercial IWAD content.
- Update documentation in the same pull request as implementation.
- Validate every editor feature against the corresponding engine contract.
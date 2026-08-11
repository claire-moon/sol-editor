# SOL Editor Engine-First Development Roadmap

`sol-editor` is the SOL authoring fork based on Ultimate Doom Builder. Engine
development now precedes editor feature expansion: the editor stays in
maintenance mode through the SOL engine beta, then consumes a frozen versioned
SDK and becomes the complete supported authoring environment for SOL content.
Story authoring and production level design remain parked until that integration
is complete.

## Completed foundation

- `v0.0.1`: repository foundation, pinned DoomTools, launch contract, and package
  validation.
- `v0.1.0`: deterministic E1M1 graybox, classic progression, setup cockpit,
  eighteen-resource wadpack contract 2, and single `sol.pk3` playtesting.
- `v0.2.0`: story contract 1, strict authoring validation, and packaging of the
  intentionally empty canonical story manifest.

## Maintenance period — engine `v0.3.0` through `v0.12.0`

Editor changes during engine-first work are limited to CI fixes, security/
reliability maintenance, compatibility updates required by engine contract
changes, and deterministic non-production regression fixtures. No story text,
narrative triggers, production levels, or broad new authoring UI is introduced.

Engine milestones are:

1. `v0.3.0`: SOL identity, separate user state, Doom IWAD discovery, and native
   mandatory `sol.pk3` mounting.
2. `v0.4.0`: engine-owned wadpack/bundle tooling, wadpack contract 3, bundle
   contract 2, canonical SOL defaults, and geometry contract 1's phase-portal
   impossible-room fixture plus conventional linked-portal lab.
3. `v0.5.0`: SOL title/options/pause UI, centered 4:3 presentation, fixed 8000 Hz
   default, exact Classic/Modern framerate option, and WW Alpha HUD wrapper.
4. `v0.6.0`: four-Chapter lifecycle, in-memory runs, Soulsphere extra life,
   unlock progression, secrets, and stat-free completion.
5. `v0.7.0`: SOL-owned custom UV/Final Custom Doom behavior.
6. `v0.8.0`: sprint/stamina, capability integration, sparse music cues,
   ambience, powerup presentation, and gore/dismemberment interfaces.
7. `v0.9.0`: deterministic OpenGL/Vulkan signature sky system.
8. `v0.10.0`: validated connected hard-load map transitions.
9. `v0.11.0`: legacy-hardware benchmarks and optimization.
10. `v0.12.0`: beta stabilization, packaging, and frozen SOL SDK contract 1.

During `v0.4.0`, authority for the wadpack manifest, third-party import and
locking, `sol.pk3` construction, slot allocation, defaults, and bundle
provenance moves to `sol-engine`. The editor consumes the resulting contracts
and continues placing its temporary playtest map after `sol.pk3` so test content
retains precedence.

The generated E1M1 fixture is expanded in v0.4 into a deterministic,
monster-free systems testbed with multiple connected rooms, stock placeholder
materials, varied lighting, all major Doom weapons, dense stock objects outside
the deliberately clear phase-room route, a stateful phase-room doorway, and a
separate conventional linked-portal lab. It exists to exercise ReLite, Universal
Ambience, renderer/resource loading, and authoring integration; it is not
production level design.

## `v0.13.0`: palette and voxel toolchain

Goal: make graphical treatment fast, deterministic, and available from both the
command line and a compact graphical editor.

- Define one canonical 256-color SOL master palette plus derived Chapter/effect
  colormaps and translations.
- Require indexed textures, sprites, voxels, and HUD assets to validate against
  the palette; allow truecolor skies/weather/signature shaders.
- Build `sol-palette` for inspection, editing, remapping, validation, and batch
  conversion.
- Build `sol-voxel` as a CLI and compact GUI using editable `.vox` sources plus
  SOL sidecar metadata for pivot, scale, palette, sprite/frame mapping, and
  export configuration.
- Support 3D/slice paint, erase, fill, selection, mirror, rotate, translate,
  crop, pivot editing, undo/redo, before/after compare, deterministic KVX export,
  batch conversion, and live engine preview.
- Keep Voxel Doom and NashGore voxel archives intact; SOL edits load as later
  overrides. Audit voxel assets separately before distribution.

Exit gate: source-to-KVX round trips preserve mapping/pivot metadata, export
reproducibly, obey the SOL palette, and hot-reload in `sol-engine`.

## `v0.14.0`: SOL SDK integration

Goal: remove sibling-source assumptions and author/test through the packaged SDK.

- Discover installed/versioned SDKs without an engine source checkout or
  vendored engine copy.
- Consume campaign, sky, audio, defaults, palette, voxel, bundle, transition,
  and story schemas from SDK contract 1.
- Launch packaged `sol-engine` with its mandatory `sol.pk3`; append the editor's
  temporary map last.
- Surface contract mismatch, missing bundle/IWAD, invalid project, and modified-
  run diagnostics.
- Preserve story contract 1 and its empty-manifest validity without expanding
  narrative tooling.

Exit gate: packaged editor and engine can author, validate, package, and playtest
a map with neither source repository present.

## `v0.15.0`: complete SOL authoring UX

Goal: make `sol-editor` the only supported practical tool for producing complete
SOL levels through superior schemas, previews, compilation, and validation—not
through opaque formats.

- Add visual Chapter/map routing and transition-seam editors.
- Add sky preset/per-map controls with engine preview.
- Add sparse music-cue, ambience-trigger, unlock, sprint, flashlight, laser,
  targeting, Soulsphere, and Chapter-lifecycle authoring/validation.
- Integrate `sol-palette` and `sol-voxel` editing and live preview.
- Add supported DeHackEd/gameplay tuning and resource-ownership interfaces.
- Provide one-click validate, package, benchmark, and engine playtest actions.
- Keep all schemas and generated formats documented and versioned.

Exit gate: a non-story regression Chapter can be authored, validated, packaged,
played, and benchmarked entirely through the editor.

## Deferred until after `v0.15.0`

- Concrete story/event IDs, objectives, subtitles, radio dialogue, environmental
  sequences, and narrative prefabs.
- Production level design, final graphical treatment, final sound replacement,
  campaign content, and story authoring.
- Explore/JP mode and the proposed invisible sanity system.

## Preserved contracts and release boundaries

- Final gameplay runtime remains one physical `sol.pk3`.
- Wadpack contract 3 retires slot 11, preserves 12–18, assigns
  PreciseCrosshair v1.5.0 to slot 19, reserves slot 20, and assigns
  runtime/content to 21–22.
- Story IDs remain contract 1 in the 1–65535 range and are not repurposed.
- Doom statistics may remain internal, but the future SOL player presentation is
  stat-free and uses Chapters rather than Episodes.
- Complete third-party bundles remain local-only until every included asset has
  documented redistribution permission. PSX sound effects stay a development
  placeholder in slot 12 until user-supplied SOL sounds replace them.

# SOL Editor

`sol-editor` is the SOL content-development fork based on Ultimate Doom Builder. It coordinates map authoring, DoomTools-based project automation, validation, packaging, and test launches against `sol-engine`.

## Responsibilities

- Author and validate SOL maps in UDMF.
- Pin and bootstrap a shared DoomTools revision.
- Build content packages without committing commercial IWAD data.
- Launch development maps against a selected SOL engine binary.
- Provide transition-anchor, encounter, story-event, and performance tooling.

## v0.0.1 quick start

```bash
bash tools/sol-bootstrap-doomtools.sh
bash tools/sol-build.sh
SOL_ENGINE=/path/to/uzdoom DOOM_IWAD=/path/to/doom.wad \
  bash tools/sol-test.sh E1M1
```

Build Ultimate Doom Builder itself using the existing upstream build process:

```bash
make
```

## Repository layout

- `Source/`, `Builder.sln`, and related files: inherited editor source.
- `sol-project/`: SOL map and resource workspace.
- `tools/sol-*`: collaboration bootstrap, build, and launch commands.
- `docs/sol/`: release plans and authoring contracts.
- `branding/sol/`: approved SOL application identity assets.

## Content policy

Do not commit Doom, Doom II, or other commercial IWAD data. Local editor configuration may reference a legally obtained IWAD through environment variables or ignored user settings.
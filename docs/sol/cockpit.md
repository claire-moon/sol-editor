# SOL setup cockpit

`tools/sol-cockpit.sh` configures the sibling `sol-engine`, `sol-editor`, and
`vend` workspace. It selects a user-owned IWAD, locates or builds both programs,
writes `.sol-env`, and optionally installs `sol`, `sol-play`, and `sol-edit`
commands.

Midnight Commander runs with subshell and X11 modifier handling disabled through
an isolated profile under `.sol-cockpit`; the user's normal MC configuration is
not changed.

## Locked wadpack stage

Wadpack contract 2 requires all eighteen approved resources. `sol-play` and
`sol-edit` trigger the importer when no valid canonical `sol.pk3` exists
and the local build inputs are incomplete:

```bash
bash tools/sol-wadpack-setup.sh
```

The selector searches common local folders first. If files remain missing, it
opens a separate isolated MC session. Highlight the folder containing the
resources, press `F2`, choose `W`, review the import report, and press `F10`.

Use:

```bash
bash tools/sol-wadpack-setup.sh --status
```

to inspect all eighteen build inputs.

## Build the canonical runtime bundle

After all eighteen entries pass:

```bash
bash tools/sol-package.sh
```

This creates canonical bundle contract 1:

```text
build/sol/sol.pk3
```

The bundle contains the eighteen normalized resources, SOL runtime, E1M1
content, component hashes, and third-party attribution. Each component is stored
intact under a numbered root-level `.wad` carrier for the embedded-resource
loader inherited by SOL Engine. The editor writes bundle version 0.3.0 into
`SOLPACK.json`, and the native engine validates and mounts the adjacent file at
startup. The same bundle is copied into local engine/editor package directories.

Once a valid `sol.pk3` exists, normal gameplay and editor playtests operate from
that one file without the loose `vend/wadpack/runtime` files. In a development
checkout, SOL regenerates the small project-owned runtime/map components and
compares their exact hashes against `SOLPACK.json`; the large bundle is rewritten
only when those components or attribution changed.

## Subsequent runs

```bash
sol
sol-play E1M1
sol-edit
```

`sol-play` starts native SOL Engine without passing `-file sol.pk3`; the engine
loads its verified adjacent sidecar and mounts the embedded 01→20 stack.
`sol-edit` materializes only the eighteen authoring resources for UDB's resource
browser. In-editor tests use the same sidecar and append UDB's temporary map so
the test map retains final precedence. Older UZDoom development binaries remain
supported through a compatibility path that passes `-file sol.pk3` explicitly.

Local engine builds produce a native `sol-engine` executable. Editor tooling
copies `sol.pk3` beside the detected executable and never replaces it with the
obsolete shell launcher.

Setup selects a user-owned Doom IWAD candidate named `DOOM.WAD` or
`DOOMU.WAD`; other known Doom-family filenames are intentionally not selected.
Native SOL Engine v0.3 inspects the contents at launch and is the final authority
that accepts registered Doom/Ultimate Doom and rejects shareware or renamed
unsupported data.

See `docs/sol/wadpack.md` and `THIRD_PARTY.md` for packaging and attribution
details.

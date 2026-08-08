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
`sol-edit` trigger the importer when no valid self-contained `sol.pk3` exists
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

## Build the self-contained runtime

After all eighteen entries pass:

```bash
bash tools/sol-package.sh
```

This creates canonical bundle contract 1:

```text
build/sol/sol.pk3
```

The bundle contains the eighteen normalized resources, SOL runtime, E1M1
content, component hashes, and third-party attribution. The same file is copied
into the local engine/editor package directories.

Once a valid `sol.pk3` exists, normal runtime/editor loading can operate from the
bundle without the loose `vend/wadpack/runtime` files. In a development checkout,
SOL regenerates the small project-owned runtime/map components and compares their
exact hashes against `SOLPACK.json`; the large bundle is rewritten only when
those components or attribution changed.

## Subsequent runs

```bash
sol
sol-play E1M1
sol-edit
```

`sol-play` materializes and mounts all bundle components in locked order.
`sol-edit` materializes the eighteen authoring resources from the same bundle,
and in-editor tests route through the same SOL runtime contract.

The symlink-safe wrappers resolve the repository from any current directory.
See `docs/sol/wadpack.md` and `THIRD_PARTY.md` for packaging and attribution
details.

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
content, component hashes, and third-party attribution. Each component is stored
intact under a numbered root-level `.wad` carrier so UZDoom's native embedded-
resource loader recursively mounts the complete stack from one `-file sol.pk3`.
The same bundle is copied into local engine/editor package directories.

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

`sol-play` passes the single `sol.pk3` to UZDoom; UZDoom mounts the embedded
01→20 stack natively. `sol-edit` materializes only the eighteen authoring
resources for UDB's resource browser. In-editor tests return to the native
one-file `sol.pk3` path, followed by UDB's temporary map.

Local engine builds also install a `sol-engine` launcher beside UZDoom and copy
`sol.pk3` beside it, so that package can run without the sibling editor checkout.

See `docs/sol/wadpack.md` and `THIRD_PARTY.md` for packaging and attribution
details.

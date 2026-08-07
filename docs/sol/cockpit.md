# SOL setup cockpit

`tools/sol-cockpit.sh` configures the sibling `sol-engine`, `sol-editor`, and
`vend` workspace. It selects a user-owned IWAD, locates or builds both programs,
packages SOL, writes `.sol-env`, and optionally installs `sol`, `sol-play`, and
`sol-edit` commands.

Midnight Commander runs with subshell and X11 modifier handling disabled through
an isolated profile under `.sol-cockpit`; the user's normal MC configuration is
not changed.

## Locked wadpack stage

The approved visual/audio configuration is a second local setup contract.
`sol-play` and `sol-edit` verify it automatically. When incomplete they run:

```bash
bash tools/sol-wadpack-setup.sh
```

The selector searches common local folders first. If files remain missing, it
opens a separate isolated MC session. Highlight the folder containing the
Rocket Launcher resources, press `F2`, choose `W`, review the import report, and
press `F10`. The launch remains blocked until all required entries are present.

The main cockpit's `V` and `S` actions now include locked-wadpack verification
and status after the engine/editor checks.

Use:

```bash
bash tools/sol-wadpack-setup.sh --status
```

to view each locked entry. Full details are in `docs/sol/wadpack.md`.

## Subsequent runs

```bash
sol
sol-play
sol-edit
```

The symlink-safe wrappers resolve the repository from any current directory.

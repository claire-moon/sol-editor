#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
workspace="$tmp/workspace"
engine_root="$workspace/sol-engine"
vend_root="$workspace/vend"
mkdir -p "$engine_root/build" "$engine_root/tools"

cat > "$engine_root/build/sol-engine" <<'ENGINE'
#!/usr/bin/env bash
exit 0
ENGINE
chmod +x "$engine_root/build/sol-engine"

cat > "$tmp/editor" <<'EDITOR'
#!/usr/bin/env bash
exit 0
EDITOR
chmod +x "$tmp/editor"

cat > "$engine_root/tools/sol-package.sh" <<'PACKAGE'
#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/build/sol"
printf 'runtime\n' > "$root/build/sol/sol-v0.1.0-dev.pk3"
printf '%s\n' "$root/build/sol/sol-v0.1.0-dev.pk3"
PACKAGE
chmod +x "$engine_root/tools/sol-package.sh"

printf 'IWADfixture' > "$tmp/DOOM.WAD"
env_file="$tmp/sol.env"
bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$vend_root" \
    --editor "$tmp/editor" \
    --primary-iwad "$tmp/DOOM.WAD" \
    --env-file "$env_file" \
    --copy --no-search >/dev/null

test -f "$vend_root/iwads/doom.wad"
test ! -L "$vend_root/iwads/doom.wad"
test -s "$vend_root/IWADS.sha256"
# shellcheck disable=SC1090
source "$env_file"
test "$SOL_ENGINE" = "$engine_root/build/sol-engine"
test "$SOL_EDITOR" = "$tmp/editor"
test "$DOOM_IWAD" = "$vend_root/iwads/doom.wad"
test -f "$SOL_RUNTIME_PKG"

printf 'PWADbad' > "$tmp/bad.wad"
if bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$tmp/bad-vend" \
    --engine "$engine_root/build/sol-engine" \
    --editor "$tmp/editor" \
    --iwad "$tmp/bad.wad" \
    --env-file "$tmp/bad.env" \
    --no-search >/dev/null 2>&1; then
    printf 'invalid IWAD was accepted\n' >&2
    exit 1
fi

printf 'IWADalternate' > "$tmp/DOOMU.WAD"
bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$tmp/doomu-vend" \
    --editor "$tmp/editor" \
    --iwad "$tmp/DOOMU.WAD" \
    --env-file "$tmp/doomu.env" \
    --copy --no-search >/dev/null
# shellcheck disable=SC1090,SC1091
source "$tmp/doomu.env"
test "$DOOM_IWAD" = "$tmp/doomu-vend/iwads/doomu.wad"

printf 'IWADunsupported' > "$tmp/DOOM2.WAD"
if bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$tmp/doom2-vend" \
    --editor "$tmp/editor" \
    --primary-iwad "$tmp/DOOM2.WAD" \
    --env-file "$tmp/doom2.env" \
    --copy --no-search >/dev/null 2>&1; then
    printf 'unsupported Doom II IWAD was selected\n' >&2
    exit 1
fi
test ! -e "$tmp/doom2.env"

printf 'workspace initializer tests passed\n'

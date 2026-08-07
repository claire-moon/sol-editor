#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
workspace="$tmp/workspace"
engine_root="$workspace/sol-engine"
vend_root="$workspace/vend"
mkdir -p "$engine_root/build" "$engine_root/tools"

cat > "$engine_root/build/uzdoom" <<'ENGINE'
#!/usr/bin/env bash
exit 0
ENGINE
chmod +x "$engine_root/build/uzdoom"

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
    --engine "$engine_root/build/uzdoom" \
    --editor "$tmp/editor" \
    --primary-iwad "$tmp/DOOM.WAD" \
    --env-file "$env_file" \
    --copy --no-search >/dev/null

test -f "$vend_root/iwads/doom.wad"
test ! -L "$vend_root/iwads/doom.wad"
test -s "$vend_root/IWADS.sha256"
# shellcheck disable=SC1090
source "$env_file"
test "$SOL_ENGINE" = "$engine_root/build/uzdoom"
test "$SOL_EDITOR" = "$tmp/editor"
test "$DOOM_IWAD" = "$vend_root/iwads/doom.wad"
test -f "$SOL_RUNTIME_PKG"

printf 'PWADbad' > "$tmp/bad.wad"
if bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$tmp/bad-vend" \
    --engine "$engine_root/build/uzdoom" \
    --editor "$tmp/editor" \
    --iwad "$tmp/bad.wad" \
    --env-file "$tmp/bad.env" \
    --no-search >/dev/null 2>&1; then
    printf 'invalid IWAD was accepted\n' >&2
    exit 1
fi

printf 'workspace initializer tests passed\n'

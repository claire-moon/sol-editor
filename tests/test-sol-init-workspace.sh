#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
workspace="$tmp/workspace"
engine_root="$workspace/sol-engine"
vend_root="$workspace/vend"
mkdir -p "$engine_root/build" "$engine_root/tools" "$workspace/sol-editor"

cat > "$engine_root/build/uzdoom" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$engine_root/build/uzdoom"

cat > "$engine_root/tools/sol-package.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/build/sol"
printf 'runtime\n' > "$root/build/sol/sol-v0.1.0-dev.pk3"
printf '%s\n' "$root/build/sol/sol-v0.1.0-dev.pk3"
EOF
chmod +x "$engine_root/tools/sol-package.sh"

printf 'IWADfixture' > "$tmp/DOOM.WAD"
env_file="$tmp/sol.env"
bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$vend_root" \
    --engine "$engine_root/build/uzdoom" \
    --primary-iwad "$tmp/DOOM.WAD" \
    --env-file "$env_file" \
    --copy \
    --no-search

test -f "$vend_root/iwads/doom.wad"
test ! -L "$vend_root/iwads/doom.wad"
test -s "$vend_root/IWADS.sha256"
test -f "$env_file"
# shellcheck disable=SC1090
source "$env_file"
test "$SOL_ENGINE" = "$engine_root/build/uzdoom"
test "$DOOM_IWAD" = "$vend_root/iwads/doom.wad"
test -f "$SOL_RUNTIME_PKG"

link_vend="$tmp/link-vend"
link_env="$tmp/link.env"
bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$link_vend" \
    --engine "$engine_root/build/uzdoom" \
    --iwad "$tmp/DOOM.WAD" \
    --env-file "$link_env" \
    --link \
    --no-search

test -L "$link_vend/iwads/doom.wad"

printf 'PWADbad' > "$tmp/bad.wad"
if bash "$root/tools/sol-init-workspace.sh" \
    --workspace "$workspace" \
    --engine-root "$engine_root" \
    --vend "$tmp/bad-vend" \
    --engine "$engine_root/build/uzdoom" \
    --iwad "$tmp/bad.wad" \
    --env-file "$tmp/bad.env" \
    --no-search >/dev/null 2>&1; then
    printf 'invalid IWAD was accepted\n' >&2
    exit 1
fi

printf 'workspace initializer tests passed\n'

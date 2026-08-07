#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
workspace="$tmp/workspace"
engine_root="$workspace/sol-engine"
vend_root="$workspace/vend"
state_dir="$tmp/state"
env_file="$tmp/sol.env"
editor_launcher="$tmp/sol-editor-launcher"
engine_launcher="$engine_root/build/uzdoom"
fixture="$tmp/DOOM.WAD"
mkdir -p "$engine_root/tools" "$engine_root/build" "$vend_root"

cat > "$engine_launcher" <<'ENGINE'
#!/usr/bin/env bash
printf 'engine %s\n' "$*"
ENGINE
chmod +x "$engine_launcher"

cat > "$editor_launcher" <<'EDITOR'
#!/usr/bin/env bash
printf 'editor %s\n' "$*"
EDITOR
chmod +x "$editor_launcher"

cat > "$engine_root/tools/sol-package.sh" <<'PACKAGE'
#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/build/sol"
printf 'runtime\n' > "$root/build/sol/sol-v0.1.0-dev.pk3"
printf '%s\n' "$root/build/sol/sol-v0.1.0-dev.pk3"
PACKAGE
chmod +x "$engine_root/tools/sol-package.sh"
printf 'IWADfixture' > "$fixture"

fake_mc="$tmp/mc"
cat > "$fake_mc" <<'MC'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$SOL_COCKPIT_STATE/mc-args"
printf '%s\n' "$MC_PROFILE_ROOT" > "$SOL_COCKPIT_STATE/mc-profile-root"
"$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" select-iwad copy "$FIXTURE_IWAD"
MC
chmod +x "$fake_mc"

export SOL_WORKSPACE="$workspace"
export SOL_ENGINE_ROOT="$engine_root"
export SOL_VEND_ROOT="$vend_root"
export SOL_COCKPIT_STATE="$state_dir"
export SOL_ENV_FILE="$env_file"
export SOL_ENGINE="$engine_launcher"
export SOL_EDITOR="$editor_launcher"
export SOL_COCKPIT_MC_BIN="$fake_mc"
export SOL_COCKPIT_ASSUME_YES=1
export SOL_COCKPIT_NO_PAUSE=1
export SOL_INSTALL_LAUNCHERS=0
export FIXTURE_IWAD="$fixture"

bash "$root/tools/sol-cockpit.sh" --setup-only --no-build

test -f "$env_file"
test -f "$vend_root/iwads/doom.wad"
test ! -L "$vend_root/iwads/doom.wad"
test -s "$vend_root/IWADS.sha256"
grep -Eq '(^| )-u( |$)' "$state_dir/mc-args"
grep -Eq '(^| )-X( |$)' "$state_dir/mc-args"
test "$(cat "$state_dir/mc-profile-root")" = "$state_dir/mc-profile"
grep -F 'auto_menu=true' "$state_dir/mc-profile/.config/mc/ini"
grep -F 'Use highlighted IWAD' "$state_dir/mc-profile/.config/mc/menu"

# shellcheck disable=SC1090
source "$env_file"
test "$SOL_ENGINE" = "$engine_launcher"
test "$SOL_EDITOR" = "$editor_launcher"
test "$DOOM_IWAD" = "$vend_root/iwads/doom.wad"
test -f "$SOL_RUNTIME_PKG"

bash "$root/tools/sol-cockpit.sh" --verify >/dev/null
bash "$root/tools/sol-cockpit.sh" --status | grep -F '[PASS] Engine'

# A subsequent setup with an explicit IWAD must be idempotent and need no MC.
rm -f "$state_dir/mc-args"
bash "$root/tools/sol-cockpit.sh" --setup-only --no-build --iwad "$fixture" >/dev/null
test ! -e "$state_dir/mc-args"

# Replacing the IWAD from the cockpit updates the generated environment.
printf 'IWADsecond' > "$tmp/DOOM2.WAD"
"$root/tools/sol-cockpit-action.sh" select-iwad link "$tmp/DOOM2.WAD" >/dev/null
test -L "$vend_root/iwads/doom2.wad"
# shellcheck disable=SC1090
source "$env_file"
test "$DOOM_IWAD" = "$vend_root/iwads/doom2.wad"

printf 'PWADbad' > "$tmp/bad.wad"
if "$root/tools/sol-cockpit-action.sh" select-iwad copy "$tmp/bad.wad" >/dev/null 2>&1; then
    printf 'invalid IWAD was accepted\n' >&2
    exit 1
fi

printf 'SOL cockpit tests passed\n'

#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/engine-root/tools" "$tmp/engine-root/build/sol"

ln -s "$root/tools/sol-cockpit.sh" "$tmp/bin/sol"
ln -s "$root/tools/sol-test.sh" "$tmp/bin/sol-play"
ln -s "$root/tools/sol-open-editor.sh" "$tmp/bin/sol-edit"

"$tmp/bin/sol" --help | grep -F 'First-run setup and ongoing Midnight Commander cockpit'

cat > "$tmp/editor" <<'EDITOR'
#!/usr/bin/env bash
printf 'editor %s\n' "$*"
EDITOR
chmod +x "$tmp/editor"

cat > "$tmp/engine" <<'ENGINE'
#!/usr/bin/env bash
printf 'engine %s\n' "$*"
ENGINE
chmod +x "$tmp/engine"

cat > "$tmp/engine-root/tools/sol-package.sh" <<'PACKAGE'
#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/build/sol"
printf 'fresh runtime\n' > "$root/build/sol/sol-v0.1.0-dev.pk3"
printf 'called\n' >> "$root/build/sol/package-calls"
printf '%s\n' "$root/build/sol/sol-v0.1.0-dev.pk3"
PACKAGE
chmod +x "$tmp/engine-root/tools/sol-package.sh"

printf 'IWADfixture' > "$tmp/doom.wad"
printf 'stale runtime\n' > "$tmp/stale-runtime.pk3"
cat > "$tmp/sol.env" <<ENV
export SOL_EDITOR='$tmp/editor'
export SOL_ENGINE='$tmp/engine'
export SOL_ENGINE_ROOT='$tmp/engine-root'
export SOL_RUNTIME_PKG='$tmp/stale-runtime.pk3'
export DOOM_IWAD='$tmp/doom.wad'
ENV

SOL_ENV_FILE="$tmp/sol.env" SOL_SKIP_WADPACK=1 "$tmp/bin/sol-edit" --fixture | grep -F 'editor --fixture'
play_output=$(SOL_ENV_FILE="$tmp/sol.env" SOL_SKIP_DOOMTOOLS=1 SOL_SKIP_WADPACK=1 "$tmp/bin/sol-play" E1M1)
printf '%s\n' "$play_output" | grep -F 'engine -iwad'
printf '%s\n' "$play_output" | grep -F "$tmp/engine-root/build/sol/sol-v0.1.0-dev.pk3"
! printf '%s\n' "$play_output" | grep -F "$tmp/stale-runtime.pk3"
test "$(wc -l < "$tmp/engine-root/build/sol/package-calls")" -eq 1

printf 'symlink launcher and fresh-runtime tests passed\n'

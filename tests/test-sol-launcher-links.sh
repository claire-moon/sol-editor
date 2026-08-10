#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
mkdir -p "$tmp/bin" "$engine_root/tools" "$engine_root/sol"

ln -s "$root/tools/sol-cockpit.sh" "$tmp/bin/sol"
ln -s "$root/tools/sol-test.sh" "$tmp/bin/sol-play"
ln -s "$root/tools/sol-open-editor.sh" "$tmp/bin/sol-edit"

"$tmp/bin/sol" --help | grep -F 'First-run setup and ongoing Midnight Commander cockpit'

cat > "$engine_root/tools/sol-bundle.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
target=${SOL_BUNDLE:?}
mkdir -p "$(dirname "$target")"
test -f "$target" || printf 'SOL v0.4 fixture\n' > "$target"
printf '%s\n' "$target"
SH
chmod +x "$engine_root/tools/sol-bundle.sh"

cat > "$engine_root/tools/sol-bundle.py" <<'PY'
#!/usr/bin/env python3
import sys
command = sys.argv[1] if len(sys.argv) > 1 else ''
if command in {'verify', 'materialize'}:
    raise SystemExit(0)
raise SystemExit(2)
PY
chmod +x "$engine_root/tools/sol-bundle.py"
printf '{}\n' > "$engine_root/sol/wadpack.json"
printf '{}\n' > "$engine_root/sol/version.json"

cat > "$tmp/editor" <<'EDITOR'
#!/usr/bin/env bash
printf 'editor %s\n' "$*"
EDITOR
cat > "$tmp/bin/sol-engine" <<'ENGINE'
#!/usr/bin/env bash
printf 'engine %s\n' "$*"
ENGINE
chmod +x "$tmp/editor" "$tmp/bin/sol-engine"
printf 'IWADfixture' > "$tmp/doom.wad"

bundle="$engine_root/build/sol/sol.pk3"
cat > "$tmp/sol.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_EDITOR='$tmp/editor'
export SOL_ENGINE_ROOT='$engine_root'
export SOL_ENGINE='$tmp/bin/sol-engine'
export SOL_BUNDLE='$bundle'
export DOOM_IWAD='$tmp/doom.wad'
ENV

SOL_ENV_FILE="$tmp/sol.env" "$tmp/bin/sol-edit" --fixture | grep -F 'editor --fixture'
play_output=$(SOL_ENV_FILE="$tmp/sol.env" "$tmp/bin/sol-play" E1M1)
printf '%s\n' "$play_output" | grep -F "engine -iwad $tmp/doom.wad +map E1M1"
! printf '%s\n' "$play_output" | grep -F "$bundle"

printf 'v0.4 symlink launcher tests passed\n'

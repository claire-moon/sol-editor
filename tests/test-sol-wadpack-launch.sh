#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
mkdir -p "$engine_root/tools" "$engine_root/sol" "$tmp/bin"

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
import pathlib
import sys
if len(sys.argv) < 2:
    raise SystemExit(2)
if sys.argv[1] == 'verify':
    raise SystemExit(0)
if sys.argv[1] == 'materialize':
    raise SystemExit(0)
raise SystemExit(2)
PY
chmod +x "$engine_root/tools/sol-bundle.py"
printf '{}\n' > "$engine_root/sol/wadpack.json"
printf '{}\n' > "$engine_root/sol/version.json"

cat > "$tmp/bin/sol-engine" <<'ENGINE'
#!/usr/bin/env bash
printf '%s\n' "$@"
ENGINE
cat > "$tmp/bin/uzdoom" <<'ENGINE'
#!/usr/bin/env bash
printf '%s\n' "$@"
ENGINE
cat > "$tmp/bin/editor" <<'EDITOR'
#!/usr/bin/env bash
exit 0
EDITOR
chmod +x "$tmp/bin/sol-engine" "$tmp/bin/uzdoom" "$tmp/bin/editor"
printf 'IWADfixture' > "$tmp/doom.wad"
printf 'editor map\n' > "$tmp/editor-map.wad"

bundle="$engine_root/build/sol/sol.pk3"
cat > "$tmp/native.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_ENGINE_ROOT='$engine_root'
export SOL_EDITOR='$tmp/bin/editor'
export SOL_ENGINE='$tmp/bin/sol-engine'
export SOL_BUNDLE='$bundle'
export DOOM_IWAD='$tmp/doom.wad'
ENV

native_output=$(SOL_ENV_FILE="$tmp/native.env" bash "$root/tools/sol-test-main.sh" E1M1)
printf '%s\n' "$native_output" > "$tmp/native-args"
grep -Fx -- '-iwad' "$tmp/native-args"
grep -Fx "$tmp/doom.wad" "$tmp/native-args"
grep -Fx '+map' "$tmp/native-args"
grep -Fx 'E1M1' "$tmp/native-args"
! grep -Fx "$bundle" "$tmp/native-args"
test -f "$bundle"

native_editor_output=$(SOL_ENV_FILE="$tmp/native.env" \
    bash "$root/tools/sol-editor-engine.sh" -file "$tmp/editor-map.wad" +map E1M1)
printf '%s\n' "$native_editor_output" > "$tmp/native-editor-args"
grep -Fx "$tmp/editor-map.wad" "$tmp/native-editor-args"
! grep -Fx "$bundle" "$tmp/native-editor-args"

cat > "$tmp/legacy.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_ENGINE_ROOT='$engine_root'
export SOL_EDITOR='$tmp/bin/editor'
export SOL_ENGINE='$tmp/bin/uzdoom'
export SOL_BUNDLE='$bundle'
export DOOM_IWAD='$tmp/doom.wad'
ENV

legacy_output=$(SOL_ENV_FILE="$tmp/legacy.env" bash "$root/tools/sol-test-main.sh" E1M1)
printf '%s\n' "$legacy_output" > "$tmp/legacy-args"
grep -Fx -- '-file' "$tmp/legacy-args"
bundle_line=$(grep -nFx "$bundle" "$tmp/legacy-args" | cut -d: -f1)
map_line=$(grep -nFx '+map' "$tmp/legacy-args" | cut -d: -f1)
test -n "$bundle_line"
test -n "$map_line"
test "$bundle_line" -lt "$map_line"

legacy_editor_output=$(SOL_ENV_FILE="$tmp/legacy.env" \
    bash "$root/tools/sol-editor-engine.sh" -file "$tmp/editor-map.wad" +map E1M1)
printf '%s\n' "$legacy_editor_output" > "$tmp/legacy-editor-args"
bundle_line=$(grep -nFx "$bundle" "$tmp/legacy-editor-args" | cut -d: -f1)
map_line=$(grep -nFx "$tmp/editor-map.wad" "$tmp/legacy-editor-args" | cut -d: -f1)
test -n "$bundle_line"
test -n "$map_line"
test "$bundle_line" -lt "$map_line"

printf 'v0.4 native sidecar launch integration tests passed\n'

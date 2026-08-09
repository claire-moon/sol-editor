#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/source" "$tmp/vend" "$tmp/bin"

native_engine="$tmp/bin/Linux-x86_64-SOL-Engine-0.3.0-test.AppImage"
cat > "$native_engine" <<'ENGINE'
#!/usr/bin/env bash
printf '%s\n' "$@"
ENGINE
chmod +x "$native_engine"
cat > "$tmp/bin/uzdoom" <<'ENGINE'
#!/usr/bin/env bash
printf '%s\n' "$@"
ENGINE
chmod +x "$tmp/bin/uzdoom"
cat > "$tmp/bin/editor" <<'EDITOR'
#!/usr/bin/env bash
exit 0
EDITOR
chmod +x "$tmp/bin/editor"

printf 'IWADfixture' > "$tmp/doom.wad"
printf 'one' > "$tmp/source/one.pk3"
printf 'two' > "$tmp/source/two.pk3"
sha_one=$(sha256sum "$tmp/source/one.pk3" | cut -d' ' -f1)
sha_two=$(sha256sum "$tmp/source/two.pk3" | cut -d' ' -f1)
cat > "$tmp/manifest.json" <<JSON
{
  "schema": 1,
  "name": "launch fixture",
  "version": "0.1.0",
  "load_order": [
    {"id":"one","display_name":"One","source_names":["one.pk3"],"source_sha256":["$sha_one"],"runtime_name":"01-one.pk3","transform":{"type":"copy"},"distribution":"test","required":true},
    {"id":"two","display_name":"Two","source_names":["two.pk3"],"source_sha256":["$sha_two"],"runtime_name":"02-two.pk3","transform":{"type":"copy"},"distribution":"test","required":true}
  ]
}
JSON
cat > "$tmp/version.json" <<'JSON'
{"version":"0.2.0","bundle_version":"0.3.0","wadpack_contract":99,"wadpack_entries":2,"bundle_contract":1,"bundle_name":"sol.pk3"}
JSON
printf '# credits\n' > "$tmp/credits.md"
printf 'runtime\n' > "$tmp/runtime.pk3"
printf 'content\n' > "$tmp/content.pk3"

python3 "$root/tools/sol-wadpack.py" \
  --manifest "$tmp/manifest.json" --vend "$tmp/vend" \
  import --scan "$tmp/source" >/dev/null
python3 "$root/tools/sol-bundle.py" build \
  --manifest "$tmp/manifest.json" --version-file "$tmp/version.json" \
  --vend "$tmp/vend" --runtime "$tmp/runtime.pk3" --content "$tmp/content.pk3" \
  --credits "$tmp/credits.md" --output "$tmp/sol.pk3" >/dev/null

cat > "$tmp/sol.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_EDITOR='$tmp/bin/editor'
export SOL_ENGINE='$native_engine'
export DOOM_IWAD='$tmp/doom.wad'
ENV

common_env=(
  SOL_ENV_FILE="$tmp/sol.env"
  SOL_BUNDLE="$tmp/sol.pk3"
  SOL_BUNDLE_REUSE=1
  SOL_WADPACK_MANIFEST="$tmp/manifest.json"
  SOL_VERSION_FILE="$tmp/version.json"
)

output=$(env "${common_env[@]}" bash "$root/tools/sol-test-main.sh" E1M1)
printf '%s\n' "$output" > "$tmp/play-args"
grep -Fx -- '-iwad' "$tmp/play-args"
grep -Fx "$tmp/doom.wad" "$tmp/play-args"
! grep -Fx -- '-file' "$tmp/play-args"
! grep -Fx "$tmp/sol.pk3" "$tmp/play-args"
grep -Fx '+map' "$tmp/play-args"
grep -Fx 'E1M1' "$tmp/play-args"
! grep -E '/01-one\.pk3$|/02-two\.pk3$|/runtime\.pk3$|/content\.pk3$' "$tmp/play-args"
test -f "$tmp/bin/sol.pk3"
cmp "$tmp/sol.pk3" "$tmp/bin/sol.pk3"

wrapper_output=$(env "${common_env[@]}" \
  bash "$root/tools/sol-editor-engine.sh" -file "$tmp/editor-map.wad" +map E1M1)
printf '%s\n' "$wrapper_output" > "$tmp/editor-args"
map_line=$(grep -nFx "$tmp/editor-map.wad" "$tmp/editor-args" | cut -d: -f1)
test -n "$map_line"
! grep -Fx -- '-file' "$tmp/editor-args"
! grep -Fx "$tmp/sol.pk3" "$tmp/editor-args"
! grep -E '/01-one\.pk3$|/02-two\.pk3$|/runtime\.pk3$|/content\.pk3$' "$tmp/editor-args"

cat > "$tmp/legacy.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_EDITOR='$tmp/bin/editor'
export SOL_ENGINE='$tmp/bin/uzdoom'
export DOOM_IWAD='$tmp/doom.wad'
ENV
legacy_env=(
  SOL_ENV_FILE="$tmp/legacy.env"
  SOL_BUNDLE="$tmp/sol.pk3"
  SOL_BUNDLE_REUSE=1
  SOL_WADPACK_MANIFEST="$tmp/manifest.json"
  SOL_VERSION_FILE="$tmp/version.json"
)

legacy_output=$(env "${legacy_env[@]}" bash "$root/tools/sol-test-main.sh" E1M1)
printf '%s\n' "$legacy_output" > "$tmp/legacy-play-args"
bundle_line=$(grep -nFx "$tmp/sol.pk3" "$tmp/legacy-play-args" | cut -d: -f1)
map_line=$(grep -nFx '+map' "$tmp/legacy-play-args" | cut -d: -f1)
grep -Fx -- '-file' "$tmp/legacy-play-args"
test -n "$bundle_line"
test -n "$map_line"
test "$bundle_line" -lt "$map_line"

legacy_editor_output=$(env "${legacy_env[@]}" \
  bash "$root/tools/sol-editor-engine.sh" -file "$tmp/editor-map.wad" +map E1M1)
printf '%s\n' "$legacy_editor_output" > "$tmp/legacy-editor-args"
bundle_line=$(grep -nFx "$tmp/sol.pk3" "$tmp/legacy-editor-args" | cut -d: -f1)
map_line=$(grep -nFx "$tmp/editor-map.wad" "$tmp/legacy-editor-args" | cut -d: -f1)
test -n "$bundle_line"
test -n "$map_line"
test "$bundle_line" -lt "$map_line"

python3 - "$tmp/sol.pk3" <<'PY'
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as zf:
    data = json.loads(zf.read('SOLPACK.json'))
    assert data['native_embedding'] == 'uzdoom-root-wad-carriers'
    assert [c['archive'] for c in data['components']] == [
        '01-one.wad', '02-two.wad', '03-sol-runtime.wad', '04-sol-content.wad'
    ]
PY

printf 'native sidecar launch integration tests passed\n'

#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/engine/tools" "$tmp/source" "$tmp/vend" "$tmp/bin"

cat > "$tmp/bin/engine" <<'ENGINE'
#!/usr/bin/env bash
printf '%s\n' "$@"
ENGINE
chmod +x "$tmp/bin/engine"

cat > "$tmp/bin/editor" <<'EDITOR'
#!/usr/bin/env bash
exit 0
EDITOR
chmod +x "$tmp/bin/editor"

cat > "$tmp/engine/tools/sol-package.sh" <<'PACKAGE'
#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/build/sol"
printf 'fresh-runtime\n' > "$root/build/sol/sol-v0.1.0-dev.pk3"
printf '%s\n' "$root/build/sol/sol-v0.1.0-dev.pk3"
PACKAGE
chmod +x "$tmp/engine/tools/sol-package.sh"

printf 'IWADfixture' > "$tmp/doom.wad"
printf 'one' > "$tmp/source/one.pk3"
printf 'two' > "$tmp/source/two.pk3"
sha_one=$(sha256sum "$tmp/source/one.pk3" | cut -d' ' -f1)
sha_two=$(sha256sum "$tmp/source/two.pk3" | cut -d' ' -f1)
cat > "$tmp/manifest.json" <<JSON
{
  "schema": 1,
  "name": "launch fixture",
  "version": "1",
  "load_order": [
    {"id":"one","display_name":"One","source_names":["one.pk3"],"source_sha256":["$sha_one"],"runtime_name":"01-one.pk3","transform":{"type":"copy"},"distribution":"test","required":true},
    {"id":"two","display_name":"Two","source_names":["two.pk3"],"source_sha256":["$sha_two"],"runtime_name":"02-two.pk3","transform":{"type":"copy"},"distribution":"test","required":true}
  ]
}
JSON
python3 "$root/tools/sol-wadpack.py" \
  --manifest "$tmp/manifest.json" --vend "$tmp/vend" \
  import --scan "$tmp/source" >/dev/null

printf 'stale-runtime\n' > "$tmp/stale-runtime.pk3"
cat > "$tmp/sol.env" <<ENV
export SOL_WORKSPACE='$tmp'
export SOL_EDITOR_ROOT='$root'
export SOL_EDITOR='$tmp/bin/editor'
export SOL_ENGINE_ROOT='$tmp/engine'
export SOL_ENGINE='$tmp/bin/engine'
export SOL_VEND='$tmp/vend'
export SOL_RUNTIME_PKG='$tmp/stale-runtime.pk3'
export DOOM_IWAD='$tmp/doom.wad'
ENV

output=$(SOL_ENV_FILE="$tmp/sol.env" \
  SOL_WADPACK_MANIFEST="$tmp/manifest.json" \
  SOL_SKIP_DOOMTOOLS=1 \
  bash "$root/tools/sol-test-main.sh" E1M1)
printf '%s\n' "$output" > "$tmp/play-args"

grep -Fx -- '-iwad' "$tmp/play-args"
grep -Fx "$tmp/doom.wad" "$tmp/play-args"
one_line=$(grep -nFx "$tmp/vend/wadpack/runtime/01-one.pk3" "$tmp/play-args" | cut -d: -f1)
two_line=$(grep -nFx "$tmp/vend/wadpack/runtime/02-two.pk3" "$tmp/play-args" | cut -d: -f1)
runtime_line=$(grep -nFx "$tmp/engine/build/sol/sol-v0.1.0-dev.pk3" "$tmp/play-args" | cut -d: -f1)
test "$one_line" -lt "$two_line"
test "$two_line" -lt "$runtime_line"
! grep -F "$tmp/stale-runtime.pk3" "$tmp/play-args"

wrapper_output=$(SOL_ENV_FILE="$tmp/sol.env" \
  SOL_WADPACK_MANIFEST="$tmp/manifest.json" \
  bash "$root/tools/sol-editor-engine.sh" -file "$tmp/editor-map.wad" +map E1M1)
printf '%s\n' "$wrapper_output" > "$tmp/editor-args"
grep -Fx "$tmp/vend/wadpack/runtime/01-one.pk3" "$tmp/editor-args"
grep -Fx "$tmp/vend/wadpack/runtime/02-two.pk3" "$tmp/editor-args"
grep -Fx "$tmp/editor-map.wad" "$tmp/editor-args"

printf 'wadpack launch integration tests passed\n'

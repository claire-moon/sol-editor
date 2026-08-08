#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/engine-root" "$tmp/vend/wadpack"

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

cat > "$tmp/manifest.json" <<'JSON'
{
  "schema": 1,
  "name": "launcher fixture",
  "version": "0.2.0",
  "load_order": []
}
JSON
cat > "$tmp/version.json" <<'JSON'
{
  "project": "SOL Editor launcher fixture",
  "version": "0.2.0",
  "wadpack_contract": 99,
  "wadpack_entries": 0,
  "bundle_contract": 1,
  "bundle_name": "sol.pk3"
}
JSON
cat > "$tmp/vend/wadpack/lock.json" <<'JSON'
{
  "schema": 1,
  "files": []
}
JSON
printf '# launcher fixture credits\n' > "$tmp/THIRD_PARTY.md"
printf 'runtime-component\n' > "$tmp/runtime.pk3"
printf 'content-component\n' > "$tmp/content.pk3"
printf 'IWADfixture' > "$tmp/doom.wad"

python3 "$root/tools/sol-bundle.py" build \
    --manifest "$tmp/manifest.json" \
    --version-file "$tmp/version.json" \
    --vend "$tmp/vend" \
    --runtime "$tmp/runtime.pk3" \
    --content "$tmp/content.pk3" \
    --credits "$tmp/THIRD_PARTY.md" \
    --output "$tmp/sol.pk3" \
    >/dev/null

cat > "$tmp/sol.env" <<ENV
export SOL_EDITOR='$tmp/editor'
export SOL_ENGINE='$tmp/engine'
export SOL_ENGINE_ROOT='$tmp/engine-root'
export SOL_VEND_ROOT='$tmp/vend'
export SOL_WADPACK_MANIFEST='$tmp/manifest.json'
export SOL_VERSION_FILE='$tmp/version.json'
export SOL_THIRD_PARTY_FILE='$tmp/THIRD_PARTY.md'
export SOL_BUNDLE='$tmp/sol.pk3'
export SOL_BUNDLE_REUSE='1'
export DOOM_IWAD='$tmp/doom.wad'
ENV

SOL_ENV_FILE="$tmp/sol.env" "$tmp/bin/sol-edit" --fixture | grep -F 'editor --fixture'
play_output=$(SOL_ENV_FILE="$tmp/sol.env" "$tmp/bin/sol-play" E1M1)
printf '%s\n' "$play_output" | grep -F "engine -iwad $tmp/doom.wad -file $tmp/sol.pk3 +map E1M1"

printf 'symlink launcher and native-bundle tests passed\n'

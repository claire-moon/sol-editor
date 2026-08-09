#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/source" "$tmp/vend"

printf 'one-data\n' > "$tmp/source/one.pk3"
printf 'two-data\n' > "$tmp/source/two.wad"
sha_one=$(sha256sum "$tmp/source/one.pk3" | cut -d' ' -f1)
sha_two=$(sha256sum "$tmp/source/two.wad" | cut -d' ' -f1)
cat > "$tmp/manifest.json" <<JSON
{
  "schema": 1,
  "name": "bundle fixture",
  "version": "0.1.0",
  "load_order": [
    {"id":"one","display_name":"One","source_names":["one.pk3"],"source_sha256":["$sha_one"],"runtime_name":"01-one.pk3","transform":{"type":"copy"},"distribution":"test","required":true},
    {"id":"two","display_name":"Two","source_names":["two.wad"],"source_sha256":["$sha_two"],"runtime_name":"02-two.wad","transform":{"type":"copy"},"distribution":"test","required":true}
  ]
}
JSON
cat > "$tmp/version.json" <<'JSON'
{
  "project": "SOL Editor",
  "version": "0.1.0",
  "bundle_version": "0.3.0",
  "wadpack_contract": 99,
  "wadpack_entries": 2,
  "bundle_contract": 1,
  "bundle_name": "sol.pk3"
}
JSON
printf '# Fixture credits\n' > "$tmp/THIRD_PARTY.md"
printf 'runtime-component\n' > "$tmp/runtime.pk3"
printf 'content-component\n' > "$tmp/content.pk3"

python3 "$root/tools/sol-wadpack.py" \
    --manifest "$tmp/manifest.json" --vend "$tmp/vend" \
    import --scan "$tmp/source" >/dev/null

build_bundle() {
    python3 "$root/tools/sol-bundle.py" build \
        --manifest "$tmp/manifest.json" \
        --version-file "$tmp/version.json" \
        --vend "$tmp/vend" \
        --runtime "$tmp/runtime.pk3" \
        --content "$tmp/content.pk3" \
        --credits "$tmp/THIRD_PARTY.md" \
        --output "$tmp/sol.pk3" >/dev/null
}

build_bundle
python3 "$root/tools/sol-bundle.py" verify \
    --bundle "$tmp/sol.pk3" \
    --manifest "$tmp/manifest.json" \
    --version-file "$tmp/version.json" \
    --runtime "$tmp/runtime.pk3" \
    --content "$tmp/content.pk3" \
    --credits "$tmp/THIRD_PARTY.md" >/dev/null

first_hash=$(sha256sum "$tmp/sol.pk3" | cut -d' ' -f1)
build_bundle
second_hash=$(sha256sum "$tmp/sol.pk3" | cut -d' ' -f1)
test "$first_hash" = "$second_hash"

mapfile -t wadpack_paths < <(python3 "$root/tools/sol-bundle.py" materialize \
    --bundle "$tmp/sol.pk3" --directory "$tmp/cache" --scope wadpack \
    --manifest "$tmp/manifest.json" --version-file "$tmp/version.json")
test ${#wadpack_paths[@]} -eq 2
[[ ${wadpack_paths[0]} == */01-one.pk3 ]]
[[ ${wadpack_paths[1]} == */02-two.wad ]]
cmp "$tmp/source/one.pk3" "${wadpack_paths[0]}"
cmp "$tmp/source/two.wad" "${wadpack_paths[1]}"

mapfile -t engine_paths < <(python3 "$root/tools/sol-bundle.py" materialize \
    --bundle "$tmp/sol.pk3" --directory "$tmp/cache" --scope engine \
    --manifest "$tmp/manifest.json" --version-file "$tmp/version.json")
test ${#engine_paths[@]} -eq 3
[[ ${engine_paths[2]} == */runtime.pk3 ]]
cmp "$tmp/runtime.pk3" "${engine_paths[2]}"

mapfile -t all_paths < <(python3 "$root/tools/sol-bundle.py" materialize \
    --bundle "$tmp/sol.pk3" --directory "$tmp/cache" --scope all \
    --manifest "$tmp/manifest.json" --version-file "$tmp/version.json")
test ${#all_paths[@]} -eq 4
[[ ${all_paths[3]} == */content.pk3 ]]
cmp "$tmp/content.pk3" "${all_paths[3]}"

python3 - "$tmp/sol.pk3" <<'PY'
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as zf:
    data = json.loads(zf.read('SOLPACK.json'))
    assert data['version'] == '0.3.0'
    assert data['bundle_contract'] == 1
    assert data['native_embedding'] == 'uzdoom-root-wad-carriers'
    assert data['wadpack_contract'] == 99
    assert data['wadpack_entries'] == 2
    assert [c['kind'] for c in data['components']] == ['wadpack', 'wadpack', 'runtime', 'content']
    assert [c['archive'] for c in data['components']] == [
        '01-one.wad', '02-two.wad', '03-sol-runtime.wad', '04-sol-content.wad'
    ]
    assert [c['runtime_name'] for c in data['components']] == [
        '01-one.pk3', '02-two.wad', 'runtime.pk3', 'content.pk3'
    ]
    for member in data['components']:
        assert '/' not in member['archive']
        assert member['archive'].endswith('.wad')
    assert zf.read('THIRD_PARTY.md') == b'# Fixture credits\n'
PY

printf 'changed-runtime\n' >> "$tmp/runtime.pk3"
if python3 "$root/tools/sol-bundle.py" verify \
    --bundle "$tmp/sol.pk3" \
    --manifest "$tmp/manifest.json" \
    --version-file "$tmp/version.json" \
    --runtime "$tmp/runtime.pk3" >/dev/null 2>&1; then
    printf 'stale runtime component passed SOL bundle freshness validation\n' >&2
    exit 1
fi
printf 'runtime-component\n' > "$tmp/runtime.pk3"
printf 'changed credits\n' >> "$tmp/THIRD_PARTY.md"
if python3 "$root/tools/sol-bundle.py" verify \
    --bundle "$tmp/sol.pk3" \
    --manifest "$tmp/manifest.json" \
    --version-file "$tmp/version.json" \
    --credits "$tmp/THIRD_PARTY.md" >/dev/null 2>&1; then
    printf 'stale attribution passed SOL bundle freshness validation\n' >&2
    exit 1
fi

printf 'not a zip\n' > "$tmp/bad.pk3"
if python3 "$root/tools/sol-bundle.py" verify --bundle "$tmp/bad.pk3" >/dev/null 2>&1; then
    printf 'invalid SOL bundle passed verification\n' >&2
    exit 1
fi

printf 'SOL native embedded bundle tests passed\n'

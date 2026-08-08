#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/source" "$tmp/vend" "$tmp/engine/tools" "$tmp/engine/bin" "$tmp/editor/bin"

printf 'one-data\n' > "$tmp/source/one.pk3"
printf 'two-data\n' > "$tmp/source/two.wad"
sha_one=$(sha256sum "$tmp/source/one.pk3" | cut -d' ' -f1)
sha_two=$(sha256sum "$tmp/source/two.wad" | cut -d' ' -f1)
cat > "$tmp/manifest.json" <<JSON
{
  "schema": 1,
  "name": "package fixture",
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
  "wadpack_contract": 99,
  "wadpack_entries": 2,
  "bundle_contract": 1,
  "bundle_name": "sol.pk3"
}
JSON
printf '# Package fixture credits\n' > "$tmp/THIRD_PARTY.md"
printf 'runtime-component\n' > "$tmp/runtime.pk3"
printf 'content-component\n' > "$tmp/content.pk3"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/engine/bin/uzdoom"
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/editor/bin/builder"
chmod +x "$tmp/engine/bin/uzdoom" "$tmp/editor/bin/builder"
printf '# placeholder\n' > "$tmp/engine/tools/sol-runtime-package.sh"

python3 "$root/tools/sol-wadpack.py" \
    --manifest "$tmp/manifest.json" --vend "$tmp/vend" \
    import --scan "$tmp/source" >/dev/null

bundle=$(env \
    SOL_WORKSPACE="$tmp" \
    SOL_ENGINE_ROOT="$tmp/engine" \
    SOL_VEND_ROOT="$tmp/vend" \
    SOL_WADPACK_MANIFEST="$tmp/manifest.json" \
    SOL_VERSION_FILE="$tmp/version.json" \
    SOL_THIRD_PARTY_FILE="$tmp/THIRD_PARTY.md" \
    SOL_BUNDLE="$tmp/output/sol.pk3" \
    SOL_RUNTIME_COMPONENT="$tmp/runtime.pk3" \
    SOL_CONTENT_COMPONENT="$tmp/content.pk3" \
    SOL_ENGINE="$tmp/engine/bin/uzdoom" \
    SOL_EDITOR="$tmp/editor/bin/builder" \
    bash "$root/tools/sol-bundle.sh")

test "$bundle" = "$tmp/output/sol.pk3"
test -f "$bundle"
for copy in \
    "$tmp/engine/build/sol/sol.pk3" \
    "$tmp/engine/bin/sol.pk3" \
    "$tmp/editor/bin/sol.pk3"; do
    test -f "$copy"
    cmp "$bundle" "$copy"
done

python3 "$root/tools/sol-bundle.py" verify \
    --bundle "$bundle" --manifest "$tmp/manifest.json" \
    --version-file "$tmp/version.json" \
    --runtime "$tmp/runtime.pk3" --content "$tmp/content.pk3" \
    --credits "$tmp/THIRD_PARTY.md" >/dev/null

python3 - "$bundle" <<'PY'
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as zf:
    data = json.loads(zf.read('SOLPACK.json'))
    assert data['native_embedding'] == 'uzdoom-root-wad-carriers'
    assert [c['archive'] for c in data['components']] == [
        '01-one.wad', '02-two.wad', '03-sol-runtime.wad', '04-sol-content.wad'
    ]
PY

# Prove vend is a build input rather than a packaged-runtime dependency.
rm -rf "$tmp/vend"
reused=$(env \
    SOL_WORKSPACE="$tmp" \
    SOL_ENGINE_ROOT="$tmp/engine" \
    SOL_VEND_ROOT="$tmp/vend" \
    SOL_WADPACK_MANIFEST="$tmp/manifest.json" \
    SOL_VERSION_FILE="$tmp/version.json" \
    SOL_THIRD_PARTY_FILE="$tmp/THIRD_PARTY.md" \
    SOL_BUNDLE="$bundle" \
    SOL_ENGINE="$tmp/engine/bin/uzdoom" \
    SOL_EDITOR="$tmp/editor/bin/builder" \
    bash "$root/tools/sol-bundle.sh")
test "$reused" = "$bundle"

# Materialization remains available for editor authoring, but gameplay can pass
# only sol.pk3 because UZDoom recursively mounts the root-level *.wad carriers.
mapfile -t paths < <(python3 "$root/tools/sol-bundle.py" materialize \
    --bundle "$bundle" --directory "$tmp/materialized" --scope all \
    --manifest "$tmp/manifest.json" --version-file "$tmp/version.json")
test ${#paths[@]} -eq 4
[[ ${paths[0]} == */01-one.pk3 ]]
[[ ${paths[1]} == */02-two.wad ]]
[[ ${paths[2]} == */runtime.pk3 ]]
[[ ${paths[3]} == */content.pk3 ]]

printf 'self-contained native SOL package deployment tests passed\n'

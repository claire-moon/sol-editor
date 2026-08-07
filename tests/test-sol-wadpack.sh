#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
script="$root/tools/sol-wadpack.py"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/source/root/mod" "$tmp/bin"
printf 'copy-data' > "$tmp/source/direct.pk3"
printf 'inner-data' > "$tmp/member.pk3"
(cd "$tmp" && zip -q "$tmp/source/member.zip" member.pk3)
printf 'zscript' > "$tmp/source/root/mod/zscript.txt"
printf 'license' > "$tmp/source/root/mod/LICENSE"
(cd "$tmp/source/root" && zip -qr "$tmp/source/root.zip" mod)
printf 'seven-data' > "$tmp/seven.pk3"
printf 'seven-container' > "$tmp/source/seven.7z"
cat > "$tmp/bin/7z" <<'FAKE7Z'
#!/usr/bin/env bash
set -euo pipefail
if [[ $1 == l ]]; then
  printf 'Path = archive.7z\nPath = flashlight.pk3\n'
elif [[ $1 == e && $2 == -so ]]; then
  cat "$FAKE_7Z_PAYLOAD"
else
  exit 2
fi
FAKE7Z
chmod +x "$tmp/bin/7z"
sha_direct=$(sha256sum "$tmp/source/direct.pk3" | cut -d' ' -f1)
sha_member=$(sha256sum "$tmp/source/member.zip" | cut -d' ' -f1)
sha_root=$(sha256sum "$tmp/source/root.zip" | cut -d' ' -f1)
sha_seven=$(sha256sum "$tmp/source/seven.7z" | cut -d' ' -f1)
cat > "$tmp/manifest.json" <<JSON
{
  "schema": 1,
  "name": "fixture",
  "version": "1",
  "load_order": [
    {"id":"direct","display_name":"Direct","source_names":["direct.pk3"],"source_sha256":["$sha_direct"],"runtime_name":"01-direct.pk3","transform":{"type":"copy"},"distribution":"test","required":true},
    {"id":"root","display_name":"Root","source_names":["root.zip"],"source_sha256":["$sha_root"],"runtime_name":"02-root.pk3","transform":{"type":"zip_strip_single_root"},"distribution":"test","required":true},
    {"id":"member","display_name":"Member","source_names":["member.zip"],"source_sha256":["$sha_member"],"runtime_name":"03-member.pk3","transform":{"type":"zip_member","member_suffix":"member.pk3"},"distribution":"test","required":true},
    {"id":"seven","display_name":"Seven","source_names":["seven.7z"],"source_sha256":["$sha_seven"],"runtime_name":"04-seven.pk3","transform":{"type":"sevenzip_member_or_direct","member_suffix":"flashlight.pk3"},"distribution":"test","required":true}
  ]
}
JSON
PATH="$tmp/bin:$PATH" FAKE_7Z_PAYLOAD="$tmp/seven.pk3" \
  python3 "$script" --manifest "$tmp/manifest.json" --vend "$tmp/vend" import --scan "$tmp/source"
python3 "$script" --manifest "$tmp/manifest.json" --vend "$tmp/vend" verify
mapfile -t paths < <(python3 "$script" --manifest "$tmp/manifest.json" --vend "$tmp/vend" paths)
test ${#paths[@]} -eq 4
[[ ${paths[0]} == */01-direct.pk3 ]]
[[ ${paths[3]} == */04-seven.pk3 ]]
unzip -Z1 "$tmp/vend/wadpack/runtime/02-root.pk3" | grep -qx 'zscript.txt'
cmp "$tmp/member.pk3" "$tmp/vend/wadpack/runtime/03-member.pk3"
cmp "$tmp/seven.pk3" "$tmp/vend/wadpack/runtime/04-seven.pk3"
stat -c '%a' "$tmp/vend/wadpack/runtime/01-direct.pk3" | grep -qx 644

printf 'tampered\n' >> "$tmp/vend/wadpack/runtime/01-direct.pk3"
if python3 "$script" --manifest "$tmp/manifest.json" --vend "$tmp/vend" verify >/dev/null 2>&1; then
    printf 'tampered wadpack passed verification\n' >&2
    exit 1
fi

printf 'wadpack tests passed\n'

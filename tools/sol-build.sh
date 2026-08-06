#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$root/sol/version.json")
build_dir="$root/build/sol"
generated_dir="$build_dir/generated/e1m1"
stage_dir="$build_dir/stage"
archive="$build_dir/sol-e1m1-v${version}.pk3"

rm -rf "$generated_dir" "$stage_dir"
mkdir -p "$generated_dir" "$stage_dir/maps"
python3 "$root/tools/sol-generate-e1m1.py" --output "$generated_dir" >/dev/null
python3 "$root/tools/sol-validate-e1m1.py" --directory "$generated_dir" >/dev/null
cmp "$generated_dir/stats.json" "$root/sol-project/maps/e1m1/stats.json"
cmp "$generated_dir/layout.svg" "$root/sol-project/maps/e1m1/layout.svg"

cp -a "$root/sol-project/src/." "$stage_dir/"
cp "$generated_dir/E1M1.wad" "$stage_dir/maps/E1M1.wad"
rm -f "$archive"
(
  cd "$stage_dir"
  find . -type f -print0 | sort -z | xargs -0 touch -d '@0'
  find . -type f -print | LC_ALL=C sort | zip -X -q "$archive" -@
)
printf '%s\n' "$archive"

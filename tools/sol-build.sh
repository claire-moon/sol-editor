#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
project_file="$root/sol-project/project.json"
source_dir="$root/sol-project/src"
out_dir="$root/build/sol"

for command in python3 zip; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command" >&2
        exit 1
    fi
done

python3 -m json.tool "$project_file" >/dev/null

if [[ ${SOL_SKIP_DOOMTOOLS:-0} != 1 ]]; then
    bash "$root/tools/sol-doommake.sh" --version >/dev/null
fi

version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])' "$project_file")
archive="$out_dir/sol-e1m1-v${version}.pk3"

if [[ ! -d $source_dir ]]; then
    printf 'Missing SOL project source directory: %s\n' "$source_dir" >&2
    exit 1
fi

mkdir -p "$out_dir"
rm -f "$archive"

(
    cd "$source_dir"
    find . -type f -print0 \
        | LC_ALL=C sort -z \
        | xargs -0 zip -X -q "$archive"
)

printf '%s\n' "$archive"

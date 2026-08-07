#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=$(cd "$root/.." && pwd)
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
vend_root=${SOL_VEND:-"$workspace/vend"}
mod_root=${SOL_MOD_ROOT:-"$vend_root/sol-mods"}
source_dir=${1:-}

resolver="$engine_root/tools/sol-mod-stack.sh"
manifest="$engine_root/sol/mods/stack.txt"
if [[ ! -x $resolver || ! -f $manifest ]]; then
    printf 'Sibling sol-engine fixed mod contract not found under %s\n' "$engine_root" >&2
    exit 1
fi
mkdir -p "$mod_root"

if [[ -n $source_dir ]]; then
    source_dir=$(realpath "$source_dir")
    if [[ ! -d $source_dir ]]; then
        printf 'SOL mod source directory not found: %s\n' "$source_dir" >&2
        exit 1
    fi
    while IFS= read -r entry || [[ -n $entry ]]; do
        entry=${entry%$'\r'}
        [[ -z $entry || $entry == \#* ]] && continue
        if [[ ! -f $source_dir/$entry ]]; then
            printf 'Missing required source archive: %s\n' "$source_dir/$entry" >&2
            exit 1
        fi
        cp -f "$source_dir/$entry" "$mod_root/$entry"
    done < "$manifest"
fi

SOL_MOD_ROOT="$mod_root" bash "$resolver" --check
checksum_file="$vend_root/SOL-MODS.sha256"
: > "$checksum_file"
while IFS= read -r entry || [[ -n $entry ]]; do
    entry=${entry%$'\r'}
    [[ -z $entry || $entry == \#* ]] && continue
    sha256sum "$mod_root/$entry" >> "$checksum_file"
done < "$manifest"

printf 'SOL mod root: %s\n' "$(realpath "$mod_root")"
printf 'Checksums: %s\n' "$checksum_file"

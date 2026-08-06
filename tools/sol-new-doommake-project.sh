#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
target=${1:-"$root/sol-project/doommake-workspace"}

if [[ -e $target ]]; then
    printf 'Target already exists: %s\n' "$target" >&2
    exit 1
fi

exec "$root/tools/sol-doommake.sh" "$target" --new-project maps run git

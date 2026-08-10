#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
bundler="$engine_root/tools/sol-bundle.sh"

if [[ ! -f $bundler ]]; then
    printf 'SOL Engine v0.4 bundler not found: %s\n' "$bundler" >&2
    exit 1
fi

export SOL_EDITOR_ROOT="$root"
export SOL_ENGINE_ROOT="$engine_root"
exec bash "$bundler" "$@"

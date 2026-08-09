#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
setup="$engine_root/tools/sol-wadpack-setup.sh"

if [[ ! -f $setup ]]; then
    printf 'SOL Engine v0.4 wadpack setup not found: %s\n' "$setup" >&2
    exit 1
fi

export SOL_EDITOR_ROOT="$root"
export SOL_ENGINE_ROOT="$engine_root"
exec bash "$setup" "$@"

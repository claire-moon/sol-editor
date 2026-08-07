#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file=${SOL_ENV_FILE:-"$root/.sol-env"}

if [[ ! -f $env_file ]]; then
    bash "$root/tools/sol-cockpit.sh" --setup-only
fi
set -a
# shellcheck disable=SC1090
source "$env_file"
set +a

workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
vend_root=${SOL_VEND:-${SOL_VEND_ROOT:-"$workspace/vend"}}
manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
wadpack_tool=(python3 "$root/tools/sol-wadpack.py" --manifest "$manifest" --vend "$vend_root")
mkdir -p "$root/sol-project/.udb"
if [[ ${SOL_SKIP_WADPACK:-0} != 1 ]]; then
    if ! "${wadpack_tool[@]}" verify >/dev/null; then
        bash "$root/tools/sol-wadpack-setup.sh"
    fi
    "${wadpack_tool[@]}" paths > "$root/sol-project/.udb/sol-wadpack.resources.txt"
else
    : > "$root/sol-project/.udb/sol-wadpack.resources.txt"
fi

export SOL_WADPACK_MANIFEST="$manifest"
export SOL_WADPACK_ROOT="$vend_root/wadpack"
export SOL_WADPACK_LOAD_ORDER="$vend_root/wadpack/load-order.txt"
export SOL_EDITOR_TEST_ENGINE="$root/tools/sol-editor-engine.sh"

if [[ ! -x ${SOL_EDITOR:-} ]]; then
    bash "$root/tools/sol-cockpit.sh" --setup-only
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
fi
exec "$SOL_EDITOR" "$@"

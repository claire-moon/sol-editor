#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ -f $root/.sol-env ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$root/.sol-env"
    set +a
fi

map_name=${1:-E1M1}
if [[ $# -gt 0 ]]; then
    shift
fi

content_package=$(bash "$root/tools/sol-build.sh")

if [[ -z ${SOL_ENGINE:-} ]]; then
    printf 'SOL_ENGINE is not configured. Run tools/sol-init-workspace.sh first.\n' >&2
    exit 1
fi
if [[ ! -x $SOL_ENGINE ]]; then
    printf 'SOL_ENGINE is not executable: %s\n' "$SOL_ENGINE" >&2
    exit 1
fi
if [[ -z ${SOL_ENGINE_ROOT:-} || ! -x $SOL_ENGINE_ROOT/tools/sol-mod-stack.sh ]]; then
    printf 'SOL_ENGINE_ROOT does not provide the SOL mod resolver. Reinitialize the workspace.\n' >&2
    exit 1
fi
if [[ -z ${SOL_RUNTIME_PKG:-} || ! -f $SOL_RUNTIME_PKG ]]; then
    printf 'SOL_RUNTIME_PKG is not configured or missing. Reinitialize the workspace.\n' >&2
    exit 1
fi

bash "$SOL_ENGINE_ROOT/tools/sol-mod-stack.sh" --check >/dev/null
mapfile -d '' -t mod_files < <(bash "$SOL_ENGINE_ROOT/tools/sol-mod-stack.sh" --print0)
packages=("${mod_files[@]}" "$SOL_RUNTIME_PKG" "$content_package")
args=(-file "${packages[@]}")
if [[ -n ${DOOM_IWAD:-} ]]; then
    if [[ ! -f $DOOM_IWAD ]]; then
        printf 'DOOM_IWAD does not exist: %s\n' "$DOOM_IWAD" >&2
        exit 1
    fi
    args=(-iwad "$DOOM_IWAD" "${args[@]}")
fi

exec "$SOL_ENGINE" "${args[@]}" +map "$map_name" "$@"

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
engine=$SOL_ENGINE
if [[ ! -x $engine ]]; then
    printf 'SOL_ENGINE is not executable: %s\n' "$engine" >&2
    exit 1
fi

packages=()
if [[ -n ${SOL_RUNTIME_PKG:-} ]]; then
    if [[ ! -f $SOL_RUNTIME_PKG ]]; then
        printf 'SOL_RUNTIME_PKG does not exist: %s\n' "$SOL_RUNTIME_PKG" >&2
        exit 1
    fi
    packages+=("$SOL_RUNTIME_PKG")
fi
packages+=("$content_package")

args=(-file "${packages[@]}")
if [[ -n ${DOOM_IWAD:-} ]]; then
    if [[ ! -f $DOOM_IWAD ]]; then
        printf 'DOOM_IWAD does not exist: %s\n' "$DOOM_IWAD" >&2
        exit 1
    fi
    args=(-iwad "$DOOM_IWAD" "${args[@]}")
fi

exec "$engine" "${args[@]}" +map "$map_name" "$@"

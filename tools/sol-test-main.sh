#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file=${SOL_ENV_FILE:-"$root/.sol-env"}

load_env() {
    [[ -f $env_file ]] || return 1
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
}

needs_setup=0
if ! load_env; then
    needs_setup=1
else
    [[ -x ${SOL_ENGINE:-} ]] || needs_setup=1
    [[ -f ${DOOM_IWAD:-} ]] || needs_setup=1
fi

if ((needs_setup)); then
    if [[ -t 0 && -t 1 || ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]; then
        bash "$root/tools/sol-cockpit.sh" --setup-only
        load_env
    else
        printf 'SOL is not configured. Run tools/sol-cockpit.sh.\n' >&2
        exit 1
    fi
fi

workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
manifest=${SOL_WADPACK_MANIFEST:-"$engine_root/sol/wadpack.json"}
version_file=${SOL_VERSION_FILE:-"$engine_root/sol/version.json"}
bundle=${SOL_BUNDLE:-"$engine_root/build/sol/sol.pk3"}
bundle_tool=(python3 "$root/tools/sol-bundle.py")

bundle=$(SOL_ENGINE_ROOT="$engine_root" SOL_BUNDLE="$bundle" bash "$root/tools/sol-bundle.sh")
"${bundle_tool[@]}" verify \
    --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
    >/dev/null

map_name=${1:-E1M1}
if [[ $# -gt 0 ]]; then shift; fi

args=(-iwad "$(realpath "$DOOM_IWAD")")
is_native_sol_engine() {
    local name
    for name in "$(basename "$1")" "$(basename "$(realpath "$1")")"; do
        case $name in
            sol-engine|sol-engine.exe|*SOL-Engine*.AppImage) return 0 ;;
        esac
    done
    return 1
}
if ! is_native_sol_engine "$SOL_ENGINE"; then
    args+=(-file "$bundle")
fi
exec "$SOL_ENGINE" "${args[@]}" +map "$map_name" "$@"

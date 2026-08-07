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
    [[ -f ${SOL_ENGINE_ROOT:-}/tools/sol-package.sh ]] || needs_setup=1
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
vend_root=${SOL_VEND:-${SOL_VEND_ROOT:-"$workspace/vend"}}
manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
wadpack_tool=(python3 "$root/tools/sol-wadpack.py" --manifest "$manifest" --vend "$vend_root")

if [[ ${SOL_SKIP_WADPACK:-0} != 1 ]]; then
    if ! "${wadpack_tool[@]}" verify >/dev/null; then
        if [[ -t 0 && -t 1 || ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]; then
            bash "$root/tools/sol-wadpack-setup.sh"
        else
            printf 'SOL wadpack is incomplete. Run tools/sol-wadpack-setup.sh.\n' >&2
            exit 1
        fi
    fi
    mapfile -t wadpack_files < <("${wadpack_tool[@]}" paths)
else
    wadpack_files=()
fi

map_name=${1:-E1M1}
if [[ $# -gt 0 ]]; then shift; fi
runtime_package=$(bash "$SOL_ENGINE_ROOT/tools/sol-package.sh")
if [[ ! -f $runtime_package ]]; then
    printf 'SOL runtime package was not produced: %s\n' "$runtime_package" >&2
    exit 1
fi
content_package=$(bash "$root/tools/sol-build.sh")

# Third-party resources load first in the locked Rocket Launcher order. SOL
# runtime and map content load last so project-owned fixes can override them.
exec "$SOL_ENGINE" \
    -iwad "$DOOM_IWAD" \
    -file "${wadpack_files[@]}" "$runtime_package" "$content_package" \
    +map "$map_name" "$@"

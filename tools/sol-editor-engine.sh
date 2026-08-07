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
runtime_package=$(bash "$SOL_ENGINE_ROOT/tools/sol-package.sh")

has_iwad=0
for argument in "$@"; do
    [[ $argument == -iwad ]] && has_iwad=1
done

args=(-file "${wadpack_files[@]}" "$runtime_package")
if ((has_iwad == 0)); then
    args=(-iwad "$DOOM_IWAD" "${args[@]}")
fi

# UDB's temporary map and resource arguments follow the locked SOL baseline.
exec "$SOL_ENGINE" "${args[@]}" "$@"

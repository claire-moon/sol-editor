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

manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
version_file=${SOL_VERSION_FILE:-"$root/sol/version.json"}
bundle=${SOL_BUNDLE:-"$root/build/sol/sol.pk3"}
cache=${SOL_BUNDLE_CACHE:-"$root/build/sol/materialized"}
bundle_tool=(python3 "$root/tools/sol-bundle.py")

if ! "${bundle_tool[@]}" verify \
    --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
    >/dev/null 2>&1; then
    bundle=$(SOL_BUNDLE="$bundle" bash "$root/tools/sol-bundle.sh")
fi
"${bundle_tool[@]}" verify \
    --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
    >/dev/null
mapfile -t bundle_files < <("${bundle_tool[@]}" materialize \
    --bundle "$bundle" --directory "$cache" --scope all \
    --manifest "$manifest" --version-file "$version_file")

map_name=${1:-E1M1}
if [[ $# -gt 0 ]]; then shift; fi

# sol.pk3 is the physical runtime payload. Its intact embedded archives are
# materialized and mounted in locked order so duplicate root resources in
# third-party mods cannot overwrite one another during bundle construction.
exec "$SOL_ENGINE" \
    -iwad "$DOOM_IWAD" \
    -file "${bundle_files[@]}" \
    +map "$map_name" "$@"

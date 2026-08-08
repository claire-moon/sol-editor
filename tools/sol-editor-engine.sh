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

manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
version_file=${SOL_VERSION_FILE:-"$root/sol/version.json"}
bundle=${SOL_BUNDLE:-"$root/build/sol/sol.pk3"}
cache=${SOL_BUNDLE_CACHE:-"$root/build/sol/materialized"}
bundle_tool=(python3 "$root/tools/sol-bundle.py")

bundle=$(SOL_BUNDLE="$bundle" bash "$root/tools/sol-bundle.sh")
mapfile -t engine_files < <("${bundle_tool[@]}" materialize \
    --bundle "$bundle" --directory "$cache" --scope engine \
    --manifest "$manifest" --version-file "$version_file")

has_iwad=0
for argument in "$@"; do
    [[ $argument == -iwad ]] && has_iwad=1
done

args=(-file "${engine_files[@]}")
if ((has_iwad == 0)); then
    args=(-iwad "$DOOM_IWAD" "${args[@]}")
fi

# UDB's temporary map/resource arguments follow the eighteen embedded wadpack
# resources and SOL runtime component materialized from sol.pk3. The packaged
# E1M1 content component is intentionally omitted so UDB's temporary map wins.
exec "$SOL_ENGINE" "${args[@]}" "$@"

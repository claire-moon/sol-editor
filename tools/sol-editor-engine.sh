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
bundle_tool=(python3 "$root/tools/sol-bundle.py")

bundle=$(SOL_BUNDLE="$bundle" bash "$root/tools/sol-bundle.sh")
"${bundle_tool[@]}" verify \
    --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
    >/dev/null

has_iwad=0
for argument in "$@"; do
    [[ $argument == -iwad ]] && has_iwad=1
done

args=(-file "$bundle")
if ((has_iwad == 0)); then
    args=(-iwad "$DOOM_IWAD" "${args[@]}")
fi

# UZDoom recursively mounts sol.pk3's numbered native embedded carriers. UDB's
# temporary map/resource arguments follow the bundle and therefore retain final
# test-map precedence without duplicating the eighteen authoring resources.
exec "$SOL_ENGINE" "${args[@]}" "$@"

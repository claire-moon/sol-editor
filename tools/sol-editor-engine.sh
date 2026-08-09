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

args=()
if ((has_iwad == 0)); then
    args=(-iwad "$(realpath "$DOOM_IWAD")")
fi

# Native SOL Engine mounts the verified sidecar itself. Keep one compatibility
# path for pre-v0.3 UZDoom binaries; UDB's temporary map arguments always follow
# the canonical bundle and retain final test-map precedence.
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
exec "$SOL_ENGINE" "${args[@]}" "$@"

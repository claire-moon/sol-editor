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
resources_file="$root/sol-project/.udb/sol-wadpack.resources.txt"
mkdir -p "$root/sol-project/.udb"

bundle=$(SOL_BUNDLE="$bundle" bash "$root/tools/sol-bundle.sh")
"${bundle_tool[@]}" materialize \
    --bundle "$bundle" --directory "$cache" --scope wadpack \
    --manifest "$manifest" --version-file "$version_file" \
    > "$resources_file"

export SOL_BUNDLE="$bundle"
export SOL_WADPACK_MANIFEST="$manifest"
export SOL_WADPACK_ROOT="$cache"
export SOL_WADPACK_LOAD_ORDER="$resources_file"
export SOL_EDITOR_TEST_ENGINE="$root/tools/sol-editor-engine.sh"

if [[ ! -x ${SOL_EDITOR:-} ]]; then
    bash "$root/tools/sol-cockpit.sh" --setup-only
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
fi
exec "$SOL_EDITOR" "$@"

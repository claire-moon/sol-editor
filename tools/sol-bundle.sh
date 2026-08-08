#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file=${SOL_ENV_FILE:-"$root/.sol-env"}
if [[ -f $env_file ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
fi

workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
vend_root=${SOL_VEND:-${SOL_VEND_ROOT:-"$workspace/vend"}}
manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
version_file=${SOL_VERSION_FILE:-"$root/sol/version.json"}
credits=${SOL_THIRD_PARTY_FILE:-"$root/THIRD_PARTY.md"}
bundle=${SOL_BUNDLE:-"$root/build/sol/sol.pk3"}
bundle_tool=(python3 "$root/tools/sol-bundle.py")
wadpack_tool=(python3 "$root/tools/sol-wadpack.py" --manifest "$manifest" --vend "$vend_root")

runtime_builder="$engine_root/tools/sol-package.sh"
if [[ -x $engine_root/tools/sol-runtime-package.sh ]]; then
    runtime_builder="$engine_root/tools/sol-runtime-package.sh"
fi

if [[ ! -x $runtime_builder ]]; then
    printf 'SOL engine runtime packager not found: %s\n' "$runtime_builder" >&2
    exit 1
fi

# A valid existing sol.pk3 is a self-contained runtime. This permits installed
# packages to run after their build-time vend directory has been removed.
if [[ -f $bundle && ${SOL_FORCE_BUNDLE_REFRESH:-0} != 1 ]]; then
    if "${bundle_tool[@]}" verify \
        --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
        >/dev/null 2>&1; then
        mkdir -p "$engine_root/build/sol"
        cp -f "$bundle" "$engine_root/build/sol/sol.pk3"
        if [[ -d $engine_root/build/sol-local ]]; then
            cp -f "$bundle" "$engine_root/build/sol-local/sol.pk3"
        fi
        if [[ -d $root/Build ]]; then
            cp -f "$bundle" "$root/Build/sol.pk3"
        fi
        printf '%s\n' "$bundle"
        exit 0
    fi
fi

if ! "${wadpack_tool[@]}" verify >/dev/null 2>&1; then
    if [[ ${SOL_BUNDLE_NO_SETUP:-0} == 1 ]]; then
        printf 'SOL wadpack is incomplete and no valid sol.pk3 exists.\n' >&2
        exit 1
    elif [[ -t 0 && -t 1 || ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]; then
        bash "$root/tools/sol-wadpack-setup.sh"
    else
        printf 'SOL wadpack is incomplete and no valid sol.pk3 exists. Run tools/sol-wadpack-setup.sh.\n' >&2
        exit 1
    fi
fi
"${wadpack_tool[@]}" verify >/dev/null

runtime_package=${SOL_RUNTIME_COMPONENT:-$(bash "$runtime_builder")}
content_package=${SOL_CONTENT_COMPONENT:-$(bash "$root/tools/sol-build.sh")}

"${bundle_tool[@]}" build \
    --manifest "$manifest" \
    --version-file "$version_file" \
    --vend "$vend_root" \
    --runtime "$runtime_package" \
    --content "$content_package" \
    --credits "$credits" \
    --output "$bundle" \
    >/dev/null

mkdir -p "$engine_root/build/sol"
cp -f "$bundle" "$engine_root/build/sol/sol.pk3"
if [[ -d $engine_root/build/sol-local ]]; then
    cp -f "$bundle" "$engine_root/build/sol-local/sol.pk3"
fi
if [[ -d $root/Build ]]; then
    cp -f "$bundle" "$root/Build/sol.pk3"
fi

printf '%s\n' "$bundle"

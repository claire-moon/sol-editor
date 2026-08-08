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

copy_bundle() {
    local destination=$1
    mkdir -p "$(dirname "$destination")"
    if [[ $(realpath -m "$bundle") != $(realpath -m "$destination") ]]; then
        cp -f "$bundle" "$destination"
    fi
}

install_bundle_copies() {
    copy_bundle "$engine_root/build/sol/sol.pk3"
    if [[ -d $engine_root/build/sol-local ]]; then
        copy_bundle "$engine_root/build/sol-local/sol.pk3"
    fi
    if [[ -n ${SOL_ENGINE:-} && -f ${SOL_ENGINE:-} ]]; then
        copy_bundle "$(dirname "$(realpath "$SOL_ENGINE")")/sol.pk3"
    fi
    if [[ -d $root/Build ]]; then
        copy_bundle "$root/Build/sol.pk3"
    fi
    if [[ -n ${SOL_EDITOR:-} && -f ${SOL_EDITOR:-} ]]; then
        copy_bundle "$(dirname "$(realpath "$SOL_EDITOR")")/sol.pk3"
    fi
}

bundle_valid=0
if [[ -f $bundle ]] && "${bundle_tool[@]}" verify \
    --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
    >/dev/null 2>&1; then
    bundle_valid=1
fi

wadpack_ready=0
if "${wadpack_tool[@]}" verify >/dev/null 2>&1; then
    wadpack_ready=1
fi

# Installed packages can explicitly pin a verified bundle without any build-time
# source tree. With no loose wadpack available, a valid bundle is automatically
# treated as the complete self-contained runtime.
if ((bundle_valid)) && [[ ${SOL_BUNDLE_REUSE:-0} == 1 ]]; then
    install_bundle_copies
    printf '%s\n' "$bundle"
    exit 0
fi
if ((wadpack_ready == 0)); then
    if ((bundle_valid)); then
        install_bundle_copies
        printf '%s\n' "$bundle"
        exit 0
    fi
    if [[ ${SOL_BUNDLE_NO_SETUP:-0} == 1 ]]; then
        printf 'SOL wadpack is incomplete and no valid sol.pk3 exists.\n' >&2
        exit 1
    fi
    if [[ -t 0 && -t 1 || ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]; then
        bash "$root/tools/sol-wadpack-setup.sh"
    else
        printf 'SOL wadpack is incomplete and no valid sol.pk3 exists. Run tools/sol-wadpack-setup.sh.\n' >&2
        exit 1
    fi
    "${wadpack_tool[@]}" verify >/dev/null || {
        printf 'SOL wadpack remains incomplete after setup.\n' >&2
        exit 1
    }
fi

runtime_builder="$engine_root/tools/sol-package.sh"
if [[ -f $engine_root/tools/sol-runtime-package.sh ]]; then
    runtime_builder="$engine_root/tools/sol-runtime-package.sh"
fi
if [[ ! -f $runtime_builder ]]; then
    printf 'SOL engine runtime packager not found: %s\n' "$runtime_builder" >&2
    exit 1
fi

# These SOL-owned component packages are small. Rebuilding them lets us compare
# exact hashes with SOLPACK.json and avoids rewriting the much larger sol.pk3
# unless runtime/map/attribution content actually changed.
runtime_package=${SOL_RUNTIME_COMPONENT:-$(bash "$runtime_builder")}
content_package=${SOL_CONTENT_COMPONENT:-$(bash "$root/tools/sol-build.sh")}

if ((bundle_valid)) && [[ ${SOL_FORCE_BUNDLE_REFRESH:-0} != 1 ]]; then
    if "${bundle_tool[@]}" verify \
        --bundle "$bundle" --manifest "$manifest" --version-file "$version_file" \
        --runtime "$runtime_package" --content "$content_package" --credits "$credits" \
        >/dev/null 2>&1; then
        install_bundle_copies
        printf '%s\n' "$bundle"
        exit 0
    fi
fi

"${bundle_tool[@]}" build \
    --manifest "$manifest" \
    --version-file "$version_file" \
    --vend "$vend_root" \
    --runtime "$runtime_package" \
    --content "$content_package" \
    --credits "$credits" \
    --output "$bundle" \
    >/dev/null

install_bundle_copies
printf '%s\n' "$bundle"

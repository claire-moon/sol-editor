#!/usr/bin/env bash
set -euo pipefail

editor_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=${SOL_WORKSPACE:-$(cd "$editor_root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
build_dir=${SOL_ENGINE_BUILD_DIR:-"$engine_root/build/sol-local"}
jobs=${SOL_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')}
detect_only=0
install_deps=0
clean=0

usage() {
    cat <<'USAGE'
Usage: tools/sol-build-engine.sh [--detect] [--install-deps] [--clean]

Build or locate the executable produced by the sibling sol-engine checkout.
When the complete local SOL wadpack is available, also refresh sol.pk3 and copy
it beside the engine executable. The self-contained `sol-engine` launcher is
installed beside the UZDoom binary on every successful local build.
USAGE
}

while (($#)); do
    case $1 in
        --detect) detect_only=1 ;;
        --install-deps) install_deps=1 ;;
        --clean) clean=1 ;;
        --engine-root) engine_root=$2; shift ;;
        --build-dir) build_dir=$2; shift ;;
        --jobs) jobs=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

engine_root=$(realpath -m "$engine_root")
build_dir=$(realpath -m "$build_dir")

find_engine() {
    local candidate
    for candidate in \
        "${SOL_ENGINE:-}" \
        "$build_dir/uzdoom" \
        "$build_dir/Release/uzdoom" \
        "$engine_root/build/uzdoom" \
        "$engine_root/build/Release/uzdoom" \
        "$engine_root/build/Debug/uzdoom" \
        "$engine_root/build/src/uzdoom" \
        "$engine_root/uzdoom"; do
        if [[ -n $candidate && -x $candidate ]]; then
            realpath "$candidate"
            return 0
        fi
    done
    candidate=$(find "$engine_root/build" -maxdepth 4 -type f \
        \( -name uzdoom -o -name 'UZDoom*.AppImage' \) \
        -perm -111 -print -quit 2>/dev/null || true)
    if [[ -n $candidate ]]; then
        realpath "$candidate"
        return 0
    fi
    return 1
}

if ((detect_only)); then
    find_engine
    exit $?
fi

if [[ ! -f $engine_root/CMakeLists.txt ]]; then
    printf 'sol-engine checkout not found: %s\n' "$engine_root" >&2
    exit 1
fi

if ((install_deps)); then
    packages=(
        build-essential cmake ninja-build pkg-config ccache
        libopenal-dev libsdl2-dev libwebp-dev libbz2-dev libvpx-dev
        waylandpp-dev
    )
    if ! command -v apt-get >/dev/null 2>&1; then
        printf 'Automatic dependency installation currently supports apt-based systems only.\n' >&2
        exit 1
    fi
    if ((EUID == 0)); then
        apt-get update
        apt-get install -y "${packages[@]}"
    else
        command -v sudo >/dev/null 2>&1 || {
            printf 'sudo is required to install build dependencies.\n' >&2
            exit 1
        }
        sudo apt-get update
        sudo apt-get install -y "${packages[@]}"
    fi
fi

for command_name in cmake ninja c++; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing build command: %s\n' "$command_name" >&2
        printf 'Rerun with --install-deps.\n' >&2
        exit 1
    }
done

if ((clean)); then
    rm -rf "$build_dir"
fi
mkdir -p "$build_dir"

cmake_args=(
    -S "$engine_root"
    -B "$build_dir"
    -G Ninja
    -DPK3_QUIET_ZIPDIR=ON
    -DUSE_PCH=OFF
    -DCMAKE_BUILD_TYPE=RelWithDebInfo
)
if command -v ccache >/dev/null 2>&1; then
    cmake_args+=(
        -DCMAKE_C_COMPILER_LAUNCHER=ccache
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
    )
fi
cmake "${cmake_args[@]}"
cmake --build "$build_dir" --parallel "$jobs"

engine=$(find_engine) || {
    printf 'sol-engine built without producing a detectable executable.\n' >&2
    exit 1
}
engine_dir=$(dirname "$engine")
if [[ -f $engine_root/tools/sol-launcher.sh ]]; then
    install -m 0755 "$engine_root/tools/sol-launcher.sh" "$engine_dir/sol-engine"
fi

# Packaging must never turn a successful compile into a failure while the local
# third-party build inputs are still being collected. Once they are complete,
# this places the canonical bundle beside the executable automatically.
if [[ -f $editor_root/tools/sol-bundle.sh ]]; then
    SOL_ENGINE="$engine" \
    SOL_ENGINE_ROOT="$engine_root" \
    SOL_EDITOR_ROOT="$editor_root" \
    SOL_BUNDLE_NO_SETUP=1 \
        bash "$editor_root/tools/sol-bundle.sh" >/dev/null 2>&1 || true
fi

printf '%s\n' "$engine"

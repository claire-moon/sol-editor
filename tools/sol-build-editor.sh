#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
install_deps=0
detect_only=0
clean=0
build_type=${SOL_EDITOR_BUILD_TYPE:-Release}

usage() {
    cat <<'USAGE'
Usage: tools/sol-build-editor.sh [--detect] [--install-deps] [--clean]
USAGE
}

while (($#)); do
    case $1 in
        --detect) detect_only=1 ;;
        --install-deps) install_deps=1 ;;
        --clean) clean=1 ;;
        --build-type) build_type=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

find_editor() {
    local candidate
    for candidate in "${SOL_EDITOR:-}" "$root/Build/builder"; do
        if [[ -n $candidate && -x $candidate ]]; then
            realpath "$candidate"
            return 0
        fi
    done
    if [[ -f $root/Build/Builder.exe && -x $(command -v mono 2>/dev/null || true) ]]; then
        printf '%s\n' "$root/Build/builder"
        return 0
    fi
    return 1
}

if ((detect_only)); then
    find_editor
    exit $?
fi

if ((install_deps)); then
    packages=(build-essential ca-certificates gnupg mesa-common-dev libx11-dev libxfixes-dev)
    if ! command -v apt-get >/dev/null 2>&1; then
        printf 'Automatic dependency installation currently supports apt-based systems only.\n' >&2
        exit 1
    fi
    if ((EUID == 0)); then
        elevate=()
    else
        command -v sudo >/dev/null 2>&1 || {
            printf 'sudo is required to install editor dependencies.\n' >&2
            exit 1
        }
        elevate=(sudo)
    fi
    "${elevate[@]}" apt-get update
    "${elevate[@]}" apt-get install -y "${packages[@]}"
    if ! command -v msbuild >/dev/null 2>&1; then
        keyring=/usr/share/keyrings/mono-official-archive-keyring.gpg
        "${elevate[@]}" gpg --homedir /tmp --no-default-keyring \
            --keyring "gnupg-ring:$keyring" \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
        "${elevate[@]}" chmod +r "$keyring"
        printf '%s\n' 'deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main' | \
            "${elevate[@]}" tee /etc/apt/sources.list.d/mono-official-stable.list >/dev/null
        "${elevate[@]}" apt-get update
    fi
    "${elevate[@]}" apt-get install -y mono-complete
fi

for command_name in make g++ msbuild mono; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing editor build command: %s\n' "$command_name" >&2
        printf 'Rerun with --install-deps.\n' >&2
        exit 1
    }
done

if ((clean)); then
    rm -rf "$root/Build"
fi
make -C "$root" BUILDTYPE="$build_type" linux
editor=$(find_editor) || {
    printf 'sol-editor build did not produce Build/builder.\n' >&2
    exit 1
}
printf '%s\n' "$editor"

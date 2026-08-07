#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
vend_root=${SOL_VEND_ROOT:-${SOL_VEND:-"$workspace/vend"}}
manifest=${SOL_WADPACK_MANIFEST:-"$root/sol-project/wadpack.json"}
state_dir=${SOL_COCKPIT_STATE:-"$root/.sol-cockpit"}
profile_root="$state_dir/wadpack-mc-profile"
mc_bin=${SOL_COCKPIT_MC_BIN:-mc}
no_mc=0
allow_missing=0
status_only=0
declare -a sources=()

usage() {
    cat <<'USAGE'
Usage: tools/sol-wadpack-setup.sh [options]

Find, normalize, lock, and verify the mandatory SOL visual/audio wadpack.

Options:
  --source PATH       Search one file or directory; may be repeated
  --status            Show the current locked wadpack
  --allow-missing     Import everything found without requiring completion
  --no-mc             Do not open the Midnight Commander source selector
  --vend DIR          Override the SOL vend directory
  --manifest FILE     Override the wadpack manifest
  -h, --help          Show this help
USAGE
}

while (($#)); do
    case $1 in
        --source) sources+=("$2"); shift 2 ;;
        --status) status_only=1; shift ;;
        --allow-missing) allow_missing=1; shift ;;
        --no-mc) no_mc=1; shift ;;
        --vend) vend_root=$2; shift 2 ;;
        --manifest) manifest=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

vend_root=$(realpath -m "$vend_root")
manifest=$(realpath -m "$manifest")
mkdir -p "$vend_root/wadpack/source" "$vend_root/wadpack/runtime" "$state_dir"
command_args=(python3 "$root/tools/sol-wadpack.py" --manifest "$manifest" --vend "$vend_root")

if ((status_only)); then
    exec "${command_args[@]}" status
fi

write_profile() {
    mkdir -p "$profile_root/.config/mc"
    cat > "$profile_root/.config/mc/menu" <<'MENU'
shell_patterns=1

W  Import SOL wadpack from highlighted file or directory
    "$SOL_COCKPIT_ROOT/tools/sol-wadpack-action.sh" import "%d/%f"

P  Show SOL wadpack status
    "$SOL_COCKPIT_ROOT/tools/sol-wadpack-action.sh" status
MENU
    cat > "$profile_root/.config/mc/ini" <<'INI'
[Midnight-Commander]
auto_save_setup=false
auto_menu=true
confirm_exit=true
use_internal_view=true
use_internal_edit=true
INI
    chmod -R u+rwX,go-rwx "$profile_root"
}

ensure_sevenzip() {
    command -v 7zz >/dev/null 2>&1 && return 0
    command -v 7z >/dev/null 2>&1 && return 0
    if command -v apt-get >/dev/null 2>&1 && [[ -t 0 ]]; then
        printf 'Flashlight++ is packaged as 7z and requires p7zip-full. Install it now? [Y/n] '
        read -r reply
        if [[ -z $reply || $reply == y || $reply == Y ]]; then
            if ((EUID == 0)); then
                apt-get update
                apt-get install -y p7zip-full
            elif command -v sudo >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y p7zip-full
            fi
        fi
    fi
    command -v 7zz >/dev/null 2>&1 || command -v 7z >/dev/null 2>&1 || {
        printf '7-Zip is required for flashlight_plus_plus_v9_1.7z. Install p7zip-full.\n' >&2
        return 1
    }
}

try_import() {
    local -a args=("${command_args[@]}" import)
    local source
    for source in "${sources[@]}"; do
        args+=(--scan "$source")
    done
    ((allow_missing)) && args+=(--allow-missing)
    "${args[@]}"
}

if ((${#sources[@]} == 0)); then
    sources+=(
        "$vend_root/wadpack/source"
        "$workspace"
        "${HOME:-$workspace}/Downloads"
        "${HOME:-$workspace}/Desktop"
        "${HOME:-$workspace}/Documents"
    )
fi

ensure_sevenzip
set +e
try_import
result=$?
set -e
if ((result == 0)); then
    printf 'SOL wadpack is locked and ready.\n'
    exit 0
fi
if ((allow_missing || no_mc || result != 2)); then
    exit "$result"
fi

if ! command -v "$mc_bin" >/dev/null 2>&1 && [[ ! -x $mc_bin ]]; then
    printf 'Midnight Commander is required to locate the remaining wadpack files.\n' >&2
    exit 2
fi

write_profile
export SOL_COCKPIT_ROOT="$root"
export SOL_COCKPIT_NO_PAUSE=1
export SOL_WORKSPACE="$workspace"
export SOL_VEND_ROOT="$vend_root"
export SOL_WADPACK_MANIFEST="$manifest"
printf '\nSOL WADPACK SELECTOR\n'
printf 'Browse to the folder containing the Rocket Launcher resources.\n'
printf 'Highlight that folder or any file inside it, press F2, then choose W.\n'
printf 'Press F10 after the import report returns.\n\n'
MC_PROFILE_ROOT="$profile_root" "$mc_bin" -u -X "${HOME:-$workspace}" "$vend_root/wadpack/runtime"

"${command_args[@]}" verify
printf 'SOL wadpack is locked and ready.\n'

#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
vend_root=${SOL_VEND_ROOT:-"$workspace/vend"}
env_file=${SOL_ENV_FILE:-"$root/.sol-env"}
state_dir=${SOL_COCKPIT_STATE:-"$root/.sol-cockpit"}
mc_bin=${SOL_COCKPIT_MC_BIN:-mc}
force_setup=0
setup_only=0
verify_only=0
status_only=0
no_build=0
engine_override=${SOL_ENGINE:-}
editor_override=${SOL_EDITOR:-}
iwad_override=
install_mode=copy

usage() {
    cat <<'USAGE'
Usage: tools/sol-cockpit.sh [options]

First-run setup and ongoing Midnight Commander cockpit for SOL.

Options:
  --setup              Run the guided setup again
  --setup-only         Complete setup without opening the cockpit afterward
  --verify             Verify the current setup and exit
  --status             Print setup status and exit
  --no-build           Do not build missing engine/editor binaries
  --engine FILE        Use an existing sol-engine executable
  --editor FILE        Use an existing sol-editor launcher
  --iwad FILE          Use this IWAD without opening the selector
  --link-iwad          Symlink rather than copy the selected IWAD
  --workspace DIR      Override the sibling workspace directory
  --engine-root DIR    Override the sol-engine checkout
  --vend DIR           Override the vend directory
  --env-file FILE      Override the generated environment file
  -h, --help           Show this help
USAGE
}

require_arg() {
    if (($# < 2)) || [[ -z ${2:-} ]]; then
        printf 'Option %s requires a value.\n' "$1" >&2
        exit 2
    fi
}

while (($#)); do
    case $1 in
        --setup) force_setup=1; shift ;;
        --setup-only) force_setup=1; setup_only=1; shift ;;
        --verify) verify_only=1; shift ;;
        --status) status_only=1; shift ;;
        --no-build) no_build=1; shift ;;
        --engine) require_arg "$@"; engine_override=$2; shift 2 ;;
        --editor) require_arg "$@"; editor_override=$2; shift 2 ;;
        --iwad) require_arg "$@"; iwad_override=$2; shift 2 ;;
        --link-iwad) install_mode=link; shift ;;
        --workspace) require_arg "$@"; workspace=$2; shift 2 ;;
        --engine-root) require_arg "$@"; engine_root=$2; shift 2 ;;
        --vend) require_arg "$@"; vend_root=$2; shift 2 ;;
        --env-file) require_arg "$@"; env_file=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

workspace=$(realpath -m "$workspace")
engine_root=$(realpath -m "$engine_root")
vend_root=$(realpath -m "$vend_root")
env_file=$(realpath -m "$env_file")
state_dir=$(realpath -m "$state_dir")
status_file="$state_dir/STATUS.txt"
selected_file="$state_dir/selected-iwad"
profile_root="$state_dir/mc-profile"
mkdir -p "$state_dir" "$vend_root/iwads" "$vend_root/pwads" "$vend_root/assets" "$vend_root/licenses"

export SOL_WORKSPACE="$workspace"
export SOL_EDITOR_ROOT="$root"
export SOL_ENGINE_ROOT="$engine_root"
export SOL_VEND_ROOT="$vend_root"
export SOL_ENV_FILE="$env_file"
export SOL_COCKPIT_STATE="$state_dir"

say_stage() {
    local current=$1 total=$2 label=$3
    printf '\n[%s/%s] %s\n' "$current" "$total" "$label"
}

assume_yes() {
    [[ ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]
}

confirm() {
    local prompt=$1 default=${2:-yes} reply
    if assume_yes; then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        [[ $default == yes ]]
        return
    fi
    if [[ $default == yes ]]; then
        printf '%s [Y/n] ' "$prompt"
    else
        printf '%s [y/N] ' "$prompt"
    fi
    read -r reply
    if [[ -z $reply ]]; then
        [[ $default == yes ]]
    else
        [[ $reply == y || $reply == Y || $reply == yes || $reply == YES ]]
    fi
}

is_iwad() {
    local magic
    [[ -f $1 ]] || return 1
    magic=$(LC_ALL=C head -c 4 "$1" 2>/dev/null || true)
    [[ $magic == IWAD ]]
}

load_env() {
    [[ -f $env_file ]] || return 1
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
}

env_valid() {
    (
        set +u
        load_env || exit 1
        [[ -x ${SOL_ENGINE:-} ]] || exit 1
        [[ -x ${SOL_EDITOR:-} ]] || exit 1
        [[ -f ${SOL_RUNTIME_PKG:-} ]] || exit 1
        is_iwad "${DOOM_IWAD:-}" || exit 1
    )
}

find_engine() {
    if [[ -n $engine_override && -x $engine_override ]]; then
        realpath "$engine_override"
        return
    fi
    SOL_ENGINE_ROOT="$engine_root" "$root/tools/sol-build-engine.sh" --detect 2>/dev/null || true
}

find_editor() {
    if [[ -n $editor_override && -x $editor_override ]]; then
        realpath "$editor_override"
        return
    fi
    SOL_EDITOR="$editor_override" "$root/tools/sol-build-editor.sh" --detect 2>/dev/null || true
}

ensure_mc() {
    if command -v "$mc_bin" >/dev/null 2>&1 || [[ -x $mc_bin ]]; then
        return 0
    fi
    printf 'Midnight Commander is required for the SOL setup cockpit.\n'
    if command -v apt-get >/dev/null 2>&1 && confirm 'Install Midnight Commander now?' yes; then
        if ((EUID == 0)); then
            apt-get update
            apt-get install -y mc
        else
            command -v sudo >/dev/null 2>&1 || {
                printf 'sudo is required to install Midnight Commander.\n' >&2
                exit 1
            }
            sudo apt-get update
            sudo apt-get install -y mc
        fi
        mc_bin=mc
        return
    fi
    printf 'Install the mc package, then rerun this cockpit.\n' >&2
    exit 1
}

write_mc_profile() {
    mkdir -p "$profile_root/.config/mc"
    cat > "$profile_root/.config/mc/menu" <<'MENU'
shell_patterns=1

I  Use highlighted IWAD (copy into vend)
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" select-iwad copy "%d/%f"

L  Use highlighted IWAD (link into vend)
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" select-iwad link "%d/%f"

E  Build or rebuild sol-engine
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" build-engine

D  Build or rebuild sol-editor
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" build-editor

V  Verify SOL setup
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" verify

T  Launch E1M1 in sol-engine
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" test

O  Open sol-editor
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" editor

S  Show setup status
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" status

R  Reset local SOL setup
    "$SOL_COCKPIT_ROOT/tools/sol-cockpit-action.sh" reset
MENU
    cat > "$profile_root/.config/mc/ini" <<'INI'
[Midnight-Commander]
auto_save_setup=false
auto_menu=true
confirm_exit=true
confirm_delete=true
use_internal_view=true
use_internal_edit=true
mouse_repeat_rate=400
INI
    chmod -R u+rwX,go-rwx "$profile_root"
}

scan_iwads() {
    local path search_root
    declare -A seen=()
    shopt -s nullglob nocaseglob
    for path in "$vend_root/iwads"/*.wad; do
        if is_iwad "$path"; then
            path=$(realpath "$path")
            [[ -n ${seen[$path]:-} ]] || { seen[$path]=1; printf '%s\n' "$path"; }
        fi
    done
    shopt -u nocaseglob
    for search_root in \
        "$HOME/.local/share/Steam/steamapps/common" \
        "$HOME/.steam/steam/steamapps/common" \
        "$HOME/GOG Games" \
        "/usr/share/games/doom" \
        "/usr/local/share/games/doom"; do
        [[ -d $search_root ]] || continue
        while IFS= read -r -d '' path; do
            if is_iwad "$path"; then
                path=$(realpath "$path")
                [[ -n ${seen[$path]:-} ]] || { seen[$path]=1; printf '%s\n' "$path"; }
            fi
        done < <(find "$search_root" -maxdepth 5 -type f \
            \( -iname doom.wad -o -iname doom1.wad -o -iname doom2.wad \
               -o -iname tnt.wad -o -iname plutonia.wad \
               -o -iname freedoom1.wad -o -iname freedoom2.wad \) \
            -print0 2>/dev/null)
    done
}

select_iwad_with_mc() {
    local start_dir candidate
    selected_iwad_result=
    ensure_mc
    write_mc_profile
    rm -f "$selected_file"
    mapfile -t candidates < <(scan_iwads)
    if ((${#candidates[@]} == 1)) && confirm "Use detected IWAD ${candidates[0]}?" yes; then
        "$root/tools/sol-cockpit-action.sh" select-iwad "$install_mode" "${candidates[0]}"
        selected_iwad_result=$(cat "$selected_file")
        return
    fi
    start_dir=${HOME:-$workspace}
    if ((${#candidates[@]} > 0)); then
        start_dir=$(dirname "${candidates[0]}")
    fi
    printf '\nMidnight Commander IWAD selector\n'
    printf '1. Browse to DOOM.WAD, DOOM2.WAD, or another legally owned IWAD.\n'
    printf '2. Highlight the file.\n'
    printf '3. Press F2 and choose I to copy it, or L to link it.\n'
    printf '4. Press F10 to return to the wizard.\n\n'
    export SOL_COCKPIT_ROOT="$root"
    export SOL_COCKPIT_NO_PAUSE=1
    MC_PROFILE_ROOT="$profile_root" "$mc_bin" -u -X "$start_dir" "$vend_root/iwads"
    if [[ ! -s $selected_file ]]; then
        printf 'No IWAD was selected.\n' >&2
        exit 1
    fi
    candidate=$(cat "$selected_file")
    is_iwad "$candidate" || {
        printf 'The selected file is not a valid IWAD: %s\n' "$candidate" >&2
        exit 1
    }
    selected_iwad_result=$candidate
}

ensure_engine() {
    local install_arg=()
    engine_result=$(find_engine)
    if [[ -n $engine_result && -x $engine_result ]]; then
        return
    fi
    if ((no_build)); then
        printf 'No built sol-engine executable was found.\n' >&2
        exit 1
    fi
    printf 'A local sol-engine build is required.\n'
    if confirm 'Install engine build dependencies with apt first?' yes; then
        install_arg=(--install-deps)
    fi
    SOL_ENGINE_ROOT="$engine_root" "$root/tools/sol-build-engine.sh" "${install_arg[@]}"
    engine_result=$(find_engine)
    [[ -n $engine_result && -x $engine_result ]] || {
        printf 'sol-engine build completed without a detectable executable.\n' >&2
        exit 1
    }
}

ensure_editor() {
    local install_arg=()
    editor_result=$(find_editor)
    if [[ -n $editor_result && -x $editor_result ]]; then
        return
    fi
    if ((no_build)); then
        printf 'No built sol-editor launcher was found.\n' >&2
        exit 1
    fi
    printf 'A local sol-editor build is required.\n'
    if confirm "Install editor dependencies and Mono's official apt source?" yes; then
        install_arg=(--install-deps)
    fi
    "$root/tools/sol-build-editor.sh" "${install_arg[@]}"
    editor_result=$(find_editor)
    [[ -n $editor_result && -x $editor_result ]] || {
        printf 'sol-editor build completed without a detectable launcher.\n' >&2
        exit 1
    }
}

install_launchers() {
    local bin_dir=${SOL_USER_BIN:-"$HOME/.local/bin"}
    [[ ${SOL_INSTALL_LAUNCHERS:-1} == 1 ]] || return 0
    if ! confirm "Install sol, sol-play, and sol-edit commands in $bin_dir?" yes; then
        return 0
    fi
    mkdir -p "$bin_dir"
    ln -sfn "$root/tools/sol-cockpit.sh" "$bin_dir/sol"
    ln -sfn "$root/tools/sol-test.sh" "$bin_dir/sol-play"
    ln -sfn "$root/tools/sol-open-editor.sh" "$bin_dir/sol-edit"
}

print_status() {
    local engine='NOT CONFIGURED' editor='NOT CONFIGURED' runtime='NOT CONFIGURED' iwad='NOT CONFIGURED'
    local env_state=FAIL engine_state=FAIL editor_state=FAIL runtime_state=FAIL iwad_state=FAIL
    if load_env 2>/dev/null; then
        env_state=PASS
        [[ -x ${SOL_ENGINE:-} ]] && { engine_state=PASS; engine=$SOL_ENGINE; }
        [[ -x ${SOL_EDITOR:-} ]] && { editor_state=PASS; editor=$SOL_EDITOR; }
        [[ -f ${SOL_RUNTIME_PKG:-} ]] && { runtime_state=PASS; runtime=$SOL_RUNTIME_PKG; }
        if is_iwad "${DOOM_IWAD:-}"; then iwad_state=PASS; iwad=$DOOM_IWAD; fi
    fi
    cat <<STATUS
SOL SETUP COCKPIT

[$env_state] Environment  $env_file
[$engine_state] Engine       $engine
[$editor_state] Editor       $editor
[$runtime_state] Runtime      $runtime
[$iwad_state] IWAD         $iwad

Workspace: $workspace
Engine checkout: $engine_root
Vendor files: $vend_root

F2 menu actions:
I select/copy IWAD   L select/link IWAD
E build engine       D build editor
V verify setup       T launch E1M1
O open editor        R reset setup
STATUS
}

verify_setup() {
    local failed=0 content_package
    if ! env_valid; then
        printf 'FAIL: generated environment is missing or invalid.\n' >&2
        return 1
    fi
    load_env
    printf 'PASS: sol-engine executable: %s\n' "$SOL_ENGINE"
    printf 'PASS: sol-editor launcher: %s\n' "$SOL_EDITOR"
    printf 'PASS: runtime package: %s\n' "$SOL_RUNTIME_PKG"
    printf 'PASS: IWAD header: %s\n' "$DOOM_IWAD"
    if ! bash "$engine_root/tools/sol-package.sh" >/dev/null; then
        printf 'FAIL: runtime package regeneration failed.\n' >&2
        failed=1
    else
        printf 'PASS: runtime package regeneration.\n'
    fi
    if ! content_package=$(SOL_SKIP_DOOMTOOLS=1 bash "$root/tools/sol-build.sh"); then
        printf 'FAIL: E1M1 content package generation failed.\n' >&2
        failed=1
    elif [[ ! -f $content_package ]]; then
        printf 'FAIL: content package path is missing: %s\n' "$content_package" >&2
        failed=1
    else
        printf 'PASS: E1M1 content package: %s\n' "$content_package"
    fi
    ((failed == 0))
}

run_setup() {
    local iwad engine editor
    printf 'SOL FIRST-RUN SETUP\n'
    printf 'Workspace: %s\n' "$workspace"
    say_stage 1 5 'Validate repository layout'
    [[ -f $engine_root/tools/sol-package.sh ]] || {
        printf 'Missing sibling sol-engine checkout: %s\n' "$engine_root" >&2
        exit 1
    }
    printf 'PASS: sol-engine and sol-editor sibling layout.\n'

    say_stage 2 5 'Select a user-owned Doom IWAD'
    if [[ -n $iwad_override ]]; then
        is_iwad "$iwad_override" || {
            printf 'Invalid IWAD: %s\n' "$iwad_override" >&2
            exit 1
        }
        iwad=$(realpath "$iwad_override")
    else
        select_iwad_with_mc
        iwad=$selected_iwad_result
    fi

    say_stage 3 5 'Locate or build sol-engine'
    ensure_engine
    engine=$engine_result
    [[ -x $engine ]] || { printf 'Engine setup failed.\n' >&2; exit 1; }
    printf 'PASS: %s\n' "$engine"

    say_stage 4 5 'Locate or build sol-editor'
    ensure_editor
    editor=$editor_result
    [[ -x $editor ]] || { printf 'Editor setup failed.\n' >&2; exit 1; }
    printf 'PASS: %s\n' "$editor"

    say_stage 5 5 'Generate environment and verify packages'
    init_args=(
        --workspace "$workspace"
        --engine-root "$engine_root"
        --engine "$engine"
        --editor "$editor"
        --vend "$vend_root"
        --primary-iwad "$iwad"
        --env-file "$env_file"
        --no-search
    )
    if [[ $install_mode == link ]]; then init_args+=(--link); else init_args+=(--copy); fi
    "$root/tools/sol-init-workspace.sh" "${init_args[@]}"
    install_launchers
    verify_setup
    print_status > "$status_file"
    printf '\nSOL setup completed.\n'
}

open_cockpit() {
    ensure_mc
    write_mc_profile
    print_status > "$status_file"
    export SOL_COCKPIT_ROOT="$root"
    export SOL_COCKPIT_NO_PAUSE=0
    printf 'Opening SOL cockpit. Press F2 for SOL actions and F10 to exit.\n'
    MC_PROFILE_ROOT="$profile_root" "$mc_bin" -u -X "$workspace" "$vend_root/iwads"
}

if ((status_only)); then
    print_status
    exit 0
fi
if ((verify_only)); then
    verify_setup
    exit
fi
if ((force_setup)) || ! env_valid; then
    run_setup
fi
if ((setup_only)); then
    exit 0
fi
open_cockpit

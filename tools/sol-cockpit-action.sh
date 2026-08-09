#!/usr/bin/env bash
set -euo pipefail

root=${SOL_EDITOR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
workspace=${SOL_WORKSPACE:-$(cd "$root/.." && pwd)}
vend_root=${SOL_VEND_ROOT:-"$workspace/vend"}
state_dir=${SOL_COCKPIT_STATE:-"$root/.sol-cockpit"}
env_file=${SOL_ENV_FILE:-"$root/.sol-env"}
status_file="$state_dir/STATUS.txt"
selected_file="$state_dir/selected-iwad"
mkdir -p "$state_dir" "$vend_root/iwads"

action=${1:-}
shift || true

is_iwad() {
    local magic
    [[ -f $1 ]] || return 1
    magic=$(LC_ALL=C head -c 4 "$1" 2>/dev/null || true)
    [[ $magic == IWAD ]]
}

is_supported_iwad() {
    local name=${1##*/}
    name=${name,,}
    [[ $name == doom.wad || $name == doomu.wad ]] && is_iwad "$1"
}

pause_if_tty() {
    if [[ -t 0 && -t 1 && ${SOL_COCKPIT_NO_PAUSE:-0} != 1 ]]; then
        printf '\nPress Enter to return to the SOL cockpit.'
        read -r _
    fi
}

case $action in
    select-iwad)
        mode=${1:-copy}
        source_path=${2:-}
        if [[ $mode != copy && $mode != link ]]; then
            printf 'Invalid IWAD install mode: %s\n' "$mode" >&2
            exit 2
        fi
        if [[ -z $source_path || ! -f $source_path ]]; then
            printf 'Highlight an IWAD file before choosing this action.\n' >&2
            pause_if_tty
            exit 1
        fi
        source_path=$(realpath "$source_path")
        if ! is_supported_iwad "$source_path"; then
            printf 'Select a Doom IWAD candidate named DOOM.WAD or DOOMU.WAD; SOL Engine validates its contents at launch: %s\n' "$source_path" >&2
            pause_if_tty
            exit 1
        fi
        destination="$vend_root/iwads/$(basename "$source_path" | tr '[:upper:]' '[:lower:]')"
        if [[ $source_path != $(realpath -m "$destination") ]]; then
            if [[ $mode == link ]]; then
                ln -sfn "$source_path" "$destination"
            else
                cp -f "$source_path" "$destination"
            fi
        fi
        destination=$(realpath -m "$destination")
        printf '%s\n' "$destination" > "$selected_file"
        if [[ -f $env_file ]]; then
            set -a
            # shellcheck disable=SC1090
            source "$env_file"
            set +a
            if [[ -x ${SOL_ENGINE:-} && -x ${SOL_EDITOR:-} ]]; then
                "$root/tools/sol-init-workspace.sh" \
                    --workspace "$workspace" \
                    --engine-root "${SOL_ENGINE_ROOT:-$workspace/sol-engine}" \
                    --engine "$SOL_ENGINE" \
                    --editor "$SOL_EDITOR" \
                    --vend "$vend_root" \
                    --primary-iwad "$destination" \
                    --env-file "$env_file" \
                    --copy --no-search >/dev/null
            fi
        fi
        printf 'Selected IWAD: %s\n' "$destination"
        printf 'Press F10 to return to the guided setup.\n'
        pause_if_tty
        ;;
    build-engine)
        install_arg=()
        if [[ ${SOL_COCKPIT_INSTALL_DEPS:-0} == 1 ]]; then
            install_arg=(--install-deps)
        fi
        "$root/tools/sol-build-engine.sh" "${install_arg[@]}"
        "$root/tools/sol-cockpit.sh" --status > "$status_file"
        pause_if_tty
        ;;
    build-editor)
        install_arg=()
        if [[ ${SOL_COCKPIT_INSTALL_DEPS:-0} == 1 ]]; then
            install_arg=(--install-deps)
        fi
        "$root/tools/sol-build-editor.sh" "${install_arg[@]}"
        "$root/tools/sol-cockpit.sh" --status > "$status_file"
        pause_if_tty
        ;;
    verify)
        "$root/tools/sol-cockpit.sh" --verify
        printf '\nSOL locked wadpack:\n'
        "$root/tools/sol-wadpack-setup.sh" --status
        pause_if_tty
        ;;
    test)
        exec "$root/tools/sol-test.sh" E1M1
        ;;
    editor)
        exec "$root/tools/sol-open-editor.sh"
        ;;
    status)
        "$root/tools/sol-cockpit.sh" --status
        printf '\nSOL locked wadpack:\n'
        "$root/tools/sol-wadpack-setup.sh" --status || true
        pause_if_tty
        ;;
    reset)
        confirmed=0
        if [[ ${SOL_COCKPIT_ASSUME_YES:-0} == 1 ]]; then
            confirmed=1
        elif [[ -t 0 ]]; then
            printf 'Reset SOL local setup? [y/N] '
            read -r reply
            [[ $reply == y || $reply == Y ]] && confirmed=1
        fi
        if ((confirmed)); then
            rm -f "$env_file" "$selected_file"
            rm -rf "$state_dir/mc-profile"
            printf 'SOL local setup reset. The local wadpack was preserved.\n'
        else
            printf 'Reset cancelled.\n'
        fi
        pause_if_tty
        ;;
    *)
        printf 'Unknown cockpit action: %s\n' "$action" >&2
        exit 2
        ;;
esac

#!/usr/bin/env bash
set -euo pipefail

root=${SOL_EDITOR_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
action=${1:-}
shift || true

pause_if_tty() {
    if [[ -t 0 && -t 1 && ${SOL_COCKPIT_NO_PAUSE:-0} != 1 ]]; then
        printf '\nPress Enter to return.'
        read -r _
    fi
}

case $action in
    import)
        selected=${1:-}
        [[ -e $selected ]] || {
            printf 'Highlight a source file or directory.\n' >&2
            exit 1
        }
        if [[ -f $selected ]]; then
            selected=$(dirname "$selected")
        fi
        "$root/tools/sol-wadpack-setup.sh" --source "$selected" --no-mc --allow-missing
        "$root/tools/sol-wadpack-setup.sh" --status || true
        pause_if_tty
        ;;
    status)
        "$root/tools/sol-wadpack-setup.sh" --status || true
        pause_if_tty
        ;;
    *)
        printf 'Unknown wadpack action: %s\n' "$action" >&2
        exit 2
        ;;
esac

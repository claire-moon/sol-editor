#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=$(cd "$root/.." && pwd)
engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}
vend_root=${SOL_VEND_ROOT:-"$workspace/vend"}
env_file="$root/.sol-env"
mode=copy
engine_override=
primary_override=
search_enabled=1
declare -a supplied_iwads=()

usage() {
    cat <<'EOF'
Usage: tools/sol-init-workspace.sh [options]

Prepare a local SOL workspace around sibling sol-engine, sol-editor, and vend
directories. Commercial IWADs are never downloaded.

Options:
  --workspace DIR      Workspace containing sol-engine, sol-editor, and vend
  --engine-root DIR    Local sol-engine checkout
  --engine FILE        Built executable from the local sol-engine checkout
  --vend DIR           Third-party file directory
  --iwad FILE          Add a user-owned IWAD; may be repeated
  --primary-iwad FILE  Add and select the primary IWAD
  --copy               Copy IWADs into vend/iwads (default)
  --link               Symlink IWADs into vend/iwads
  --env-file FILE      Generated shell environment file
  --no-search          Do not scan common local game-install paths
  -h, --help           Show this help
EOF
}

while (($#)); do
    case $1 in
        --workspace)
            workspace=$2
            shift 2
            ;;
        --engine-root)
            engine_root=$2
            shift 2
            ;;
        --engine)
            engine_override=$2
            shift 2
            ;;
        --vend)
            vend_root=$2
            shift 2
            ;;
        --iwad)
            supplied_iwads+=("$2")
            shift 2
            ;;
        --primary-iwad)
            primary_override=$2
            supplied_iwads+=("$2")
            shift 2
            ;;
        --copy)
            mode=copy
            shift
            ;;
        --link)
            mode=link
            shift
            ;;
        --env-file)
            env_file=$2
            shift 2
            ;;
        --no-search)
            search_enabled=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

workspace=$(realpath -m "$workspace")
engine_root=$(realpath -m "$engine_root")
vend_root=$(realpath -m "$vend_root")
env_file=$(realpath -m "$env_file")
iwad_dir="$vend_root/iwads"
mkdir -p "$iwad_dir" "$vend_root/pwads" "$vend_root/assets" "$vend_root/licenses"

if [[ ! -d $engine_root/.git && ! -f $engine_root/tools/sol-package.sh ]]; then
    printf 'SOL engine checkout not found: %s\n' "$engine_root" >&2
    exit 1
fi
if [[ ! -x $engine_root/tools/sol-package.sh ]]; then
    if [[ -f $engine_root/tools/sol-package.sh ]]; then
        chmod +x "$engine_root/tools/sol-package.sh"
    else
        printf 'SOL runtime packager not found: %s\n' "$engine_root/tools/sol-package.sh" >&2
        exit 1
    fi
fi

find_engine() {
    local candidate
    if [[ -n $engine_override ]]; then
        printf '%s\n' "$engine_override"
        return
    fi
    for candidate in \
        "$engine_root/build/uzdoom" \
        "$engine_root/build/Release/uzdoom" \
        "$engine_root/build/Debug/uzdoom" \
        "$engine_root/build/src/uzdoom" \
        "$engine_root/build/sol-engine" \
        "$engine_root/uzdoom"; do
        if [[ -x $candidate ]]; then
            printf '%s\n' "$candidate"
            return
        fi
    done
    candidate=$(find "$engine_root" -maxdepth 5 -type f \
        \( -name uzdoom -o -name sol-engine -o -name 'UZDoom*.AppImage' \) \
        -perm -111 -print -quit 2>/dev/null || true)
    [[ -n $candidate ]] && printf '%s\n' "$candidate"
}

engine=$(find_engine)
if [[ -z $engine ]]; then
    printf 'No built sol-engine executable was found under %s\n' "$engine_root" >&2
    printf 'Build sol-engine, then rerun with --engine /absolute/path/to/uzdoom.\n' >&2
    exit 1
fi
engine=$(realpath "$engine")
if [[ ! -x $engine ]]; then
    printf 'SOL engine is not executable: %s\n' "$engine" >&2
    exit 1
fi

runtime_package=$(bash "$engine_root/tools/sol-package.sh" | tail -n 1)
runtime_package=$(realpath -m "$runtime_package")
if [[ ! -f $runtime_package ]]; then
    printf 'SOL runtime package was not produced: %s\n' "$runtime_package" >&2
    exit 1
fi

canonical_iwad_name() {
    local name=${1##*/}
    printf '%s\n' "${name,,}"
}

is_iwad() {
    local magic
    [[ -f $1 ]] || return 1
    magic=$(LC_ALL=C head -c 4 "$1" 2>/dev/null || true)
    [[ $magic == IWAD ]]
}

declare -a candidates=()
declare -A candidate_seen=()

add_candidate() {
    local path
    path=$(realpath -m "$1")
    [[ -f $path ]] || return 0
    [[ -n ${candidate_seen[$path]:-} ]] && return 0
    candidate_seen[$path]=1
    candidates+=("$path")
}

for path in "${supplied_iwads[@]}"; do
    if [[ ! -f $path ]]; then
        printf 'IWAD file does not exist: %s\n' "$path" >&2
        exit 1
    fi
    add_candidate "$path"
done

if ((search_enabled)); then
    shopt -s nullglob nocaseglob
    for path in "$iwad_dir"/*.wad; do
        add_candidate "$path"
    done
    shopt -u nocaseglob
    search_roots=(
        "$HOME/.local/share/Steam/steamapps/common"
        "$HOME/.steam/steam/steamapps/common"
        "$HOME/GOG Games"
        "/usr/share/games/doom"
        "/usr/local/share/games/doom"
    )
    for search_root in "${search_roots[@]}"; do
        [[ -d $search_root ]] || continue
        while IFS= read -r -d '' path; do
            add_candidate "$path"
        done < <(find "$search_root" -maxdepth 5 -type f \
            \( -iname doom.wad -o -iname doom1.wad -o -iname doom2.wad \
               -o -iname tnt.wad -o -iname plutonia.wad \
               -o -iname freedoom1.wad -o -iname freedoom2.wad \) \
            -print0 2>/dev/null)
    done
fi

if ((${#candidates[@]} == 0)); then
    printf 'No IWADs were found.\n' >&2
    printf 'Copy a legally obtained DOOM.WAD into %s or rerun with --iwad FILE.\n' "$iwad_dir" >&2
    exit 1
fi

declare -a installed=()
declare -A installed_seen=()
for source_path in "${candidates[@]}"; do
    if ! is_iwad "$source_path"; then
        printf 'Rejected file without an IWAD header: %s\n' "$source_path" >&2
        exit 1
    fi
    name=$(canonical_iwad_name "$source_path")
    destination="$iwad_dir/$name"
    if [[ $(realpath -m "$source_path") != $(realpath -m "$destination") ]]; then
        if [[ $mode == link ]]; then
            ln -sfn "$(realpath "$source_path")" "$destination"
        else
            cp -f "$source_path" "$destination"
        fi
    fi
    destination=$(realpath -m "$destination")
    if [[ -z ${installed_seen[$destination]:-} ]]; then
        installed_seen[$destination]=1
        installed+=("$destination")
    fi
done

select_primary() {
    local preferred path
    if [[ -n $primary_override ]]; then
        preferred=$(canonical_iwad_name "$primary_override")
        path="$iwad_dir/$preferred"
        [[ -f $path ]] || {
            printf 'Primary IWAD was not installed: %s\n' "$path" >&2
            return 1
        }
        printf '%s\n' "$path"
        return
    fi
    for preferred in doom.wad doom1.wad doom2.wad freedoom1.wad freedoom2.wad tnt.wad plutonia.wad; do
        if [[ -f $iwad_dir/$preferred ]]; then
            printf '%s\n' "$iwad_dir/$preferred"
            return
        fi
    done
    printf '%s\n' "${installed[0]}"
}

primary_iwad=$(select_primary)
if [[ ${primary_iwad##*/} != doom.wad && ${primary_iwad##*/} != doom1.wad ]]; then
    printf 'Warning: the classic Episode 1 world map requires a Doom/Ultimate Doom IWAD.\n' >&2
fi

manifest="$vend_root/IWADS.sha256"
: > "$manifest"
for path in "${installed[@]}"; do
    sha256sum "$path" >> "$manifest"
done

cat > "$vend_root/README.txt" <<EOF
SOL local third-party files

iwads/     User-owned IWADs. These files are never committed.
pwads/     External test PWADs.
assets/    Licensed external development assets.
licenses/  License and provenance records.
IWADS.sha256 records the installed IWAD checksums.

Commercial Doom data is not downloaded or redistributed by SOL.
EOF

shell_quote() {
    printf '%q' "$1"
}

mkdir -p "$(dirname "$env_file")"
{
    printf '# Generated by tools/sol-init-workspace.sh\n'
    printf 'export SOL_WORKSPACE=%s\n' "$(shell_quote "$workspace")"
    printf 'export SOL_EDITOR_ROOT=%s\n' "$(shell_quote "$root")"
    printf 'export SOL_ENGINE_ROOT=%s\n' "$(shell_quote "$engine_root")"
    printf 'export SOL_ENGINE=%s\n' "$(shell_quote "$engine")"
    printf 'export SOL_VEND=%s\n' "$(shell_quote "$vend_root")"
    printf 'export SOL_RUNTIME_PKG=%s\n' "$(shell_quote "$runtime_package")"
    printf 'export DOOM_IWAD=%s\n' "$(shell_quote "$primary_iwad")"
} > "$env_file"
chmod 600 "$env_file"

printf 'SOL workspace initialized.\n'
printf 'Engine: %s\n' "$engine"
printf 'Runtime: %s\n' "$runtime_package"
printf 'IWAD: %s\n' "$primary_iwad"
printf 'Environment: %s\n' "$env_file"
printf 'Run: source %q && bash %q E1M1\n' "$env_file" "$root/tools/sol-test.sh"

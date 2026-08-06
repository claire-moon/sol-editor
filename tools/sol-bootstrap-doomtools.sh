#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lock_file="$root/sol/doomtools.lock"
tool_dir=${SOL_DOOMTOOLS_DIR:-"$root/.sol-tools/doomtools"}
verify_only=0

if [[ ${1:-} == "--verify-only" ]]; then
    verify_only=1
elif [[ $# -gt 0 ]]; then
    printf 'Usage: %s [--verify-only]\n' "$0" >&2
    exit 2
fi

if [[ ! -f $lock_file ]]; then
    printf 'Missing DoomTools lock file: %s\n' "$lock_file" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$lock_file"

for command in git; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command" >&2
        exit 1
    fi
done

if [[ -e $tool_dir && ! -d $tool_dir/.git ]]; then
    printf 'DoomTools path exists but is not a git checkout: %s\n' "$tool_dir" >&2
    exit 1
fi

if [[ ! -d $tool_dir/.git ]]; then
    mkdir -p "$(dirname "$tool_dir")"
    git clone --filter=blob:none --no-checkout "$DOOMTOOLS_REPOSITORY" "$tool_dir"
fi

remote=$(git -C "$tool_dir" remote get-url origin)
if [[ $remote != "$DOOMTOOLS_REPOSITORY" && $remote != "${DOOMTOOLS_REPOSITORY%.git}" ]]; then
    printf 'Unexpected DoomTools origin: %s\n' "$remote" >&2
    exit 1
fi

git -C "$tool_dir" fetch --depth 1 origin "$DOOMTOOLS_COMMIT"
git -C "$tool_dir" checkout --detach --force "$DOOMTOOLS_COMMIT"

actual=$(git -C "$tool_dir" rev-parse HEAD)
if [[ $actual != "$DOOMTOOLS_COMMIT" ]]; then
    printf 'DoomTools revision mismatch: expected %s, got %s\n' "$DOOMTOOLS_COMMIT" "$actual" >&2
    exit 1
fi

if (( verify_only )); then
    printf '%s\n' "$actual"
    exit 0
fi

for command in java ant; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command" >&2
        exit 1
    fi
done

(
    cd "$tool_dir"
    ant dependencies jar.one
)

jar=$(find "$tool_dir/build/jar" -maxdepth 1 -type f -name 'doomtools-*.jar' -print | LC_ALL=C sort | tail -n 1)
if [[ -z $jar ]]; then
    printf 'DoomTools build completed without producing a JAR.\n' >&2
    exit 1
fi

bin_dir="$root/.sol-tools/bin"
mkdir -p "$bin_dir"
cat > "$bin_dir/doommake" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

tool_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../doomtools" && pwd)
jar=$(find "$tool_root/build/jar" -maxdepth 1 -type f -name 'doomtools-*.jar' -print | LC_ALL=C sort | tail -n 1)
if [[ -z $jar ]]; then
    printf 'DoomTools JAR not found. Run tools/sol-bootstrap-doomtools.sh.\n' >&2
    exit 1
fi
exec java -cp "$jar" net.mtrop.doom.tools.DoomMakeMain "$@"
WRAPPER
chmod +x "$bin_dir/doommake"

printf 'DoomTools ready: %s\n' "$actual"
printf 'DoomMake wrapper: %s\n' "$bin_dir/doommake"

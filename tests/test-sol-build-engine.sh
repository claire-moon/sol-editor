#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
build_dir="$engine_root/build/sol-local"
mkdir -p "$build_dir" "$engine_root/build/sol-v030" "$engine_root/build/package"

make_engine() {
    local path=$1
    mkdir -p "$(dirname "$path")"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$path"
    chmod +x "$path"
}

legacy="$build_dir/uzdoom"
native="$engine_root/build/sol-v030/sol-engine"
make_engine "$legacy"
make_engine "$native"

detected=$(SOL_ENGINE_ROOT="$engine_root" SOL_ENGINE_BUILD_DIR="$build_dir" \
    bash "$root/tools/sol-build-engine.sh" --detect)
test "$detected" = "$native"

rm -f "$native"
appimage="$engine_root/build/package/Linux-x86_64-SOL-Engine-0.3.0-test.AppImage"
make_engine "$appimage"
detected=$(SOL_ENGINE_ROOT="$engine_root" SOL_ENGINE_BUILD_DIR="$build_dir" \
    bash "$root/tools/sol-build-engine.sh" --detect)
test "$detected" = "$appimage"

rm -f "$appimage"
cat > "$build_dir/sol-engine" <<'LAUNCHER'
#!/usr/bin/env bash
launcher_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$launcher_dir/uzdoom" "$@"
LAUNCHER
chmod +x "$build_dir/sol-engine"
detected=$(SOL_ENGINE_ROOT="$engine_root" SOL_ENGINE_BUILD_DIR="$build_dir" \
    bash "$root/tools/sol-build-engine.sh" --detect)
test "$detected" = "$legacy"

make_engine "$native"
detected=$(SOL_ENGINE="$legacy" SOL_ENGINE_ROOT="$engine_root" \
    SOL_ENGINE_BUILD_DIR="$build_dir" \
    bash "$root/tools/sol-build-engine.sh" --detect)
test "$detected" = "$legacy"

printf 'native SOL engine detection tests passed\n'

#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
mkdir -p "$engine_root/tools"

cat > "$engine_root/tools/sol-bundle.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
target=${SOL_BUNDLE:?}
mkdir -p "$(dirname "$target")"
printf 'SOL v0.4 bundle fixture\n' > "$target"
printf '%s\n' "$target"
SH
chmod +x "$engine_root/tools/sol-bundle.sh"

target="$tmp/output/sol.pk3"
bundle=$(SOL_ENGINE_ROOT="$engine_root" SOL_BUNDLE="$target" \
    bash "$root/tools/sol-package.sh")
test "$bundle" = "$target"
test -f "$bundle"
grep -Fx 'SOL v0.4 bundle fixture' "$bundle"

printf 'engine-owned package delegation tests passed\n'

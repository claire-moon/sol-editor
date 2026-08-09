#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
mkdir -p "$engine_root/tools"

cat > "$engine_root/tools/sol-wadpack.py" <<'PY'
#!/usr/bin/env python3
import sys
print('ENGINE_WADPACK_TOOL')
for argument in sys.argv[1:]:
    print(argument)
PY
chmod +x "$engine_root/tools/sol-wadpack.py"

output=$(SOL_ENGINE_ROOT="$engine_root" \
    python3 "$root/tools/sol-wadpack.py" \
    --manifest manifest.json --vend vend verify)
printf '%s\n' "$output" | grep -Fx 'ENGINE_WADPACK_TOOL'
printf '%s\n' "$output" | grep -Fx -- '--manifest'
printf '%s\n' "$output" | grep -Fx 'manifest.json'
printf '%s\n' "$output" | grep -Fx -- '--vend'
printf '%s\n' "$output" | grep -Fx 'vend'
printf '%s\n' "$output" | grep -Fx 'verify'

if SOL_ENGINE_ROOT="$tmp/missing-engine" \
    python3 "$root/tools/sol-wadpack.py" --manifest manifest.json --vend vend verify \
    >/dev/null 2>&1; then
    printf 'editor wadpack compatibility wrapper accepted a missing engine tool\n' >&2
    exit 1
fi

printf 'engine-owned wadpack delegation tests passed\n'

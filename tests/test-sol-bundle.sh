#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
engine_root="$tmp/sol-engine"
mkdir -p "$engine_root/tools"

cat > "$engine_root/tools/sol-bundle.py" <<'PY'
#!/usr/bin/env python3
import sys
print('ENGINE_BUNDLE_TOOL')
for argument in sys.argv[1:]:
    print(argument)
PY
chmod +x "$engine_root/tools/sol-bundle.py"

output=$(SOL_ENGINE_ROOT="$engine_root" \
    python3 "$root/tools/sol-bundle.py" verify --bundle fixture.pk3)
printf '%s\n' "$output" | grep -Fx 'ENGINE_BUNDLE_TOOL'
printf '%s\n' "$output" | grep -Fx 'verify'
printf '%s\n' "$output" | grep -Fx -- '--bundle'
printf '%s\n' "$output" | grep -Fx 'fixture.pk3'

if SOL_ENGINE_ROOT="$tmp/missing-engine" \
    python3 "$root/tools/sol-bundle.py" verify --bundle fixture.pk3 \
    >/dev/null 2>&1; then
    printf 'editor bundle compatibility wrapper accepted a missing engine tool\n' >&2
    exit 1
fi

printf 'engine-owned bundle delegation tests passed\n'

#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
wrapper="$root/.sol-tools/bin/doommake"

if [[ ! -x $wrapper ]]; then
    bash "$root/tools/sol-bootstrap-doomtools.sh"
fi

exec "$wrapper" "$@"

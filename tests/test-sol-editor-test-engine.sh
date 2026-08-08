#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$root/Source/Core/Config/ConfigurationInfo.cs"
launcher="$root/tools/sol-open-editor-main.sh"
wrapper="$root/tools/sol-editor-engine.sh"

grep -F 'Environment.GetEnvironmentVariable("SOL_EDITOR_TEST_ENGINE")' "$config" >/dev/null
grep -F 'testEngines[currentEngineIndex].TestProgram : soltestprogram' "$config" >/dev/null
grep -F 'Environment.GetEnvironmentVariable("SOL_WADPACK_LOAD_ORDER")' "$config" >/dev/null
grep -F 'new DataLocation(type, path, false, false, true, null)' "$config" >/dev/null
grep -F 'return Resources;' "$config" >/dev/null
grep -F 'export SOL_EDITOR_TEST_ENGINE="$root/tools/sol-editor-engine.sh"' "$launcher" >/dev/null
grep -F 'export SOL_WADPACK_LOAD_ORDER="$resources_file"' "$launcher" >/dev/null
grep -F -- '--scope wadpack' "$launcher" >/dev/null
grep -F 'args=(-file "$bundle")' "$wrapper" >/dev/null
grep -F 'native embedded carriers' "$wrapper" >/dev/null
! grep -F 'mapfile -t engine_files' "$wrapper" >/dev/null

printf 'editor native sol.pk3 resource and test-engine override tests passed\n'

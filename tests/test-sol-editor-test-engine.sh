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
grep -F 'engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}' "$launcher" >/dev/null
grep -F 'manifest=${SOL_WADPACK_MANIFEST:-"$engine_root/sol/wadpack.json"}' "$launcher" >/dev/null
grep -F 'version_file=${SOL_VERSION_FILE:-"$engine_root/sol/version.json"}' "$launcher" >/dev/null
grep -F 'export SOL_EDITOR_TEST_ENGINE="$root/tools/sol-editor-engine.sh"' "$launcher" >/dev/null
grep -F 'export SOL_WADPACK_LOAD_ORDER="$resources_file"' "$launcher" >/dev/null
grep -F -- '--scope wadpack' "$launcher" >/dev/null
grep -F 'engine_root=${SOL_ENGINE_ROOT:-"$workspace/sol-engine"}' "$wrapper" >/dev/null
grep -F 'manifest=${SOL_WADPACK_MANIFEST:-"$engine_root/sol/wadpack.json"}' "$wrapper" >/dev/null
grep -F 'args=()' "$wrapper" >/dev/null
grep -F 'is_native_sol_engine()' "$wrapper" >/dev/null
grep -F 'sol-engine|sol-engine.exe|*SOL-Engine*.AppImage' "$wrapper" >/dev/null
grep -F 'args+=(-file "$bundle")' "$wrapper" >/dev/null
! grep -F 'mapfile -t engine_files' "$wrapper" >/dev/null

printf 'v0.4 editor resource materialization and test-engine override tests passed\n'

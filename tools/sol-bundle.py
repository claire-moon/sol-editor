#!/usr/bin/env python3
"""Compatibility entry point for the engine-owned SOL v0.4 bundle tool."""

import os
import sys

from pathlib import Path


root = Path(__file__).resolve().parents[1]
workspace = Path(os.environ.get("SOL_WORKSPACE", root.parent))
engine_root = Path(os.environ.get("SOL_ENGINE_ROOT", workspace / "sol-engine"))
tool = engine_root / "tools" / "sol-bundle.py"

if not tool.is_file():
    raise SystemExit(f"SOL Engine v0.4 bundle tool not found: {tool}")

os.execv(sys.executable, [sys.executable, str(tool), *sys.argv[1:]])

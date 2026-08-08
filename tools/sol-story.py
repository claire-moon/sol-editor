#!/usr/bin/env python3
"""Validate SOL story authoring manifests."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

CONTRACT = 1
MIN_ID = 1
MAX_ID = 65535
NAMESPACES = ("events", "objectives", "subtitles", "radio")
KEY_RE = re.compile(r"^[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*$")
EVENT_REFS = {
    "objective_id": "objectives",
    "subtitle_id": "subtitles",
    "radio_id": "radio",
}


def die(message: str) -> None:
    raise ValueError(message)


def load_manifest(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        die(f"cannot read story manifest {path}: {exc}")
    if not isinstance(data, dict):
        die("story manifest root must be an object")
    return data


def validate_id(value: Any, context: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        die(f"{context} id must be an integer")
    if value < MIN_ID or value > MAX_ID:
        die(f"{context} id must be in {MIN_ID}..{MAX_ID}")
    return value


def validate_key(value: Any, context: str) -> str:
    if not isinstance(value, str) or KEY_RE.fullmatch(value) is None:
        die(f"{context} key must use stable lowercase identifier syntax")
    return value


def validate_namespace(data: dict[str, Any], namespace: str) -> tuple[set[int], set[str]]:
    entries = data.get(namespace)
    if not isinstance(entries, list):
        die(f"{namespace} must be an array")
    ids: set[int] = set()
    keys: set[str] = set()
    for index, entry in enumerate(entries):
        context = f"{namespace}[{index}]"
        if not isinstance(entry, dict):
            die(f"{context} must be an object")
        ident = validate_id(entry.get("id"), context)
        key = validate_key(entry.get("key"), context)
        if ident in ids:
            die(f"duplicate {namespace} id: {ident}")
        if key in keys:
            die(f"duplicate {namespace} key: {key}")
        ids.add(ident)
        keys.add(key)
    return ids, keys


def validate_manifest(path: Path) -> dict[str, Any]:
    data = load_manifest(path)
    if data.get("contract") != CONTRACT:
        die(f"story contract must be {CONTRACT}")
    if not isinstance(data.get("map"), str) or not data["map"]:
        die("story map must be a non-empty string")

    ids: dict[str, set[int]] = {}
    for namespace in NAMESPACES:
        ids[namespace], _ = validate_namespace(data, namespace)

    for index, event in enumerate(data["events"]):
        for field, namespace in EVENT_REFS.items():
            value = event.get(field)
            if value is None:
                continue
            ident = validate_id(value, f"events[{index}].{field}")
            if ident not in ids[namespace]:
                die(f"events[{index}].{field} references missing {namespace} id {ident}")
    return data


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    try:
        data = validate_manifest(args.manifest)
    except ValueError as exc:
        print(f"SOL story validation failed: {exc}", file=sys.stderr)
        return 1
    if args.summary:
        counts = ", ".join(f"{name}={len(data[name])}" for name in NAMESPACES)
        print(f"story contract {CONTRACT} {data['map']}: {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Validate the generated SOL E1M1 PWAD and graybox release contract."""
import argparse
import json
import re
import struct
from collections import deque
from pathlib import Path

MONSTER_TYPES = {9, 3001, 3002, 3004}
BLOCK_KINDS = ("vertex", "linedef", "sidedef", "sector", "thing")


def fail(message):
    raise SystemExit(message)


def parse_value(raw):
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    try:
        return float(raw) if any(marker in raw.lower() for marker in (".", "e")) else int(raw)
    except ValueError:
        fail(f"unsupported UDMF value: {raw}")


def parse_blocks(textmap, kind):
    pattern = re.compile(rf"(?ms)^{re.escape(kind)}\s*\n\{{\s*\n(.*?)^\}}\s*\n")
    blocks = []
    for body in pattern.findall(textmap):
        values = {}
        for line in body.splitlines():
            match = re.fullmatch(r"\s*([A-Za-z0-9_]+)\s*=\s*(.+);\s*", line)
            if not match:
                fail(f"malformed {kind} property: {line}")
            key, raw = match.groups()
            if key in values:
                fail(f"duplicate {kind} property: {key}")
            values[key] = parse_value(raw)
        blocks.append(values)
    return blocks


def read_wad(path):
    data = path.read_bytes()
    if len(data) < 12 or data[:4] != b"PWAD":
        fail("E1M1.wad is not a valid PWAD header")
    count, directory_offset = struct.unpack_from("<II", data, 4)
    directory_size = count * 16
    if directory_offset < 12 or directory_offset + directory_size != len(data):
        fail("PWAD directory is outside the file or not terminal")

    entries = []
    for index in range(count):
        offset, size, raw_name = struct.unpack_from("<II8s", data, directory_offset + index * 16)
        try:
            name = raw_name.rstrip(b"\0").decode("ascii")
        except UnicodeDecodeError:
            fail("PWAD contains a non-ASCII lump name")
        if offset < 12 or offset + size > directory_offset:
            fail(f"PWAD lump is outside the data region: {name}")
        entries.append((name, offset, size))

    if [entry[0] for entry in entries] != ["E1M1", "TEXTMAP", "ENDMAP"]:
        fail("unexpected E1M1 lump order")
    text_entry = entries[1]
    try:
        textmap = data[text_entry[1]:text_entry[1] + text_entry[2]].decode("utf-8")
    except UnicodeDecodeError:
        fail("TEXTMAP is not UTF-8")
    return textmap


def require_index(value, length, label):
    if not isinstance(value, int) or value < 0 or value >= length:
        fail(f"invalid {label} index: {value}")
    return value


def validate_geometry(blocks, stats):
    vertices = blocks["vertex"]
    sidedefs = blocks["sidedef"]
    linedefs = blocks["linedef"]
    sectors = blocks["sector"]

    adjacency = {index: set() for index in range(len(sectors))}
    exit_lines = []
    for linedef in linedefs:
        require_index(linedef.get("v1"), len(vertices), "v1")
        require_index(linedef.get("v2"), len(vertices), "v2")
        front_index = require_index(linedef.get("sidefront"), len(sidedefs), "sidefront")
        front_sector = require_index(sidedefs[front_index].get("sector"), len(sectors), "front sector")

        if linedef.get("twosided") is True:
            back_index = require_index(linedef.get("sideback"), len(sidedefs), "sideback")
            back_sector = require_index(sidedefs[back_index].get("sector"), len(sectors), "back sector")
            if front_sector == back_sector:
                fail("two-sided linedef connects a sector to itself")
            adjacency[front_sector].add(back_sector)
            adjacency[back_sector].add(front_sector)
        elif "sideback" in linedef:
            fail("one-sided linedef unexpectedly has a back side")

        if linedef.get("special") == 243:
            exit_lines.append(linedef)

    if len(exit_lines) != 1 or exit_lines[0].get("playeruse") is not True:
        fail("expected one player-use Exit_Normal linedef")

    if not sectors:
        fail("map contains no sectors")
    visited = {0}
    queue = deque([0])
    while queue:
        current = queue.popleft()
        for neighbor in adjacency[current] - visited:
            visited.add(neighbor)
            queue.append(neighbor)
    if len(visited) != len(sectors):
        fail(f"sector graph is disconnected: reached {len(visited)} of {len(sectors)}")
    if len(sectors) != 14 or len(adjacency) != stats["sectors"]:
        fail("sector budget changed without updating the release contract")


def validate_things(things, stats):
    types = [thing.get("type") for thing in things]
    monster_count = sum(thing_type in MONSTER_TYPES for thing_type in types)
    if monster_count != stats["monsters"] or monster_count != 176:
        fail(f"monster budget mismatch: expected 176, found {monster_count}")
    if types.count(1) != 1:
        fail("expected exactly one player-one start")
    if 2001 not in types or 2002 not in types:
        fail("graybox weapon progression is incomplete")

    for thing in things:
        x = thing.get("x")
        y = thing.get("y")
        if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
            fail("thing is missing numeric coordinates")
        if not (0 <= x <= 14 * 512 and 0 <= y <= 512):
            fail(f"thing is outside the graybox bounds: ({x}, {y})")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, required=True)
    args = parser.parse_args()

    textmap = read_wad(args.directory / "E1M1.wad")
    stats = json.loads((args.directory / "stats.json").read_text(encoding="utf-8"))
    blocks = {kind: parse_blocks(textmap, kind) for kind in BLOCK_KINDS}

    for plural, kind in (
        ("vertices", "vertex"),
        ("linedefs", "linedef"),
        ("sidedefs", "sidedef"),
        ("sectors", "sector"),
        ("things", "thing"),
    ):
        actual = len(blocks[kind])
        if stats.get(plural) != actual:
            fail(f"{plural}: expected {stats.get(plural)}, found {actual}")

    if stats.get("map") != "E1M1" or stats.get("version") != "0.1.0":
        fail("generated metadata does not match the v0.1.0 E1M1 contract")

    validate_geometry(blocks, stats)
    validate_things(blocks["thing"], stats)
    print(json.dumps(stats, sort_keys=True))


if __name__ == "__main__":
    main()

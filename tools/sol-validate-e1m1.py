#!/usr/bin/env python3
"""Validate the generated SOL! E1M1 TESTMAP v0.4 contract."""

import argparse
import json
import re
import struct

from collections import deque
from pathlib import Path


MONSTER_TYPES = {9, 58, 3001, 3002, 3003, 3004, 3005, 3006}
REQUIRED_WEAPONS = {2001, 2002, 2003, 2004, 2005, 2006}
DECORATION_TYPES = {15, 18, 19, 20, 21, 22, 34, 35, 44, 45, 46, 55, 56, 57, 2035}
BLOCK_KINDS = ("vertex", "linedef", "sidedef", "sector", "thing")
PORTAL_SPECIAL = 156
PORTAL_TYPE_LINKED = 3
PORTAL_IDS = {
    9001: 9002,
    9002: 9001,
    9011: 9012,
    9012: 9011,
}
DOOR_SPECIAL = 11
PORTAL_DOOR_ID = 9100


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
        if any(marker in raw.lower() for marker in (".", "e")):
            return float(raw)

        return int(raw)
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
        offset, size, raw_name = struct.unpack_from(
            "<II8s",
            data,
            directory_offset + index * 16,
        )

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
        return data[
            text_entry[1]:text_entry[1] + text_entry[2]
        ].decode("utf-8")
    except UnicodeDecodeError:
        fail("TEXTMAP is not UTF-8")


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
    door_lines = []
    portal_lines = []

    for linedef in linedefs:
        require_index(linedef.get("v1"), len(vertices), "v1")
        require_index(linedef.get("v2"), len(vertices), "v2")
        front_index = require_index(
            linedef.get("sidefront"),
            len(sidedefs),
            "sidefront",
        )
        front_sector = require_index(
            sidedefs[front_index].get("sector"),
            len(sectors),
            "front sector",
        )
        back_sector = None

        if linedef.get("twosided") is True:
            back_index = require_index(
                linedef.get("sideback"),
                len(sidedefs),
                "sideback",
            )
            back_sector = require_index(
                sidedefs[back_index].get("sector"),
                len(sectors),
                "back sector",
            )

            if front_sector == back_sector:
                fail("two-sided linedef connects a sector to itself")

            adjacency[front_sector].add(back_sector)
            adjacency[back_sector].add(front_sector)
        elif "sideback" in linedef:
            fail("one-sided linedef unexpectedly has a back side")

        if linedef.get("special") == 243:
            exit_lines.append(linedef)

        if linedef.get("special") == DOOR_SPECIAL:
            door_lines.append(linedef)

        if linedef.get("special") == PORTAL_SPECIAL:
            portal_lines.append((linedef, front_sector, back_sector))

    if len(exit_lines) != 1 or exit_lines[0].get("playeruse") is not True:
        fail("expected one player-use Exit_Normal linedef")

    if len(door_lines) != 1:
        fail("portal lab must have exactly one Door_Open gate")

    door = door_lines[0]
    if (
        door.get("playeruse") is not True
        or door.get("arg0") != PORTAL_DOOR_ID
        or door.get("arg1") != 16
    ):
        fail("portal lab Door_Open gate does not match the authored contract")

    door_sectors = [
        sector
        for sector in sectors
        if sector.get("id") == PORTAL_DOOR_ID
    ]
    if len(door_sectors) != 1:
        fail("portal lab must have exactly one tagged door sector")

    door_sector = door_sectors[0]
    if door_sector.get("heightceiling") != door_sector.get("heightfloor"):
        fail("portal lab door sector must start closed")

    if len(portal_lines) != 4 or stats.get("linked_portals") != 4:
        fail("TESTMAP must contain exactly two reciprocal linked-portal pairs")

    seen_ids = set()
    portal_by_id = {}

    for portal, front_sector, back_sector in portal_lines:
        line_id = portal.get("id")
        destination_id = portal.get("arg0")

        if line_id not in PORTAL_IDS or destination_id != PORTAL_IDS[line_id]:
            fail("TESTMAP linked portal IDs are not reciprocal")

        if portal.get("arg2") != PORTAL_TYPE_LINKED:
            fail("TESTMAP portal is not a linked portal")

        if portal.get("twosided") is not True or back_sector is None:
            fail("TESTMAP linked portal must have traversable space behind it")

        if line_id in portal_by_id:
            fail(f"duplicate TESTMAP linked portal ID: {line_id}")

        seen_ids.add(line_id)
        portal_by_id[line_id] = (front_sector, back_sector)

    if seen_ids != set(PORTAL_IDS):
        fail("TESTMAP linked portal pairs are incomplete")

    for line_id, destination_id in PORTAL_IDS.items():
        source_sectors = portal_by_id[line_id]
        destination_sectors = portal_by_id[destination_id]

        for source_sector in source_sectors:
            adjacency[source_sector].update(destination_sectors)

    if len(sectors) != stats["sectors"] or len(sectors) < 40:
        fail("systems-test sector budget is too small")

    visited = {0}
    queue = deque([0])

    while queue:
        current = queue.popleft()

        for neighbor in adjacency[current] - visited:
            visited.add(neighbor)
            queue.append(neighbor)

    if len(visited) != len(sectors):
        fail(
            "sector graph is disconnected even after linked-portal traversal: "
            f"reached {len(visited)} of {len(sectors)}"
        )

    floor_textures = {sector.get("texturefloor") for sector in sectors}
    ceiling_textures = {sector.get("textureceiling") for sector in sectors}
    light_levels = {sector.get("lightlevel") for sector in sectors}
    wall_textures = {
        sidedef.get("texturemiddle")
        for sidedef in sidedefs
        if sidedef.get("texturemiddle") not in (None, "-")
    }

    if len(floor_textures) < 5 or "NUKAGE1" not in floor_textures:
        fail("systems-test floor/material coverage is incomplete")

    if len(ceiling_textures) < 4 or "F_SKY1" not in ceiling_textures:
        fail("systems-test ceiling/sky coverage is incomplete")

    if len(light_levels) < 6:
        fail("systems-test lighting coverage is incomplete")

    if len(wall_textures) < 7:
        fail("systems-test wall texture coverage is incomplete")


def validate_things(things, stats):
    types = [thing.get("type") for thing in things]
    monster_count = sum(thing_type in MONSTER_TYPES for thing_type in types)
    decoration_count = sum(
        thing_type in DECORATION_TYPES
        for thing_type in types
    )

    if monster_count != 0 or stats.get("monsters") != 0:
        fail(f"TESTMAP must be monster-free, found {monster_count}")

    if decoration_count != stats["decorations"] or decoration_count < 120:
        fail(
            "decoration coverage mismatch: "
            f"expected at least 120, found {decoration_count}"
        )

    for player_start in (1, 2, 3, 4):
        if types.count(player_start) != 1:
            fail(f"expected exactly one player-{player_start} start")

    missing_weapons = sorted(REQUIRED_WEAPONS - set(types))

    if missing_weapons:
        fail(f"systems-test weapon coverage is incomplete: {missing_weapons}")

    if 2035 not in types:
        fail("systems-test map must contain explosive barrels")

    if not ({44, 45, 46, 55, 56, 57} & set(types)):
        fail("systems-test map must contain stock torch decorations")

    bounds = stats.get("bounds")

    if (
        not isinstance(bounds, list)
        or len(bounds) != 4
        or not all(isinstance(value, (int, float)) for value in bounds)
    ):
        fail("generated metadata has invalid map bounds")

    min_x, min_y, max_x, max_y = bounds

    for thing in things:
        x = thing.get("x")
        y = thing.get("y")

        if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
            fail("thing is missing numeric coordinates")

        if not (min_x <= x <= max_x and min_y <= y <= max_y):
            fail(f"thing is outside the systems-test bounds: ({x}, {y})")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, required=True)
    args = parser.parse_args()

    textmap = read_wad(args.directory / "E1M1.wad")
    stats = json.loads(
        (args.directory / "stats.json").read_text(encoding="utf-8")
    )
    blocks = {
        kind: parse_blocks(textmap, kind)
        for kind in BLOCK_KINDS
    }

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

    if (
        stats.get("map") != "E1M1"
        or stats.get("title") != "TESTMAP"
        or stats.get("version") != "0.4.0"
        or stats.get("testbed_contract") != 1
        or stats.get("geometry_contract") != 1
        or stats.get("rooms", 0) < 10
        or stats.get("weapons") != len(REQUIRED_WEAPONS)
    ):
        fail("generated metadata does not match the v0.4.0 TESTMAP contract")

    validate_geometry(blocks, stats)
    validate_things(blocks["thing"], stats)
    print(json.dumps(stats, sort_keys=True))


if __name__ == "__main__":
    main()

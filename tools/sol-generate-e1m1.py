#!/usr/bin/env python3
"""Generate SOL!'s deterministic E1M1 TESTMAP PWAD without IWAD data."""

import argparse
import hashlib
import json
import struct

from pathlib import Path


CELL = 512

CELLS = {
    (0, 3): "Arrival",
    (1, 3): "Security",
    (1, 4): "Phase Room",
    (1, 5): "Phase Room",
    (2, 2): "Atrium",
    (2, 3): "Atrium",
    (2, 4): "Atrium",
    (3, 2): "Atrium",
    (3, 3): "Atrium",
    (3, 4): "Atrium",
    (3, 1): "Storage",
    (4, 1): "Storage",
    (5, 1): "Service",
    (5, 2): "Service",
    (4, 3): "Control",
    (5, 3): "Control",
    (6, 2): "Control",
    (6, 3): "Control",
    (3, 5): "Laboratory",
    (4, 5): "Laboratory",
    (5, 5): "Laboratory",
    (5, 6): "Laboratory",
    (6, 6): "Laboratory",
    (6, 4): "Reactor",
    (6, 5): "Reactor",
    (7, 4): "Reactor",
    (7, 5): "Reactor",
    (7, 2): "Courtyard",
    (7, 3): "Courtyard",
    (8, 2): "Courtyard",
    (8, 3): "Courtyard",
    (8, 4): "Courtyard",
    (9, 2): "Courtyard",
    (9, 3): "Courtyard",
    (9, 4): "Courtyard",
    (9, 5): "Exit",
    (10, 5): "Exit",
    (10, 4): "Exit",
    (3, 6): "Portal Door",
    (3, 7): "Portal Lab",
    (4, 7): "Portal Lab",
    (0, 8): "Portal Lab",
    (1, 8): "Portal Lab",
}

THEMES = {
    "Arrival": ("STARTAN3", "FLOOR4_8", "CEIL3_5", 176, 0, 144),
    "Security": ("STARGR2", "FLOOR4_6", "CEIL3_5", 160, 0, 144),
    "Phase Room": ("METAL2", "FLOOR4_8", "CEIL3_5", 128, 0, 144),
    "Atrium": ("BROWN1", "FLOOR5_1", "CEIL5_1", 192, 0, 224),
    "Storage": ("GRAY1", "FLOOR4_8", "CEIL3_5", 128, 8, 136),
    "Service": ("ICKWALL1", "NUKAGE1", "CEIL1_1", 96, 0, 128),
    "Control": ("COMPSPAN", "FLOOR4_6", "CEIL5_1", 176, 16, 176),
    "Laboratory": ("TEKWALL1", "FLAT14", "CEIL5_1", 208, 0, 160),
    "Reactor": ("METAL1", "NUKAGE1", "CEIL5_1", 112, -8, 192),
    "Courtyard": ("STONE2", "FLAT14", "F_SKY1", 224, 0, 256),
    "Exit": ("STARTAN3", "FLOOR4_8", "CEIL3_5", 160, 0, 144),
    "Portal Door": ("DOOR3", "FLAT14", "CEIL5_1", 144, 0, 0),
    "Portal Lab": ("TEKWALL4", "FLAT14", "CEIL5_1", 192, 0, 160),
}

WEAPON_TYPES = (2001, 2002, 2003, 2004, 2005, 2006)
DECORATION_TYPES = (2035, 34, 35, 44, 45, 46, 55, 56, 57, 15, 18, 19, 20, 21, 22)

EXIT_CELL = (10, 4)
EXIT_EDGE = "east"

PORTAL_TYPE_TELEPORT = 1
PORTAL_TYPE_LINKED = 3
PORTAL_SPECIAL = 156
DOOR_SPECIAL = 11
PORTAL_DOOR_CELL = (3, 6)
PORTAL_DOOR_ID = 9100
PORTAL_DOOR_TRIGGER = frozenset(((3, 5), PORTAL_DOOR_CELL))
PHASE_PORTAL_LINES = {
    # The source is the physical entrance to a genuinely local dead-end room.
    # It is deliberately oriented with the illusion-room interior on side 0 so
    # the stock teleport portal's front-to-back traversal matches the revealed
    # interior-to-exterior exit direction.
    frozenset(((1, 3), (1, 4))): {
        "id": 9001,
        "destination": 9002,
        "reverse": True,
        "role": "source",
        "group": 1,
        "inside_side": 0,
        "arm_depth": 384.0,
        "entry_dot": 0.2,
        "reveal_dot": 0.3,
    },
    # This is only an ordinary local doorway until a source-side phase portal
    # is revealed. It never points back at the phase room.
    frozenset(((8, 3), (9, 3))): {
        "id": 9002,
        "destination": 0,
        "reverse": False,
        "role": "destination",
        "group": 1,
    },
}

LINKED_PORTAL_LINES = {
    frozenset(((3, 7), (4, 7))): (9011, 9012, False),
    frozenset(((0, 8), (1, 8))): (9012, 9011, True),
}


def block(kind, values):
    lines = [kind, "{"]

    for key, value in values:
        if isinstance(value, str):
            lines.append(f'    {key} = "{value}";')
        elif isinstance(value, bool):
            lines.append(f"    {key} = {'true' if value else 'false'};")
        elif isinstance(value, float):
            lines.append(f"    {key} = {value:.1f};")
        else:
            lines.append(f"    {key} = {value};")

    lines.append("}\n")
    return "\n".join(lines)


def cell_edges(gx, gy):
    x = gx * CELL
    y = gy * CELL

    return (
        ("south", (x + CELL, y), (x, y)),
        ("west", (x, y), (x, y + CELL)),
        ("north", (x, y + CELL), (x + CELL, y + CELL)),
        ("east", (x + CELL, y + CELL), (x + CELL, y)),
    )


def make_geometry():
    sectors = []
    edges = {}

    ordered_cells = sorted(CELLS, key=lambda point: (point[1], point[0]))
    sector_by_cell = {cell: index for index, cell in enumerate(ordered_cells)}

    for cell in ordered_cells:
        theme_name = CELLS[cell]
        wall, floor, ceiling, light, floor_height, ceiling_height = THEMES[theme_name]
        sectors.append({
            "cell": cell,
            "name": theme_name,
            "wall": wall,
            "floor": floor,
            "ceiling": ceiling,
            "light": light,
            "floor_height": floor_height,
            "ceiling_height": ceiling_height,
            "id": PORTAL_DOOR_ID if cell == PORTAL_DOOR_CELL else None,
        })

        gx, gy = cell
        for edge_name, p1, p2 in cell_edges(gx, gy):
            key = tuple(sorted((p1, p2)))
            edges.setdefault(key, []).append({
                "sector": sector_by_cell[cell],
                "edge_name": edge_name,
                "p1": p1,
                "p2": p2,
                "wall": wall,
                "cell": cell,
            })

    vertices = []
    vertex_lookup = {}

    def vertex(point):
        if point not in vertex_lookup:
            vertex_lookup[point] = len(vertices)
            vertices.append(point)
        return vertex_lookup[point]

    sidedefs = []
    linedefs = []

    def side(sector, top="-", bottom="-", middle="-"):
        index = len(sidedefs)
        sidedefs.append({
            "sector": sector,
            "texturetop": top,
            "texturebottom": bottom,
            "texturemiddle": middle,
        })
        return index

    for key in sorted(edges):
        owners = edges[key]

        if len(owners) == 2:
            first, second = owners
            front = side(first["sector"], first["wall"], first["wall"], "-")
            back = side(second["sector"], second["wall"], second["wall"], "-")
            v1 = vertex(first["p1"])
            v2 = vertex(first["p2"])
            cell_pair = frozenset((first["cell"], second["cell"]))
            phase_portal = PHASE_PORTAL_LINES.get(cell_pair)
            linked_portal = LINKED_PORTAL_LINES.get(cell_pair)
            is_portal_door_trigger = cell_pair == PORTAL_DOOR_TRIGGER

            linedef = {
                "v1": v1,
                "v2": v2,
                "sidefront": front,
                "sideback": back,
                "twosided": True,
            }

            if is_portal_door_trigger:
                linedef.update({
                    "special": DOOR_SPECIAL,
                    "arg0": PORTAL_DOOR_ID,
                    "arg1": 16,
                    "arg2": 0,
                    "playeruse": True,
                })

            if phase_portal is not None:
                if phase_portal["reverse"]:
                    linedef["v1"], linedef["v2"] = linedef["v2"], linedef["v1"]
                    linedef["sidefront"], linedef["sideback"] = linedef["sideback"], linedef["sidefront"]
                linedef.update({
                    "id": phase_portal["id"],
                    "special": PORTAL_SPECIAL,
                    "arg0": phase_portal["destination"],
                    "arg1": 0,
                    "arg2": PORTAL_TYPE_TELEPORT,
                    "arg3": 0,
                    "arg4": 0,
                    "user_sol_phase_role": phase_portal["role"],
                    "user_sol_phase_group": phase_portal["group"],
                })
                if phase_portal["role"] == "source":
                    linedef.update({
                        "user_sol_phase_inside_side": phase_portal["inside_side"],
                        "user_sol_phase_arm_depth": phase_portal["arm_depth"],
                        "user_sol_phase_entry_dot": phase_portal["entry_dot"],
                        "user_sol_phase_reveal_dot": phase_portal["reveal_dot"],
                    })

            if linked_portal is not None:
                line_id, destination_id, reverse = linked_portal
                if reverse:
                    linedef["v1"], linedef["v2"] = linedef["v2"], linedef["v1"]
                    linedef["sidefront"], linedef["sideback"] = linedef["sideback"], linedef["sidefront"]
                linedef.update({
                    "id": line_id,
                    "special": PORTAL_SPECIAL,
                    "arg0": destination_id,
                    "arg1": 0,
                    "arg2": PORTAL_TYPE_LINKED,
                    "arg3": 0,
                    "arg4": 0,
                })

            linedefs.append(linedef)
            continue

        if len(owners) != 1:
            raise RuntimeError(f"non-manifold testbed edge: {key}")

        owner = owners[0]
        is_exit = owner["cell"] == EXIT_CELL and owner["edge_name"] == EXIT_EDGE
        middle = "SW1COMP" if is_exit else owner["wall"]
        front = side(owner["sector"], "-", "-", middle)
        linedef = {
            "v1": vertex(owner["p1"]),
            "v2": vertex(owner["p2"]),
            "sidefront": front,
        }

        if is_exit:
            linedef["special"] = 243
            linedef["playeruse"] = True

        linedefs.append(linedef)

    return ordered_cells, sectors, vertices, sidedefs, linedefs


def add_thing(things, x, y, thing_type, angle=0):
    things.append({
        "x": float(x),
        "y": float(y),
        "angle": angle,
        "type": thing_type,
    })


def make_things(ordered_cells):
    things = []

    # Player 1 begins in the ordinary Arrival staging area, outside the source
    # span and arm-depth region. Multiplayer starts stay beside it.
    add_thing(things, 256, 3 * CELL + 256, 1, 0)
    add_thing(things, 208, 3 * CELL + 208, 2, 0)
    add_thing(things, 208, 3 * CELL + 304, 3, 0)
    add_thing(things, 304, 3 * CELL + 256, 4, 0)

    weapon_cells = (
        ((1, 3), 2001),
        ((3, 1), 2002),
        ((4, 5), 2005),
        ((6, 4), 2003),
        ((8, 3), 2004),
        ((10, 5), 2006),
    )
    for (gx, gy), thing_type in weapon_cells:
        add_thing(things, gx * CELL + 256, gy * CELL + 256, thing_type)

    supply_types = (2007, 2008, 2010, 2047, 2011, 2012, 2014, 2015, 2018, 2019, 2023, 2013)
    for index, (gx, gy) in enumerate(ordered_cells):
        if index % 2 == 0:
            add_thing(
                things,
                gx * CELL + 128,
                gy * CELL + 128,
                supply_types[index % len(supply_types)],
                (index * 29) % 360,
            )

    decoration_count = 0
    for index, (gx, gy) in enumerate(ordered_cells):
        decoration_types = (
            2035,
            DECORATION_TYPES[(index + 3) % len(DECORATION_TYPES)],
            DECORATION_TYPES[(index + 8) % len(DECORATION_TYPES)],
        )
        decoration_positions = ((96, 416), (416, 96), (416, 416))

        for slot, thing_type in enumerate(decoration_types):
            dx, dy = decoration_positions[slot]
            add_thing(
                things,
                gx * CELL + dx,
                gy * CELL + dy,
                thing_type,
                (index * 19 + slot * 90) % 360,
            )
            decoration_count += 1

    return things, decoration_count


def make_textmap():
    ordered_cells, sectors, vertices, sidedefs, linedefs = make_geometry()
    things, decoration_count = make_things(ordered_cells)
    out = ['namespace = "ZDoom";\n']

    for x, y in vertices:
        out.append(block("vertex", [("x", float(x)), ("y", float(y))]))

    for sidedef in sidedefs:
        out.append(block("sidedef", list(sidedef.items())))

    for linedef in linedefs:
        out.append(block("linedef", list(linedef.items())))

    for index, sector in enumerate(sectors):
        gx, gy = sector["cell"]
        out.append(f'// sector {index}: {sector["name"]} cell {gx},{gy}\n')
        values = [
            ("heightfloor", sector["floor_height"]),
            ("heightceiling", sector["ceiling_height"]),
            ("texturefloor", sector["floor"]),
            ("textureceiling", sector["ceiling"]),
            ("lightlevel", sector["light"]),
        ]
        if sector["id"] is not None:
            values.append(("id", sector["id"]))
        out.append(block("sector", values))

    for thing in things:
        values = list(thing.items())
        values.extend([
            ("skill1", True),
            ("skill2", True),
            ("skill3", True),
            ("skill4", True),
            ("skill5", True),
            ("single", True),
            ("coop", True),
        ])
        out.append(block("thing", values))

    min_x = min(x for x, _ in ordered_cells) * CELL
    min_y = min(y for _, y in ordered_cells) * CELL
    max_x = (max(x for x, _ in ordered_cells) + 1) * CELL
    max_y = (max(y for _, y in ordered_cells) + 1) * CELL

    stats = {
        "map": "E1M1",
        "title": "TESTMAP",
        "version": "0.4.0",
        "testbed_contract": 1,
        "geometry_contract": 1,
        "bounds": [min_x, min_y, max_x, max_y],
        "vertices": len(vertices),
        "linedefs": len(linedefs),
        "sidedefs": len(sidedefs),
        "sectors": len(sectors),
        "things": len(things),
        "monsters": 0,
        "decorations": decoration_count,
        "weapons": len(WEAPON_TYPES),
        "rooms": len(set(CELLS.values())),
        "linked_portals": len(LINKED_PORTAL_LINES),
        "phase_portal_sources": 1,
        "phase_portal_anchors": 1,
    }

    return "\n".join(out).encode(), stats


def wad(textmap):
    lumps = [(b"E1M1", b""), (b"TEXTMAP", textmap), (b"ENDMAP", b"")]
    data = bytearray(b"PWAD" + struct.pack("<II", len(lumps), 0))
    entries = []

    for name, content in lumps:
        entries.append((len(data), len(content), name))
        data.extend(content)

    directory = len(data)
    for offset, size, name in entries:
        data.extend(struct.pack("<II8s", offset, size, name.ljust(8, b"\0")))

    struct.pack_into("<I", data, 8, directory)
    return bytes(data)


def svg():
    cells = sorted(CELLS, key=lambda point: (point[1], point[0]))
    scale = 72
    margin = 24
    max_x = max(x for x, _ in cells)
    max_y = max(y for _, y in cells)
    width = (max_x + 1) * scale + margin * 2
    height = (max_y + 1) * scale + margin * 2
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#15191c"/>',
    ]

    for gx, gy in cells:
        room = CELLS[(gx, gy)]
        x = margin + gx * scale
        y = margin + (max_y - gy) * scale
        parts.append(
            f'<rect x="{x}" y="{y}" width="{scale}" height="{scale}" '
            'fill="#59656a" stroke="#d7e8df" stroke-width="2"/>'
        )
        parts.append(
            f'<text x="{x + scale / 2}" y="{y + scale / 2}" '
            'text-anchor="middle" dominant-baseline="middle" fill="white" '
            f'font-family="sans-serif" font-size="9">{room}</text>'
        )

    parts.append("</svg>\n")
    return "".join(parts).encode()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    textmap, stats = make_textmap()
    outputs = {
        "TEXTMAP.txt": textmap,
        "E1M1.wad": wad(textmap),
        "stats.json": (json.dumps(stats, indent=2, sort_keys=True) + "\n").encode(),
        "layout.svg": svg(),
    }

    for name, content in outputs.items():
        (args.output / name).write_bytes(content)

    print(args.output / "E1M1.wad", hashlib.sha256(outputs["E1M1.wad"]).hexdigest())


if __name__ == "__main__":
    main()

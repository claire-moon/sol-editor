#!/usr/bin/env python3
"""Generate SOL's deterministic E1M1 UDMF graybox without IWAD data."""
import argparse, hashlib, json, struct
from pathlib import Path

NAMES = [
    "Arrival Lock", "Arrival Connector", "Hangar Floor", "Security Connector",
    "Security Spine", "Maintenance Descent", "Processing / Maintenance",
    "Reactor Connector", "Reactor Annex", "Exterior Airlock", "Exterior Breach",
    "Command Lift", "Command Return", "Transition Seam",
]
WIDTH = 512
HEIGHT = 512
MONSTER_TYPES = [3004, 9, 3001, 3002]


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


def make_textmap():
    out = ['namespace = "ZDoom";\n']
    for x in range(0, (len(NAMES) + 1) * WIDTH, WIDTH):
        out.append(block("vertex", [("x", float(x)), ("y", 0.0)]))
        out.append(block("vertex", [("x", float(x)), ("y", float(HEIGHT))]))

    sidedefs = []
    linedefs = []
    def side(sector, middle="-"):
        index = len(sidedefs)
        sidedefs.append((sector, middle))
        return index

    for room in range(len(NAMES)):
        left = room * 2
        right = (room + 1) * 2
        for v1, v2 in ((left, right), (right + 1, left + 1)):
            linedefs.append((v1, v2, side(room, "STARTAN3"), -1, 0, False))

    linedefs.append((1, 0, side(0, "STARTAN3"), -1, 0, False))
    for room in range(1, len(NAMES)):
        bottom = room * 2
        top = bottom + 1
        linedefs.append((bottom, top, side(room - 1), side(room), 0, False))
    end_bottom = len(NAMES) * 2
    end_top = end_bottom + 1
    linedefs.append((end_bottom, end_top, side(len(NAMES) - 1, "SW1COMP"), -1, 243, True))

    for sector, middle in sidedefs:
        out.append(block("sidedef", [
            ("sector", sector), ("texturetop", "-"),
            ("texturebottom", "-"), ("texturemiddle", middle),
        ]))
    for v1, v2, front, back, special, use in linedefs:
        values = [("v1", v1), ("v2", v2), ("sidefront", front)]
        if back >= 0:
            values += [("sideback", back), ("twosided", True)]
        if special:
            values += [("special", special), ("playeruse", use)]
        out.append(block("linedef", values))
    for index, name in enumerate(NAMES):
        out.append(f"// sector {index}: {name}\n")
        out.append(block("sector", [
            ("heightfloor", 0), ("heightceiling", 160 if index not in (2, 8, 10) else 224),
            ("texturefloor", "FLOOR4_8"), ("textureceiling", "CEIL3_5"),
            ("lightlevel", 144 if index % 3 else 176),
        ]))

    things = [
        (64, 256, 1, 0),
        (640, 256, 2001, 0),
        (1664, 256, 2002, 0),
    ]
    for i in range(176):
        room = i % len(NAMES)
        slot = i // len(NAMES)
        x = room * WIDTH + 96 + (slot % 4) * 96
        y = 72 + ((slot // 4) % 4) * 112
        things.append((x, y, MONSTER_TYPES[(room + slot) % len(MONSTER_TYPES)], (i * 37) % 360))
    for room in range(1, len(NAMES), 2):
        things.append((room * WIDTH + 256, 96, 2011, 0))
        things.append((room * WIDTH + 256, 416, 2007, 0))
    for x, y, thing_type, angle in things:
        out.append(block("thing", [
            ("x", float(x)), ("y", float(y)), ("angle", angle), ("type", thing_type),
            ("skill1", True), ("skill2", True), ("skill3", True),
            ("skill4", True), ("skill5", True), ("single", True), ("coop", True),
        ]))
    stats = {
        "map": "E1M1", "version": "0.1.0-dev", "vertices": 30,
        "linedefs": len(linedefs), "sidedefs": len(sidedefs), "sectors": 14,
        "things": len(things), "monsters": 176,
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
    width = len(NAMES) * 150
    boxes = []
    for i, name in enumerate(NAMES):
        x = i * 150
        boxes.append(f'<rect x="{x}" y="20" width="140" height="80" fill="#59656a" stroke="#d7e8df"/>')
        boxes.append(f'<text x="{x+70}" y="58" text-anchor="middle" fill="white" font-size="11">{name}</text>')
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="120">%s</svg>\n' % (width, ''.join(boxes))).encode()


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

# SOL locked wadpack

SOL v0.1.0 uses a fixed resource stack to establish the intended visual, audio,
movement, gore, lighting, ambience, targeting, crosshair, and HUD baseline. The
order is part of the game contract and must not be rearranged during normal
playtests.

## Load order

1. Voxel Doom 2.4
2. Universal Weapon Sway
3. Troo Cullers 2.5
4. Tilt++
5. Relighting 0.7.3b
6. Angled Doom Lite 1.2.1
7. NashGore NEXT
8. NashGore official voxels
9. Final Custom Doom 1.0.0 beta
10. Vanilla Essence 4.3
11. HQ PSX music
12. PlayStation sound effects
13. Flashlight++ 9.1
14. WW Alpha HUD
15. Universal Ambience
16. CosmoAmbience Script edited
17. Ambient decorations
18. TargetSpy v3.1.0
19. Precise Crosshair v1.5.0

Wadpack contract 2 added entries 15–18 after the original fourteen so the earlier
resource precedence stayed unchanged. Wadpack contract 3 preserves entries 1–18
and appends Precise Crosshair v1.5.0 at entry 19. All nineteen entries are
required.

## Build-time import

```bash
bash tools/sol-wadpack-setup.sh
```

The setup program searches `vend`, the SOL workspace, Downloads, Desktop, and
Documents. When files remain missing, it opens an isolated Midnight Commander
selector. Highlight the folder containing the files, press `F2`, choose `W`,
review the import, and press `F10`.

The importer writes:

- `vend/wadpack/source/`: preserved local source archives.
- `vend/wadpack/runtime/`: normalized, numbered runtime files.
- `vend/wadpack/lock.json`: source and runtime hashes.
- `vend/wadpack/load-order.txt`: ordered build-input paths.

Wrapper archives are normalized before bundling:

- Universal Weapon Sway has its single repository root removed.
- `nashgore_next.zip` contributes the nested `nashgore.pk3`.
- `PSSFX.zip` contributes `PSSFX.wad`.
- Flashlight++ contributes its nested PK3 through 7-Zip.
- HQ PSX music contributes its nested WAD.

The contract-2 additions are direct PK3 copies with exact source hashes:

- `1 Universal Ambience.pk3`: `b739009ac26576f028bb833985b44b375213563bdc8e8c8bd3f2ee182fdd0e35`
- `2 CosmoAmbience Script edited.pk3`: `b1dc50a069433e2fa5feb6aa63d45ffb9e4c2a8989389fc026e0b44b01e01d36`
- `3 Ambient decorations.pk3`: `96b652aea1883c38e22797578280804f8a4557c7aa5c48cacdba45351413eb8b`
- `TargetSpy-v3.1.0.pk3`: `6cdafe4af382f76071150a9c4f39b61597f22cf7098a02837cc1b6a81808e128`

Contract 3 accepts the user-supplied Precise Crosshair v1.5.0 package under any
of these source names:

- `PreciseCrosshair-v1.5.0.pk3`
- `PreciseCrosshair-1.5.0.pk3`
- `PreciseCrosshair.pk3`

The public DoomToolbox source directly identifies v1.5.0 and GPL-3.0-only. SOL
does not invent a binary package hash: the manifest leaves its source hash
unpinned until import, then `lock.json` records the exact supplied source and
normalized runtime SHA-256 values.

## Single runtime package

After all nineteen resources are present, build the final runtime:

```bash
bash tools/sol-package.sh
```

The result is:

```text
build/sol/sol.pk3
```

Bundle contract 1 stores every component byte-for-byte under a numbered
root-level `.wad` carrier:

```text
sol.pk3
├── SOLPACK.json
├── THIRD_PARTY.md
├── 01-voxel-doom.wad
├── 02-universal-weapon-sway.wad
├── 03-troo-cullers.wad
├── ...
├── 18-targetspy.wad
├── 19-precise-crosshair.wad
├── 20-sol-runtime.wad
└── 21-sol-content.wad
```

The `.wad` suffix is a carrier convention, not a file-format conversion. For
example, the bytes stored under `01-voxel-doom.wad` remain the normalized Voxel
Doom PK3 bytes.

This convention deliberately uses UZDoom's existing native embedded-resource
behavior. Its filesystem marks root-level archive members ending in `.wad` as
embedded, opens each one by content, and recursively adds it as a resource file.
Because the carrier names begin with fixed-width numbers, UZDoom's normal ZIP
sorting produces the same 01→21 precedence as loading the original resources
separately.

Therefore normal gameplay and editor playtests pass exactly one resource file:

```text
-file sol.pk3
```

No gameplay extraction layer is required. This also avoids destructive
flattening: identically named `ZSCRIPT`, `MAPINFO`, `DECORATE`, `MENUDEF`, sprite,
or sound paths remain isolated in their original child archives until UZDoom
mounts them in order.

`SOLPACK.json` records each carrier name, original materialized filename,
component kind, source identity, distribution status, and SHA-256. The verifier
checks the complete member set and every child hash before launch.

## Editor authoring

Ultimate Doom Builder needs direct resource paths for its authoring data set, so
`sol-edit` materializes only wadpack entries 1–19 from `sol.pk3` into a cache
keyed by the complete bundle hash. Those files are exposed to UDB in-memory and
are not written over the user's normal resource configuration.

In-editor playtests do not use the materialized copies. The test wrapper passes
`sol.pk3` once and lets UDB's temporary map/resource arguments follow it, so the
temporary map retains final precedence.

Once `sol.pk3` exists and verifies against the current contracts, the loose
`vend/wadpack/runtime` files are no longer a normal gameplay/editor-test runtime
dependency. They remain build inputs for regenerating the bundle.

## Package placement

A successful bundle build copies the same `sol.pk3` into:

- `sol-editor/build/sol/sol.pk3`
- `sol-editor/Build/sol.pk3` when the editor has been built
- `sol-engine/build/sol/sol.pk3`
- `sol-engine/build/sol-local/sol.pk3` for the default local engine build
- the directories containing configured `SOL_ENGINE` and `SOL_EDITOR`
  executables when available

The local engine build helper also installs `sol-engine` beside the UZDoom
binary. That launcher requires/loads the adjacent `sol.pk3` automatically and
uses `DOOM_IWAD` when supplied; otherwise UZDoom keeps its normal IWAD picker.

The engine-side `tools/sol-package.sh` converges on the same final bundle when
the sibling editor and complete wadpack are available. During first-run setup it
can still emit the small SOL-owned runtime component so workspace initialization
is not blocked before third-party import.

## Attribution and licensing

`THIRD_PARTY.md` is committed in both SOL repositories and embedded in
`sol.pk3`. Upstream archive bytes are preserved intact, including license/readme
files contained by those archives.

Precise Crosshair v1.5.0 is part of DoomToolbox and declares GPL-3.0-only and ©
2019 Alexander Kromm. Its source file explicitly records v1.5.0 and the v1.5.0
changelog. The supplied PK3 stays local and is hash-locked when imported.

The Universal Ambience distribution page identifies Universal Ambience, Cosmo
ambience, and Ambient decorations as one numbered package and labels the package
GPL. Its published credits include McTed, Heydoomer, Agent Ash, Boondorl,
Dr_Cosmobyte, and several external sound sources. Because externally sourced
audio may have separate terms, entries 15–17 retain an asset-level review
requirement. Entry 16 is also a supplied edited variant, so its exact hash and
modification provenance must remain recorded.

TargetSpy v3.1.0 declares GPL-3.0-only and © 2026 Alexander Kromm. The full
source/credit inventory is in `THIRD_PARTY.md` and `sol-project/wadpack.json`.

Attribution does not itself grant redistribution rights. Several components still
require asset/license review, and HQ PlayStation music/sound effects remain
local-only proprietary audio. The complete `sol.pk3` may be generated and copied
into local SOL engine/editor packages for development and testing, but it must
not be committed to this public repository or attached to a public release until
the third-party redistribution audit is complete.

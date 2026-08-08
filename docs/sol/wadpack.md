# SOL locked wadpack

SOL v0.1.0 uses a fixed resource stack to establish the intended visual, audio,
movement, gore, lighting, ambience, targeting, and HUD baseline. The order is
part of the game contract and must not be rearranged during normal playtests.

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

Entries 15–18 are appended after the original fourteen so the earlier resource
precedence remains unchanged. Wadpack contract 2 requires all eighteen entries.

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

The four contract-2 additions are direct PK3 copies with exact source hashes:

- `1 Universal Ambience.pk3`: `b739009ac26576f028bb833985b44b375213563bdc8e8c8bd3f2ee182fdd0e35`
- `2 CosmoAmbience Script edited.pk3`: `b1dc50a069433e2fa5feb6aa63d45ffb9e4c2a8989389fc026e0b44b01e01d36`
- `3 Ambient decorations.pk3`: `96b652aea1883c38e22797578280804f8a4557c7aa5c48cacdba45351413eb8b`
- `TargetSpy-v3.1.0.pk3`: `6cdafe4af382f76071150a9c4f39b61597f22cf7098a02837cc1b6a81808e128`

## Single runtime package

After the eighteen resources are present, build the final runtime:

```bash
bash tools/sol-package.sh
```

The result is:

```text
build/sol/sol.pk3
```

Bundle contract 1 stores the normalized resources as intact child archives:

```text
sol.pk3
├── SOLPACK.json
├── THIRD_PARTY.md
└── components/
    ├── 01-voxel-doom-v2.4.pk3
    ├── 02-universal-weapon-sway.pk3
    ├── ...
    ├── 18-targetspy-v3.1.0.pk3
    ├── 19-sol-runtime.pk3
    └── 20-sol-content.pk3
```

The third-party archives are deliberately not flattened into one ZIP namespace.
Many Doom mods define identically named root resources such as `ZSCRIPT`,
`MAPINFO`, `DECORATE`, `MENUDEF`, sprites, or sounds. Flattening would silently
replace earlier files and change or break behavior. The SOL bundle instead keeps
each archive intact and records its SHA-256 in `SOLPACK.json`.

`tools/sol-bundle.py` verifies every embedded member before launch and
materializes the child archives into a cache keyed by the complete `sol.pk3`
hash. Normal play mounts entries 1–20 in order. Editor authoring materializes
entries 1–18, and editor test runs mount entries 1–19 before UDB's temporary map.

Once `sol.pk3` exists and matches the current bundle/wadpack contracts, it is a
self-contained runtime. The loose `vend/wadpack/runtime` files are no longer
needed for normal play or editor loading; they remain useful as build inputs when
regenerating the bundle.

## Package placement

A successful bundle build copies the same `sol.pk3` into:

- `sol-editor/build/sol/sol.pk3`
- `sol-editor/Build/sol.pk3` when the editor has been built
- `sol-engine/build/sol/sol.pk3`
- `sol-engine/build/sol-local/sol.pk3` for the default local engine build
- the directories containing the configured `SOL_ENGINE` and `SOL_EDITOR`
  executables when those paths are available

The engine-side `tools/sol-package.sh` attempts to produce this final bundle when
the sibling editor and complete wadpack are available. During first-run setup it
can still emit the SOL-owned runtime component so workspace initialization is not
blocked before the third-party import step.

## Attribution and licensing

`THIRD_PARTY.md` is committed in both SOL repositories and embedded in
`sol.pk3`. Upstream WAD/PK3 archives are preserved intact, including license or
readme files contained by those archives.

This records attribution and provenance but does not grant redistribution rights.
The three ambience additions remain `review-required`; TargetSpy v3.1.0 is
recorded as GPL-3.0-only; several other components still require license review;
and the HQ PlayStation music/sound effects are recorded as local-only
proprietary audio.

Therefore the complete `sol.pk3` may be generated and copied into local SOL
engine/editor packages for development and testing, but it must not be committed
to the public repository or attached to a public release until the third-party
redistribution audit is complete. The SOL project license does not relicense the
embedded third-party content.

# SOL locked wadpack

SOL v0.1.0 uses a fixed local resource stack to establish the intended visual,
audio, movement, gore, lighting, ambience, targeting, and HUD baseline. The
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

Entries 15–18 are the ambience/targeting extension added after the initial
v0.1.0 release cut. They are appended in this order so the original fourteen
resource precedence remains unchanged. Wadpack contract 2 requires all eighteen
entries.

The locked third-party resources load first. SOL's runtime package and current
map package load afterward so project-owned fixes can override the baseline.

## Local installation

```bash
bash tools/sol-wadpack-setup.sh
```

The setup program searches `vend`, the SOL workspace, Downloads, Desktop, and
Documents. When files remain missing, it opens an isolated Midnight Commander
selector. Highlight the folder containing the files, press `F2`, then choose
`W` to import and normalize every recognized item in that folder.

The importer writes:

- `vend/wadpack/source/`: preserved local source archives.
- `vend/wadpack/runtime/`: normalized, numbered runtime files.
- `vend/wadpack/lock.json`: source and runtime hashes.
- `vend/wadpack/load-order.txt`: absolute ordered runtime paths.

Wrapper archives are normalized rather than passed blindly to UZDoom:

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

## Editor and launch integration

`sol-play` verifies the lock, rebuilds the SOL runtime package, and supplies the
eighteen ordered files on every launch. It refuses to start when the pack is
missing or changed.

`sol-edit` verifies the same lock and exports both the active load-order file and
the stable editor test-engine wrapper:

```text
tools/sol-editor-engine.sh
```

While SOL Editor is running through `sol-edit`, the editor reads
`SOL_WADPACK_LOAD_ORDER` and adds the eighteen locked WAD/PK3 files to its
in-memory resource list in manifest order. Their textures, sprites, actors, and
other definitions are therefore available during authoring without manually
adding the pack to each map configuration. These injected entries are marked
not-for-testing, so UDB does not duplicate them in its generated command line.
They are not written into the user's normal Ultimate Doom Builder resource
configuration.

The test launcher separately reads `SOL_EDITOR_TEST_ENGINE` and temporarily
routes map tests through the wrapper. The user's normal Ultimate Doom Builder
test-engine setting is left unchanged on disk. The wrapper is the single
runtime injection point for the locked wadpack and SOL runtime before UDB's
temporary map arguments.

`sol-project/.udb/sol-wadpack.resources.txt` is also regenerated from the active
lock for inspection and tooling.

## Distribution and licensing

The public repositories contain only the manifest, expected source hashes,
normalizer, lock format, tests, and documentation. Third-party binaries remain
under the user's local `vend` directory.

The three ambience additions do not include license/readme metadata in the
supplied PK3 files and are therefore marked `review-required`. TargetSpy v3.1.0
identifies its main project license as GPL-3.0-only and also carries its bundled
license notices. This does not change the local-only policy for the SOL wadpack.

Several existing entries contain proprietary Doom/PlayStation-derived data or
have licenses that require further review. They must not be embedded in a
public SOL binary or release archive until every component has a recorded
redistribution basis. Literal executable embedding is deferred until that audit
and the final resource tuning pass are complete.

The current manifest records known source hashes. HQ PSX music is intentionally
unlocked until the exact selected archive is supplied and recorded.

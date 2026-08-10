# SOL wadpack consumption

Beginning with SOL Engine v0.4.0, `sol-editor` no longer owns the canonical
wadpack manifest, importer/locker, final `sol.pk3` builder, or provenance table.
Those live in the sibling `sol-engine` repository.

## Authoritative v0.4 files

```text
sol-engine/sol/wadpack.json
sol-engine/tools/sol-wadpack.py
sol-engine/tools/sol-wadpack-setup.sh
sol-engine/tools/sol-bundle.py
sol-engine/tools/sol-bundle.sh
sol-engine/THIRD_PARTY.md
```

The editor retains compatibility entry points with the same familiar names, but
they delegate to those engine-owned tools. `sol-project/wadpack.json` is now a
deprecation pointer and must not be edited as a resource contract.

## Wadpack contract 3

Twenty logical wadpack slots are defined:

```text
01–10  active
11     retired — HQ PSX music
12–18  active
19     active — PreciseCrosshair v1.5.0
20     reserved
```

There are eighteen active resources. The retired/reserved slots remain visible
in metadata but are not materialized or mounted.

SOL-owned runtime/content occupy slots 21 and 22 under bundle contract 2.

## Local setup

From the editor checkout:

```bash
bash tools/sol-wadpack-setup.sh
```

The compatibility wrapper finds the sibling engine and invokes the canonical
engine setup. Locked local files remain under the shared workspace `vend/wadpack`
tree. This includes user-supplied third-party files such as
`PreciseCrosshair-v1.5.0.pk3`; the binary is not committed to either SOL
repository.

## Final bundle

From the editor checkout:

```bash
bash tools/sol-package.sh
```

This delegates final construction to SOL Engine. The editor first remains
available to produce its current content component; the engine supplies the
runtime component, locked resource inputs, attribution, and final contract.

`SOLPACK.json` schema 2 separates all logical slots from physical mounted
components. A normal v0.4 physical bundle contains carriers for slots 1–10,
12–19, 21, and 22. No carrier exists for retired slot 11 or reserved slot 20.

The result remains:

```text
build/sol/sol.pk3
```

Copies placed beside local engine/editor binaries are byte-identical.

## Authoring materialization

Ultimate Doom Builder still requires direct resource paths. The engine-owned
bundle tool may materialize only active wadpack components into a cache keyed by
the complete bundle hash. Retired/reserved positions are skipped.

Native editor playtests let `sol-engine` validate/mount its adjacent `sol.pk3`
and append the temporary UDB map afterward so the map under edit retains final
precedence.

## Attribution and distribution

The engine `THIRD_PARTY.md` is canonical for bundle provenance. Attribution does
not grant redistribution permission. HQ PlayStation music is retired; slot 12
PlayStation sound effects remain a local placeholder; PreciseCrosshair occupies
slot 19 with its GPL/libeye notice recorded for review. The complete `sol.pk3`
remains a local development/test artifact until every included resource is
cleared.

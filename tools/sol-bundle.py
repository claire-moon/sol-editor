#!/usr/bin/env python3
"""Build, verify, and materialize SOL's single-file runtime bundle."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import tempfile
import zipfile
from pathlib import Path
from typing import Any, Iterable

SCHEMA = 1
EPOCH = (1980, 1, 1, 0, 0, 0)
BINARY_COMPRESSION = zipfile.ZIP_STORED
TEXT_COMPRESSION = zipfile.ZIP_DEFLATED
CARRIER_RE = re.compile(r'^(\d{2})-[a-z0-9][a-z0-9._-]*\.wad$')


def die(message: str, code: int = 1) -> None:
    print(message, file=os.sys.stderr)
    raise SystemExit(code)


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def sha256_stream(handle: Any) -> str:
    digest = hashlib.sha256()
    for block in iter(lambda: handle.read(1024 * 1024), b''):
        digest.update(block)
    return digest.hexdigest()


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding='utf-8'))


def zip_info(name: str, compression: int) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, EPOCH)
    info.compress_type = compression
    info.external_attr = 0o100644 << 16
    return info


def runtime_inputs(manifest: dict[str, Any], vend: Path) -> list[tuple[dict[str, Any], Path, str]]:
    lock_path = vend / 'wadpack' / 'lock.json'
    if not lock_path.is_file():
        die(f'SOL wadpack lock is missing: {lock_path}')
    lock = read_json(lock_path)
    locked = {entry['id']: entry for entry in lock.get('files', [])}
    result: list[tuple[dict[str, Any], Path, str]] = []
    runtime_dir = vend / 'wadpack' / 'runtime'
    for item in manifest['load_order']:
        path = runtime_dir / item['runtime_name']
        entry = locked.get(item['id'])
        if not path.is_file() or entry is None:
            die(f'Missing locked SOL resource: {item["display_name"]}: {path}')
        actual = sha256_path(path)
        if actual != entry.get('runtime_sha256'):
            die(f'Changed locked SOL resource: {item["display_name"]}: {path}')
        result.append((item, path, actual))
    return result


def carrier_name(order: int, ident: str) -> str:
    safe = re.sub(r'[^a-z0-9._-]+', '-', ident.casefold()).strip('-')
    if not safe:
        die(f'Cannot derive embedded carrier name for component {order}')
    return f'{order:02d}-{safe}.wad'


def component_record(order: int, kind: str, ident: str, display_name: str,
                     archive_name: str, runtime_name: str, digest: str,
                     distribution: str) -> dict[str, Any]:
    return {
        'order': order,
        'kind': kind,
        'id': ident,
        'display_name': display_name,
        'archive': archive_name,
        'runtime_name': runtime_name,
        'sha256': digest,
        'distribution': distribution,
    }


def expected_contract(manifest_path: Path | None, version_path: Path | None) -> dict[str, Any] | None:
    if manifest_path is None and version_path is None:
        return None
    if manifest_path is None or version_path is None:
        die('--manifest and --version-file must be supplied together for contract validation')
    manifest = read_json(manifest_path)
    version = read_json(version_path)
    return {
        'version': version['version'],
        'bundle_contract': version.get('bundle_contract'),
        'bundle_name': version.get('bundle_name'),
        'wadpack_contract': version['wadpack_contract'],
        'wadpack_entries': version['wadpack_entries'],
        'ids': [item['id'] for item in manifest['load_order']],
        'runtime_names': [item['runtime_name'] for item in manifest['load_order']],
    }


def validate_component_table(components: list[dict[str, Any]]) -> None:
    if not components:
        die('SOL bundle component table is empty')
    archives = [entry.get('archive') for entry in components]
    if len(archives) != len(set(archives)):
        die('SOL bundle contains duplicate embedded carrier names')
    for expected_order, entry in enumerate(components, start=1):
        if entry.get('order') != expected_order:
            die('SOL bundle component order is not contiguous')
        archive = str(entry.get('archive', ''))
        match = CARRIER_RE.fullmatch(archive)
        if match is None or int(match.group(1)) != expected_order:
            die(f'Invalid native embedded carrier name: {archive}')
        runtime_name = str(entry.get('runtime_name', ''))
        if not runtime_name or '/' in runtime_name or '\\' in runtime_name:
            die(f'Invalid materialized runtime name: {runtime_name}')
    kinds = [entry.get('kind') for entry in components]
    if kinds[-2:] != ['runtime', 'content']:
        die('SOL bundle must end with runtime and content components')
    if any(kind != 'wadpack' for kind in kinds[:-2]):
        die('SOL bundle contains an unexpected component kind')


def validate_contract(metadata: dict[str, Any], expected: dict[str, Any] | None) -> None:
    if metadata.get('schema') != SCHEMA or metadata.get('project') != 'SOL':
        die('Unsupported SOL bundle metadata')
    components = metadata.get('components')
    if not isinstance(components, list):
        die('SOL bundle component table is missing')
    validate_component_table(components)
    if expected is None:
        return
    if metadata.get('version') != expected['version']:
        die('SOL bundle version does not match this checkout')
    if metadata.get('bundle_contract') != expected['bundle_contract']:
        die('SOL bundle contract does not match this checkout')
    if expected['bundle_name'] not in (None, 'sol.pk3'):
        die('Unsupported SOL bundle filename contract')
    if metadata.get('wadpack_contract') != expected['wadpack_contract']:
        die('SOL bundle wadpack contract does not match this checkout')
    if metadata.get('wadpack_entries') != expected['wadpack_entries']:
        die('SOL bundle wadpack entry count does not match this checkout')
    wadpack = [entry for entry in components if entry.get('kind') == 'wadpack']
    if [entry.get('id') for entry in wadpack] != expected['ids']:
        die('SOL bundle wadpack IDs do not match this checkout')
    if [entry.get('runtime_name') for entry in wadpack] != expected['runtime_names']:
        die('SOL bundle materialized runtime names do not match this checkout')


def verify_bundle(bundle: Path, expected: dict[str, Any] | None = None) -> dict[str, Any]:
    if not bundle.is_file():
        die(f'SOL bundle does not exist: {bundle}')
    try:
        with zipfile.ZipFile(bundle) as archive:
            names = archive.namelist()
            if len(names) != len(set(names)):
                die('SOL bundle contains duplicate ZIP members')
            if 'SOLPACK.json' not in names or 'THIRD_PARTY.md' not in names:
                die('SOL bundle is missing metadata or attribution')
            metadata = json.loads(archive.read('SOLPACK.json').decode('utf-8'))
            validate_contract(metadata, expected)
            expected_names = {'SOLPACK.json', 'THIRD_PARTY.md'}
            expected_names.update(entry['archive'] for entry in metadata['components'])
            if set(names) != expected_names:
                die('SOL bundle contains unexpected or missing members')
            with archive.open('THIRD_PARTY.md') as handle:
                if sha256_stream(handle) != metadata.get('credits_sha256'):
                    die('SOL bundle attribution file hash mismatch')
            for entry in metadata['components']:
                with archive.open(entry['archive']) as handle:
                    if sha256_stream(handle) != entry['sha256']:
                        die(f'SOL bundle component hash mismatch: {entry["archive"]}')
            bad = archive.testzip()
            if bad is not None:
                die(f'SOL bundle ZIP integrity failure: {bad}')
            return metadata
    except (OSError, zipfile.BadZipFile, UnicodeDecodeError, json.JSONDecodeError, KeyError) as exc:
        die(f'Invalid SOL bundle {bundle}: {exc}')
    raise AssertionError('unreachable')


def one_component(metadata: dict[str, Any], kind: str) -> dict[str, Any]:
    matches = [entry for entry in metadata['components'] if entry.get('kind') == kind]
    if len(matches) != 1:
        die(f'SOL bundle must contain exactly one {kind} component')
    return matches[0]


def verify_live_inputs(metadata: dict[str, Any], runtime: Path | None,
                       content: Path | None, credits: Path | None) -> None:
    checks = ((runtime, 'runtime'), (content, 'content'))
    for path, kind in checks:
        if path is None:
            continue
        if not path.is_file():
            die(f'Current SOL {kind} component is missing: {path}')
        expected = one_component(metadata, kind)['sha256']
        if sha256_path(path) != expected:
            die(f'SOL bundle contains a stale {kind} component')
    if credits is not None:
        if not credits.is_file():
            die(f'Current SOL attribution file is missing: {credits}')
        if sha256_path(credits) != metadata.get('credits_sha256'):
            die('SOL bundle contains a stale attribution file')


def build_bundle(args: argparse.Namespace) -> None:
    manifest = read_json(args.manifest)
    version = read_json(args.version_file)
    if manifest.get('schema') != 1 or not isinstance(manifest.get('load_order'), list):
        die(f'Unsupported SOL wadpack manifest: {args.manifest}')
    if len(manifest['load_order']) != version.get('wadpack_entries'):
        die('SOL version metadata and wadpack entry count disagree')
    if version.get('wadpack_contract') is None:
        die('SOL version metadata has no wadpack contract')
    if version.get('bundle_contract') != 1 or version.get('bundle_name') != 'sol.pk3':
        die('SOL version metadata has an unsupported bundle contract')
    if not args.runtime.is_file():
        die(f'SOL runtime component is missing: {args.runtime}')
    if not args.content.is_file():
        die(f'SOL content component is missing: {args.content}')
    if not args.credits.is_file():
        die(f'SOL attribution file is missing: {args.credits}')

    inputs = runtime_inputs(manifest, args.vend)
    components: list[dict[str, Any]] = []
    sources: list[tuple[str, Path]] = []
    for order, (item, path, digest) in enumerate(inputs, start=1):
        archive_name = carrier_name(order, item['id'])
        components.append(component_record(
            order, 'wadpack', item['id'], item['display_name'], archive_name,
            item['runtime_name'], digest, item.get('distribution', 'unknown')))
        sources.append((archive_name, path))

    runtime_order = len(components) + 1
    runtime_digest = sha256_path(args.runtime)
    runtime_archive = carrier_name(runtime_order, 'sol-runtime')
    components.append(component_record(
        runtime_order, 'runtime', 'sol-runtime', 'SOL runtime', runtime_archive,
        args.runtime.name, runtime_digest, 'SOL-project'))
    sources.append((runtime_archive, args.runtime))

    content_order = len(components) + 1
    content_digest = sha256_path(args.content)
    content_archive = carrier_name(content_order, 'sol-content')
    components.append(component_record(
        content_order, 'content', 'sol-content', 'SOL E1M1 content', content_archive,
        args.content.name, content_digest, 'SOL-project'))
    sources.append((content_archive, args.content))

    metadata = {
        'schema': SCHEMA,
        'project': 'SOL',
        'version': version['version'],
        'bundle_contract': version['bundle_contract'],
        'native_embedding': 'uzdoom-root-wad-carriers',
        'wadpack_contract': version['wadpack_contract'],
        'wadpack_entries': version['wadpack_entries'],
        'distribution': 'local-build-only-until-third-party-audit',
        'credits': 'THIRD_PARTY.md',
        'credits_sha256': sha256_path(args.credits),
        'components': components,
    }
    metadata_bytes = (json.dumps(metadata, indent=2, sort_keys=True) + '\n').encode('utf-8')

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=args.output.parent, delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        with zipfile.ZipFile(tmp_path, 'w', allowZip64=True) as archive:
            archive.writestr(zip_info('SOLPACK.json', TEXT_COMPRESSION), metadata_bytes)
            archive.writestr(
                zip_info('THIRD_PARTY.md', TEXT_COMPRESSION),
                args.credits.read_bytes())
            for archive_name, source in sources:
                info = zip_info(archive_name, BINARY_COMPRESSION)
                with source.open('rb') as src, archive.open(info, 'w', force_zip64=True) as dst:
                    for block in iter(lambda: src.read(1024 * 1024), b''):
                        dst.write(block)
        os.chmod(tmp_path, 0o644)
        tmp_path.replace(args.output)
    finally:
        tmp_path.unlink(missing_ok=True)

    expected = expected_contract(args.manifest, args.version_file)
    metadata = verify_bundle(args.output, expected)
    verify_live_inputs(metadata, args.runtime, args.content, args.credits)
    print(args.output)


def selected_components(metadata: dict[str, Any], scope: str) -> Iterable[dict[str, Any]]:
    for entry in metadata['components']:
        if scope == 'wadpack' and entry['kind'] != 'wadpack':
            continue
        if scope == 'engine' and entry['kind'] == 'content':
            continue
        yield entry


def materialize(args: argparse.Namespace) -> None:
    expected = expected_contract(args.manifest, args.version_file)
    metadata = verify_bundle(args.bundle, expected)
    bundle_digest = sha256_path(args.bundle)
    root = args.directory / bundle_digest
    root.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    with zipfile.ZipFile(args.bundle) as archive:
        for entry in selected_components(metadata, args.scope):
            destination = root / entry['runtime_name']
            if not destination.is_file() or sha256_path(destination) != entry['sha256']:
                with tempfile.NamedTemporaryFile(dir=root, delete=False) as tmp:
                    tmp_path = Path(tmp.name)
                    with archive.open(entry['archive']) as src:
                        for block in iter(lambda: src.read(1024 * 1024), b''):
                            tmp.write(block)
                os.chmod(tmp_path, 0o644)
                tmp_path.replace(destination)
            paths.append(destination)
    list_path = root / f'load-order-{args.scope}.txt'
    list_path.write_text(''.join(f'{path}\n' for path in paths), encoding='utf-8')
    for path in paths:
        print(path)


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)

    build = sub.add_parser('build')
    build.add_argument('--manifest', type=Path, required=True)
    build.add_argument('--version-file', type=Path, required=True)
    build.add_argument('--vend', type=Path, required=True)
    build.add_argument('--runtime', type=Path, required=True)
    build.add_argument('--content', type=Path, required=True)
    build.add_argument('--credits', type=Path, required=True)
    build.add_argument('--output', type=Path, required=True)

    verify = sub.add_parser('verify')
    verify.add_argument('--bundle', type=Path, required=True)
    verify.add_argument('--manifest', type=Path)
    verify.add_argument('--version-file', type=Path)
    verify.add_argument('--runtime', type=Path)
    verify.add_argument('--content', type=Path)
    verify.add_argument('--credits', type=Path)

    extract = sub.add_parser('materialize')
    extract.add_argument('--bundle', type=Path, required=True)
    extract.add_argument('--directory', type=Path, required=True)
    extract.add_argument('--scope', choices=('wadpack', 'engine', 'all'), default='all')
    extract.add_argument('--manifest', type=Path)
    extract.add_argument('--version-file', type=Path)

    args = parser.parse_args()
    if args.command == 'build':
        build_bundle(args)
    elif args.command == 'verify':
        expected = expected_contract(args.manifest, args.version_file)
        metadata = verify_bundle(args.bundle, expected)
        verify_live_inputs(metadata, args.runtime, args.content, args.credits)
        print(args.bundle)
    elif args.command == 'materialize':
        materialize(args)


if __name__ == '__main__':
    main()

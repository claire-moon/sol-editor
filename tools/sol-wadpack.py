#!/usr/bin/env python3
"""Import, normalize, lock, verify, and enumerate SOL's required local wadpack."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

SKIP_DIRS = {'.git', '.cache', 'node_modules', '__pycache__', 'Build', 'build'}


def die(message: str, code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(code)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def load_manifest(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding='utf-8'))
    if data.get('schema') != 1 or not isinstance(data.get('load_order'), list):
        die(f'Unsupported wadpack manifest: {path}')
    ids = [item.get('id') for item in data['load_order']]
    runtime = [item.get('runtime_name') for item in data['load_order']]
    if len(ids) != len(set(ids)) or len(runtime) != len(set(runtime)):
        die('Wadpack manifest contains duplicate IDs or runtime names')
    return data


def candidate_files(roots: Iterable[Path], aliases: set[str]) -> Iterable[Path]:
    aliases_cf = {name.casefold() for name in aliases}
    seen: set[Path] = set()
    for root in roots:
        root = root.expanduser().resolve()
        if root.is_file():
            if root.name.casefold() in aliases_cf and root not in seen:
                seen.add(root)
                yield root
            continue
        if not root.is_dir():
            continue
        for current, dirs, files in os.walk(root):
            dirs[:] = [name for name in dirs if name not in SKIP_DIRS]
            for name in files:
                if name.casefold() in aliases_cf:
                    path = (Path(current) / name).resolve()
                    if path not in seen:
                        seen.add(path)
                        yield path


def expected_hash_ok(item: dict[str, Any], path: Path) -> bool:
    expected = {value.lower() for value in item.get('source_sha256', [])}
    value = sha256(path)
    if not expected or value in expected:
        return True
    transform = item.get('transform', {})
    if transform.get('allow_unlocked_direct') and path.suffix.casefold() in {'.pk3', '.wad'}:
        return True
    return False


def choose_source(item: dict[str, Any], roots: list[Path]) -> Path | None:
    rejected: list[tuple[Path, str]] = []
    for path in candidate_files(roots, set(item['source_names'])):
        value = sha256(path)
        if expected_hash_ok(item, path):
            return path
        rejected.append((path, value))
    if rejected:
        print(f'HASH MISMATCH: {item["display_name"]}', file=sys.stderr)
        for path, value in rejected:
            print(f'  {value}  {path}', file=sys.stderr)
    return None


def copy_atomic(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as tmp:
        tmp_path = Path(tmp.name)
        with source.open('rb') as src:
            shutil.copyfileobj(src, tmp)
    os.chmod(tmp_path, 0o644)
    tmp_path.replace(destination)


def write_bytes_atomic(data: bytes, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as tmp:
        tmp.write(data)
        tmp_path = Path(tmp.name)
    os.chmod(tmp_path, 0o644)
    tmp_path.replace(destination)


def matching_zip_member(archive: zipfile.ZipFile, transform: dict[str, Any]) -> str:
    names = [name for name in archive.namelist() if not name.endswith('/')]
    suffix = transform.get('member_suffix')
    extension = transform.get('member_extension')
    matches = []
    for name in names:
        base = Path(name).name
        if suffix and base.casefold().endswith(str(suffix).casefold()):
            matches.append(name)
        elif extension and base.casefold().endswith(str(extension).casefold()):
            matches.append(name)
    if len(matches) != 1:
        die(f'Expected one archive member, found {len(matches)}: {matches}')
    return matches[0]


def normalized_zip(source: Path, destination: Path) -> None:
    with zipfile.ZipFile(source) as src:
        files = [name for name in src.namelist() if not name.endswith('/')]
        roots = {name.split('/', 1)[0] for name in files if '/' in name}
        if len(roots) != 1 or any('/' not in name for name in files):
            die(f'Expected one top-level directory in {source}')
        root = next(iter(roots)) + '/'
        destination.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=destination.parent, delete=False) as tmp:
            tmp_path = Path(tmp.name)
        try:
            with zipfile.ZipFile(tmp_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as out:
                for name in sorted(files, key=str.casefold):
                    if not name.startswith(root):
                        die(f'Archive member escapes expected root: {name}')
                    relative = name[len(root):]
                    if not relative:
                        continue
                    relative_path = PurePosixPath(relative)
                    if relative_path.is_absolute() or '..' in relative_path.parts:
                        die(f'Unsafe archive member: {name}')
                    info = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
                    info.compress_type = zipfile.ZIP_DEFLATED
                    info.external_attr = 0o100644 << 16
                    out.writestr(info, src.read(name))
            os.chmod(tmp_path, 0o644)
            tmp_path.replace(destination)
        finally:
            tmp_path.unlink(missing_ok=True)


def sevenzip_command() -> str:
    for name in ('7zz', '7z'):
        path = shutil.which(name)
        if path:
            return path
    die('7-Zip is required to import Flashlight++. Install p7zip-full and rerun.')


def sevenzip_member(source: Path, suffix: str, destination: Path) -> None:
    command = sevenzip_command()
    listing = subprocess.run([command, 'l', '-slt', str(source)], check=True, text=True, capture_output=True)
    paths = []
    for line in listing.stdout.splitlines():
        if line.startswith('Path = '):
            value = line[7:]
            if Path(value).name.casefold().endswith(suffix.casefold()):
                paths.append(value)
    if len(paths) != 1:
        die(f'Expected one 7z member ending in {suffix}, found {paths}')
    result = subprocess.run([command, 'e', '-so', str(source), paths[0]], check=True, capture_output=True)
    write_bytes_atomic(result.stdout, destination)


def transform_source(item: dict[str, Any], source: Path, destination: Path) -> None:
    kind = item['transform']['type']
    direct_allowed = item['transform'].get('allow_direct', False)
    if kind == 'copy':
        copy_atomic(source, destination)
    elif kind == 'zip_strip_single_root':
        normalized_zip(source, destination)
    elif kind in {'zip_member', 'zip_member_or_direct'}:
        if kind == 'zip_member_or_direct' and source.suffix.casefold() != '.zip':
            copy_atomic(source, destination)
        elif direct_allowed and source.suffix.casefold() == destination.suffix.casefold():
            copy_atomic(source, destination)
        else:
            with zipfile.ZipFile(source) as archive:
                member = matching_zip_member(archive, item['transform'])
                write_bytes_atomic(archive.read(member), destination)
    elif kind == 'sevenzip_member_or_direct':
        if source.suffix.casefold() in {'.pk3', '.wad'}:
            copy_atomic(source, destination)
        else:
            sevenzip_member(source, item['transform']['member_suffix'], destination)
    else:
        die(f'Unknown transform type: {kind}')


def wadpack_paths(manifest: dict[str, Any], vend: Path) -> list[Path]:
    runtime = vend / 'wadpack' / 'runtime'
    return [runtime / item['runtime_name'] for item in manifest['load_order']]


def verify(manifest: dict[str, Any], vend: Path, quiet: bool = False) -> bool:
    lock_path = vend / 'wadpack' / 'lock.json'
    if not lock_path.is_file():
        if not quiet:
            print(f'MISSING: {lock_path}')
        return False
    lock = json.loads(lock_path.read_text(encoding='utf-8'))
    locked = {item['id']: item for item in lock.get('files', [])}
    good = True
    for item, path in zip(manifest['load_order'], wadpack_paths(manifest, vend)):
        entry = locked.get(item['id'])
        state = 'PASS'
        if not path.is_file() or not entry:
            state = 'MISSING'
            good = False
        elif sha256(path) != entry.get('runtime_sha256'):
            state = 'CHANGED'
            good = False
        if not quiet:
            print(f'[{state}] {item["display_name"]}: {path}')
    return good


def import_pack(manifest: dict[str, Any], vend: Path, roots: list[Path], allow_missing: bool) -> int:
    wadpack = vend / 'wadpack'
    source_dir = wadpack / 'source'
    runtime_dir = wadpack / 'runtime'
    source_dir.mkdir(parents=True, exist_ok=True)
    runtime_dir.mkdir(parents=True, exist_ok=True)
    roots = [source_dir, runtime_dir, *roots]

    previous_locked: dict[str, dict[str, Any]] = {}
    previous_lock_path = wadpack / 'lock.json'
    if previous_lock_path.is_file():
        try:
            previous = json.loads(previous_lock_path.read_text(encoding='utf-8'))
            previous_locked = {entry['id']: entry for entry in previous.get('files', [])}
        except (KeyError, TypeError, json.JSONDecodeError):
            previous_locked = {}

    locked_files = []
    missing = []
    for item in manifest['load_order']:
        source = choose_source(item, roots)
        destination = runtime_dir / item['runtime_name']
        if source is None:
            previous_entry = previous_locked.get(item['id'])
            if (destination.is_file() and previous_entry and
                    sha256(destination) == previous_entry.get('runtime_sha256')):
                locked_files.append(previous_entry)
                print(f'[KEEP] {item["display_name"]}: {destination}')
                continue
            missing.append(item)
            state = 'CHANGED' if destination.is_file() else 'MISSING'
            print(f'[{state}] {item["display_name"]}: {destination}')
            continue

        source_copy = source_dir / item['id'] / source.name
        if source.resolve() != source_copy.resolve():
            copy_atomic(source, source_copy)
        transform_source(item, source_copy, destination)
        locked_files.append({
            'id': item['id'],
            'display_name': item['display_name'],
            'source_name': source.name,
            'source_sha256': sha256(source_copy),
            'runtime_name': item['runtime_name'],
            'runtime_sha256': sha256(destination),
            'distribution': item['distribution'],
        })
        print(f'[PASS] {item["display_name"]}: {destination}')

    lock = {
        'schema': 1,
        'manifest_name': manifest['name'],
        'manifest_version': manifest['version'],
        'files': locked_files,
        'missing': [item['id'] for item in missing],
    }
    (wadpack / 'lock.json').write_text(json.dumps(lock, indent=2, sort_keys=True) + '\n', encoding='utf-8')
    (wadpack / 'load-order.txt').write_text(
        ''.join(str(path) + '\n' for path in wadpack_paths(manifest, vend)), encoding='utf-8')
    if missing and not allow_missing:
        print('\nMissing required SOL wadpack files:', file=sys.stderr)
        for item in missing:
            print('  - ' + ' / '.join(item['source_names']), file=sys.stderr)
        return 2
    return 0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--vend', type=Path, required=True)
    sub = parser.add_subparsers(dest='command', required=True)
    install = sub.add_parser('import')
    install.add_argument('--scan', type=Path, action='append', default=[])
    install.add_argument('--allow-missing', action='store_true')
    sub.add_parser('verify')
    sub.add_parser('status')
    sub.add_parser('paths')
    args = parser.parse_args()
    manifest = load_manifest(args.manifest)
    vend = args.vend.expanduser().resolve()
    if args.command == 'import':
        raise SystemExit(import_pack(manifest, vend, args.scan, args.allow_missing))
    if args.command in {'verify', 'status'}:
        raise SystemExit(0 if verify(manifest, vend) else 1)
    if args.command == 'paths':
        if not verify(manifest, vend, quiet=True):
            die('SOL wadpack is incomplete. Run tools/sol-wadpack-setup.sh.', 2)
        for path in wadpack_paths(manifest, vend):
            print(path)


if __name__ == '__main__':
    main()

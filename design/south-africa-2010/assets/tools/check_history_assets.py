#!/usr/bin/env python3
"""Verify Tabellone's approved Flutter decoration and retained preview evidence."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
ARTWORK = ROOT / 'design/south-africa-2010/assets/history-tabellone'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads((ARTWORK / 'manifest.json').read_text())
    assert manifest['approval'] == 'approved', 'Artwork approval missing'
    for name, expected in manifest['files'].items():
        assert digest(ARTWORK / name) == expected, f'Approval evidence changed: {name}'
    runtime = ROOT / manifest['runtimePainter']
    assert digest(runtime) == manifest['runtimePainterSha256'], 'Unreviewed painter change'
    assert runtime.read_bytes() == (ARTWORK / 'approved-artwork.dart.txt').read_bytes()
    assert manifest['runtimeRasterAssets'] == [], 'Unexpected runtime raster asset'
    print('Tabellone approved Flutter artwork and preview evidence verified.')


if __name__ == '__main__':
    main()

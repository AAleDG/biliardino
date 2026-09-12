#!/usr/bin/env python3
"""Verify Figurina's approved decoration and byte-identical PNG reuse."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
PACKET = ROOT / 'design/south-africa-2010/assets/profile-figurina'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def code(path):
    # Ignore comments/formatting only; this decoration source contains no text literals.
    compact = ''.join(''.join(line.split()) for line in path.read_text().splitlines()
                      if not line.lstrip().startswith('//'))
    return re.sub(r',(?=\))', '', compact)


def main():
    manifest = json.loads((PACKET / 'manifest.json').read_text())
    assert manifest['approval'] == 'approved', 'Artwork approval missing'
    for name, expected in manifest['files'].items():
        assert digest(PACKET / name) == expected, f'Approval evidence changed: {name}'
    for field in ('runtimeAsset', 'runtimePainter'):
        assert digest(ROOT / manifest[field]) == manifest[field + 'Sha256'], field
    assert code(ROOT / manifest['runtimePainter']) == code(PACKET / 'approved-artwork.dart.txt'), 'Unreviewed painter geometry'
    print('Figurina approved artwork, runtime painter and reused PNG verified.')


if __name__ == '__main__':
    main()

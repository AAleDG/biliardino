"""Verify approved live master/provenance; pixel hashes never imply visual parity."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[4]
folder = root / 'design/south-africa-2010/assets/live-r1'
manifest = json.loads((folder / 'manifest.json').read_text())
assert manifest['approval'] == 'approved'
assert manifest['files']['reference-board.png'] == manifest['referenceSha256']
geometry = manifest['geometryImplementation']
assert hashlib.sha256((root / geometry['file']).read_bytes()).hexdigest() == geometry['sha256']
for name, digest in manifest['files'].items():
    assert hashlib.sha256((folder / name).read_bytes()).hexdigest() == digest, name
assert 'Okay, so this is approved.' in (folder / 'approval.md').read_text()
with Image.open(folder / 'live-scene.png') as im:
    assert im.format == 'PNG' and im.mode == 'RGBA'
    assert list(im.size) == manifest['dimensions']
    histogram = im.getchannel('A').histogram()
    assert histogram[0] > 0 and histogram[255] > 0
    assert sum(histogram[1:255]) > 0
    samples = json.loads((folder / 'rod-centres.json').read_text())
    for sample in samples:
        ys = [y for y in range(190, 340) if im.getpixel((sample['x'], y))[3] == 255]
        assert [min(ys), max(ys)] == [sample['top'], sample['bottom']]
        assert (min(ys) + max(ys)) / 2 == sample['centre']
    centres = [sample['centre'] for sample in samples]
    assert (max(centres) - min(centres)) * 440 / im.width < 1

with Image.open(folder / 'source-magenta.png') as source:
    assert source.mode == 'RGB' and list(source.size) == manifest['dimensions']
    # Generated source is near-magenta, not mathematically uniform FF00FF.
    assert all(r > 230 and b > 230 and g < 40 for r,g,b in
               [source.getpixel(point) for point in [(0,0),(2171,0),(0,723),(2171,723)]])
    assert sum(r > 240 and b > 240 and g < 20
               for r,g,b in source.get_flattened_data()) > source.width * source.height / 2
extraction = json.loads((folder / 'extraction.json').read_text())
assert extraction['sourceSha256'] == manifest['files']['source-magenta.png']
assert extraction['outputSha256'] == manifest['files']['live-scene.png']
assert extraction['dimensionsUnchanged'] and extraction['interiorRgbUnchanged']
assert (manifest['runtimeAsset'] in (root / 'pubspec.yaml').read_text()) == manifest['runtimeRegistered']
assert 'magenta' in (folder / 'remove_magenta.py').read_text()
assert (folder / 'rod-centres.json').is_file()
print(json.dumps({'passed': True, 'revision': manifest['revision'], 'registered': manifest['runtimeRegistered'], 'limitation': 'Hashes and alpha do not replace approved visual review; final production composition approval is separate.'}))

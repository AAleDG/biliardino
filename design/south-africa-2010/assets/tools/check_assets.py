"""Validate review SVG structure/provenance without claiming visual approval."""
from pathlib import Path
import hashlib, json, math
import xml.etree.ElementTree as ET
root = Path(__file__).resolve().parents[4]
folder = root / 'design/south-africa-2010/assets/r1'
manifest = json.loads((folder / 'manifest.json').read_text())
allowed = {'svg', 'title', 'g', 'path', 'circle'}
results = []
for asset in manifest['assets']:
    path = folder / asset['file']
    content = path.read_bytes()
    tree = ET.fromstring(content)
    assert tree.get('viewBox') == asset['viewBox'], path
    box = list(map(float, tree.get('viewBox').split()))
    assert len(box) == 4 and all(map(math.isfinite, box)) and min(box[2:]) > 0
    ids = []
    for element in tree.iter():
        assert element.tag.split('}')[-1] in allowed, element.tag
        if element.get('id'): ids.append(element.get('id'))
        for key, value in element.attrib.items():
            assert not key.lower().startswith('on') and 'href' not in key and 'url(' not in value, (path,key)
            if key in ['fill','stroke']: assert value == 'none' or value in manifest['palette'], value
    assert len(ids) == len(set(ids)), path
    assert set(asset['animation']['layers']) <= set(ids), path
    pivot = asset['animation'].get('pivot')
    if pivot: assert box[0] <= pivot[0] <= box[0]+box[2] and box[1] <= pivot[1] <= box[1]+box[3]
    assert hashlib.sha256(content).hexdigest() == asset['sha256'], path
    results.append({'asset': asset['id'], 'bytes': len(content), 'structure': 'passed', 'hash': 'matched'})
figure = ET.fromstring((folder/'svg/foosball-figure.svg').read_bytes()).find('.//*[@id="figure"]')
assembly_figure = ET.fromstring((folder/'svg/foosball-rod.svg').read_bytes()).find('.//*[@id="figure"]')
figure.tail = assembly_figure.tail = None
assert ET.tostring(figure) == ET.tostring(assembly_figure), 'Figure and assembly geometry drift'
report = {'passed': True, 'approval': manifest['approval'], 'assets': results, 'checks': ['allowed vector-only elements', 'finite viewBoxes', 'unique IDs', 'palette restrictions', 'no external resources or handlers', 'layer/pivot references', 'SHA-256 provenance', 'figure/assembly synchronized'], 'limitation': 'Structure/provenance only; rendered inspection, user approval and Flutter validation are separate.'}
(folder/'qa/structure-checks.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))

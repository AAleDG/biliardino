"""Validate Home review artwork structure and provenance without claiming approval."""

from pathlib import Path
import hashlib
import json
import math
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[4]
FOLDER = ROOT / "design/south-africa-2010/assets/home-r1"
R1_MANIFEST = ROOT / "design/south-africa-2010/assets/r1/manifest.json"
MANIFEST = json.loads((FOLDER / "manifest.json").read_text())
APPROVED_R1 = json.loads(R1_MANIFEST.read_text())
ALLOWED_ELEMENTS = {"svg", "title", "defs", "g", "path", "circle", "use"}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


approved_hashes = {asset["id"]: asset["sha256"] for asset in APPROVED_R1["assets"]}
for source in MANIFEST["approvedInputs"]:
    assert source["sha256"] == approved_hashes[source["id"]], source["id"]

results = []
for asset in MANIFEST["assets"]:
    path = FOLDER / asset["file"]
    root = ET.fromstring(path.read_bytes())
    assert root.get("viewBox") == asset["viewBox"], path
    box = [float(value) for value in root.get("viewBox").split()]
    assert len(box) == 4 and all(math.isfinite(value) for value in box)
    assert min(box[2:]) > 0

    ids = []
    for element in root.iter():
        name = element.tag.split("}")[-1]
        assert name in ALLOWED_ELEMENTS, (path, name)
        if element.get("id"):
            ids.append(element.get("id"))
        for key, value in element.attrib.items():
            key_name = key.split("}")[-1]
            assert not key_name.lower().startswith("on"), (path, key_name)
            if key_name == "href":
                assert value.startswith("#"), (path, value)
            assert "url(" not in value, (path, value)
            if key_name in {"fill", "stroke"}:
                assert value == "none" or value in MANIFEST["palette"], (path, value)

    assert len(ids) == len(set(ids)), path
    assert not list(root.iter("{http://www.w3.org/2000/svg}text")), path
    assert sha256(path) == asset["sha256"], path
    results.append(
        {
            "asset": asset["id"],
            "bytes": path.stat().st_size,
            "structure": "passed",
            "hash": "matched",
        }
    )

hero_text = (FOLDER / "svg/home-hero.svg").read_text()
for exact_r1_fragment in (
    'M39 47 C22 50 15 63 16 79 L22 110 Q28 130 35 160 L65 160 Q72 130 78 110 L84 79 C85 63 78 50 61 47 L61 51 Q50 57 39 51 Z',
    'M29 167 Q29 162 36 162 H64 Q71 162 71 167 L66 199 Q65 207 50 207 Q35 207 34 199 Z',
    'M8 104 L352 70 Q357 70 358 76 Q358 82 352 83 L9 117 Q3 117 2 111 Q2 105 8 104 Z',
    'M60 39 L80 54 L72 78 H48 L40 54 Z M60 39 V20 M80 54 L99 47 M72 78 L84 95 M48 78 L36 95 M40 54 L21 47',
):
    assert exact_r1_fragment in hero_text, "Approved R1 primitive drifted"

review_path = FOLDER / MANIFEST["review"]["file"]
assert sha256(review_path) == MANIFEST["review"]["sha256"]
reference_path = Path("/Users/antonio.ruffolo/Downloads/726F3069-E269-4985-8BE7-CBA5848724ED.PNG")
assert reference_path.exists() and sha256(reference_path) == MANIFEST["source"]["referenceSha256"]

report = {
    "passed": True,
    "approval": MANIFEST["approval"],
    "assets": results,
    "checks": [
        "finite viewBoxes",
        "unique IDs",
        "approved palette only",
        "no text, scripts, handlers, filters, bitmaps or external resources",
        "internal fragment reuse only",
        "approved R1 input hashes matched",
        "approved R1 primitive geometry retained",
        "asset and review SHA-256 provenance matched",
        "exact supplied reference SHA-256 matched",
    ],
    "limitation": "Structural and provenance checks do not imply visual or user approval.",
}
(FOLDER / "qa/structure-checks.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report))

"""Validate the pending Home H2 raster candidate without claiming approval."""

from pathlib import Path
import hashlib
import json

from PIL import Image


ROOT = Path(__file__).resolve().parents[4]
FOLDER = ROOT / "design/south-africa-2010/assets/home-h2"
MANIFEST = json.loads((FOLDER / "manifest.json").read_text())


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


asset = MANIFEST["asset"]
asset_path = FOLDER / asset["file"]
assert sha256(asset_path) == asset["sha256"]
assert asset_path.stat().st_size == asset["bytes"]

with Image.open(asset_path) as image:
    rgba = image.convert("RGBA")
    assert image.mode == "RGBA", image.mode
    assert f"{image.width}x{image.height}" == asset["pixels"]
    alpha = rgba.getchannel("A")
    alpha_min, alpha_max = alpha.getextrema()
    histogram = alpha.histogram()
    transparent = histogram[0]
    opaque = histogram[255]
    partial = image.width * image.height - transparent - opaque
    assert (alpha_min, alpha_max) == (0, 255)
    assert rgba.getpixel((0, 0))[3] == 0
    assert transparent == MANIFEST["generation"]["alphaExtraction"]["transparentPixels"]
    assert partial == MANIFEST["generation"]["alphaExtraction"]["partiallyTransparentPixels"]

source = MANIFEST["retainedSource"]
source_path = FOLDER / source["file"]
assert sha256(source_path) == source["sha256"]

review_path = FOLDER / MANIFEST["review"]["file"]
assert sha256(review_path) == MANIFEST["review"]["sha256"]

reference_path = Path(
    "/Users/antonio.ruffolo/Downloads/726F3069-E269-4985-8BE7-CBA5848724ED.PNG"
)
assert reference_path.exists()
assert sha256(reference_path) == MANIFEST["source"]["referenceSha256"]

report = {
    "passed": True,
    "approval": MANIFEST["approval"],
    "asset": {
        "file": asset["file"],
        "sha256": asset["sha256"],
        "bytes": asset["bytes"],
        "pixels": asset["pixels"],
        "mode": "RGBA",
        "alphaMin": alpha_min,
        "alphaMax": alpha_max,
        "transparentPixels": transparent,
        "partiallyTransparentPixels": partial,
        "opaquePixels": opaque,
        "cornerAlpha": 0,
    },
    "checks": [
        "candidate hash and byte count matched",
        "1516x1038 RGBA image decoded",
        "real alpha spans 0 through 255",
        "transparent and partial-alpha counts matched manifest",
        "top-left corner is fully transparent",
        "retained opaque source hash matched",
        "review SHA-256 provenance matched",
        "exact supplied reference SHA-256 matched",
    ],
    "limitation": (
        "File structure and provenance checks do not imply visual or user approval. "
        "The built-in image tool did not expose its execution model."
    ),
}

(FOLDER / "qa").mkdir(exist_ok=True)
(FOLDER / "qa/structure-checks.json").write_text(
    json.dumps(report, indent=2) + "\n"
)
print(json.dumps(report))

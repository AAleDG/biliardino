"""Validate Nuova Partita setup artwork structure and provenance.

Passing checks never imply visual or user approval.
"""

from pathlib import Path
import hashlib
import json
import re

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[4]
ASSET_ROOT = ROOT / "design/south-africa-2010/assets"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_report(folder: Path, report: dict) -> None:
    qa = folder / "qa"
    qa.mkdir(exist_ok=True)
    (qa / "structure-checks.json").write_text(
        json.dumps(report, indent=2) + "\n"
    )


def check_setup_r1() -> dict:
    folder = ASSET_ROOT / "setup-r1"
    manifest = json.loads((folder / "manifest.json").read_text())
    assert manifest["revision"] == "setup-r1"
    assert manifest["approval"] in {
        "pending-user-review",
        "approved",
        "rejected-user-review",
    }
    assert manifest["contentBoundary"] == "decorative ribbons and football only"

    reference = ROOT / manifest["reference"]["file"]
    assert sha256(reference) == manifest["reference"]["sha256"]

    approved_r1 = json.loads((ASSET_ROOT / "r1/manifest.json").read_text())
    assert approved_r1["approval"] == "approved"
    approved = {asset["id"]: asset for asset in approved_r1["assets"]}
    input_results = []
    for item in manifest["inputs"]:
        approved_asset = approved[item["id"]]
        assert item["sha256"] == approved_asset["sha256"]
        path = ROOT / item["file"]
        assert sha256(path) == item["sha256"]
        input_results.append({"id": item["id"], "hash": "matched"})

    review = folder / "review.html"
    review_text = review.read_text()
    assert sha256(review) == manifest["review"]["sha256"]
    assert "<canvas" not in review_text.lower()
    assert "data:image" not in review_text.lower()
    assert "http://" not in review_text.lower()
    assert "https://" not in review_text.lower()
    assert "linear-gradient" in review_text
    assert review_text.count("../r1/svg/ribbon-header.svg") == 6
    assert review_text.count("../r1/svg/ribbon-corner.svg") == 8
    assert review_text.count("../r1/svg/football.svg") == 2
    for forbidden in manifest["forbiddenArtworkContent"]:
        assert forbidden not in " ".join(manifest["compositions"]).lower()

    render_results = []
    for item in manifest["review"]["renders"]:
        render = folder / item["file"]
        assert sha256(render) == item["sha256"]
        render_results.append({"viewport": item["viewport"], "hash": "matched"})

    external_sources = re.findall(
        r'(?:src|url)=["\']?([^"\')>]+)', review_text
    )
    assert not any(
        source.startswith(("http:", "https:", "data:"))
        for source in external_sources
    )

    report = {
        "passed": True,
        "revision": "setup-r1",
        "approval": manifest["approval"],
        "reference": "matched",
        "inputs": input_results,
        "review": {
            "hash": "matched",
            "offline": True,
            "renders": render_results,
        },
        "checks": [
            "exact reference hash",
            "approved R1 input hashes",
            "offline review sources only",
            "no embedded raster or canvas artwork",
            "render output hashes",
            "decorative content boundary",
        ],
        "limitation": (
            "Structure and provenance only; rendered inspection and explicit "
            "user approval are separate."
        ),
    }
    write_report(folder, report)
    return report


def alpha_counts(image: Image.Image) -> tuple[int, int, int]:
    histogram = image.getchannel("A").histogram()
    total = image.width * image.height
    transparent = histogram[0]
    opaque = histogram[255]
    return transparent, total - transparent - opaque, opaque


def check_setup_r2() -> dict:
    folder = ASSET_ROOT / "setup-r2"
    manifest = json.loads((folder / "manifest.json").read_text())
    assert manifest["revision"] == "setup-r2"
    assert manifest["approval"] in {
        "both-layers-approved-combined-composition-pending-user-review",
        "both-layers-approved-mechanical-composition-rejected-runtime-review-pending",
        "combined-composition-approved-user-review",
        "rejected-user-review",
    }
    assert manifest["contentBoundary"] == (
        "decorative ribbons and the lower football only; all UI and text "
        "remain live Flutter widgets"
    )

    reference = ROOT / manifest["reference"]["file"]
    assert sha256(reference) == manifest["reference"]["sha256"]
    for crop_key in ("userCrop", "lowerFlourishUserCrop"):
        crop = manifest["reference"][crop_key]
        assert sha256(folder / crop["file"]) == crop["sha256"]

    asset_results = []
    for asset in manifest["assets"]:
        path = folder / asset["file"]
        assert sha256(path) == asset["sha256"], path
        with Image.open(path) as image:
            assert list(image.size) == asset["dimensions"], path
            expected_mode = "RGBA" if "RGBA" in asset["format"] else "RGB"
            assert image.mode == expected_mode, (path, image.mode)
        if asset["approval"] == "approved-user-review":
            assert asset["approvalEvidence"]["date"] == "2026-09-10"
        asset_results.append(
            {
                "id": asset["id"],
                "hash": "matched",
                "dimensions": asset["dimensions"],
                "format": asset["format"],
                "approval": asset["approval"],
            }
        )

    assets = {asset["id"]: asset for asset in manifest["assets"]}
    upper_asset = assets["team-stage-v10-gimp-white-to-alpha"]
    upper_path = folder / upper_asset["file"]
    with Image.open(upper_path) as image:
        upper = image.convert("RGBA")
        transparent, partial, opaque = alpha_counts(upper)
        total = upper.width * upper.height
        assert upper.getchannel("A").getextrema() == (0, 255)
        assert abs(
            100 * transparent / total
            - upper_asset["alpha"]["fullyTransparentPercent"]
        ) < 0.001
        assert abs(
            100 * partial / total
            - upper_asset["alpha"]["partiallyTransparentPercent"]
        ) < 0.001
        assert abs(
            100 * opaque / total - upper_asset["alpha"]["fullyOpaquePercent"]
        ) < 0.001

    lower_asset = assets["lower-flourish-v5-transparent"]
    lower_path = folder / lower_asset["file"]
    with Image.open(lower_path) as image:
        lower = image.convert("RGBA")
        transparent, partial, opaque = alpha_counts(lower)
        assert lower.getchannel("A").getextrema() == (0, 255)
        assert partial == 0
        assert transparent == lower_asset["alpha"]["transparentPixels"]
        assert opaque == lower_asset["alpha"]["opaquePixels"]
        opaque_magenta = sum(
            1
            for red, green, blue, alpha in lower.get_flattened_data()
            if alpha and red > 150 and blue > 150 and green < 100
        )
        assert opaque_magenta == lower_asset["alpha"]["opaqueStrongMagentaPixels"]

    lower_source = folder / assets["lower-flourish-v4-chroma"]["file"]
    with Image.open(lower_source) as source, Image.open(lower_path) as derived:
        assert ImageChops.difference(
            source.convert("RGB"), derived.convert("RGB")
        ).getbbox() is None

    provenance = lower_asset["operation"]["record"]
    assert sha256(folder / provenance["file"]) == provenance["sha256"]

    combined = manifest["combinedReview"]
    review_path = folder / combined["file"]
    review_text = review_path.read_text()
    assert sha256(review_path) == combined["sha256"]
    lower_name = Path(lower_asset["file"]).name
    upper_name = Path(upper_asset["file"]).name
    assert review_text.count(upper_name) == 2
    assert review_text.count(lower_name) == 2
    assert "<canvas" not in review_text.lower()
    assert "data:image" not in review_text.lower()
    assert "http://" not in review_text.lower()
    assert "https://" not in review_text.lower()
    for live_text in (
        "NUOVA PARTITA",
        "OPZIONI PARTITA",
        "GIOCATORI DISPONIBILI",
        "SQUADRA 1",
        "SQUADRA 2",
        "INIZIA PARTITA",
    ):
        assert live_text in review_text

    render_results = []
    for render in combined["renders"]:
        path = folder / render["file"]
        assert sha256(path) == render["sha256"]
        with Image.open(path) as image:
            assert list(image.size) == render["viewport"]
        render_results.append(
            {
                "file": render["file"],
                "viewport": render["viewport"],
                "hash": "matched",
            }
        )

    report = {
        "passed": True,
        "revision": "setup-r2",
        "approval": manifest["approval"],
        "reference": "matched",
        "approvedLayers": {
            "teamStage": upper_asset["sha256"],
            "lowerFlourish": lower_asset["sha256"],
        },
        "assets": asset_results,
        "combinedReview": {
            "approval": combined["approval"],
            "hash": "matched",
            "offline": True,
            "renders": render_results,
        },
        "checks": [
            "exact reference and crop hashes",
            "all candidate and approved asset hashes, dimensions, and modes",
            "exact approved-layer alpha properties",
            "lower v5 RGB identity with v4 source",
            "no opaque strong-magenta lower pixels",
            "lower provenance hash",
            "offline combined review with separate live fixture UI",
            "combined render dimensions and hashes",
        ],
        "limitation": (
            "Structure, provenance, and retained render hashes do not imply "
            "combined visual approval or running Flutter validation."
        ),
    }
    write_report(folder, report)
    return report


reports = [check_setup_r1(), check_setup_r2()]
print(json.dumps({"passed": True, "revisions": reports}))

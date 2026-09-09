# South Africa 2010 artwork

R1 artwork was **approved by the user on 2026-09-07** at the five SVG hashes recorded in the manifest. Open [the review](r1/review.html) or inspect [the manifest](r1/manifest.json). The root DESIGN.md remains the design authority. This folder contains approved editable SVG masters and review geometry, not a new approved visual direction.

## Inventory

| File | Role | Integration |
| --- | --- | --- |
| foosball-figure.svg | Rigid tabletop figure with head/body/foot groups | Use as a single rigid figure; head/body/foot IDs are editing aids, not a human animation rig |
| foosball-rod.svg | Same figure mounted on its own rod layer | Main header decoration; small translations permitted during splash only |
| football.svg | Football with outline, seams and panels | Rotate/translate as one mark during splash; decorative use only |
| ribbon-header.svg | Yellow/green/blue/red sweep | Reference paths for a shared Flutter painter |
| ribbon-corner.svg | Bottom-left tapered sweep | Reference paths for a shared Flutter painter |

All SVGs have transparent backgrounds, finite viewBoxes, literal palette colors, named groups and no font/text rendering, external resources, filters, bitmap content or scripts. The figure master is duplicated into the assembly deterministically by the authoring script; keep the two geometries synchronized if revised. Assembly player origin is (194,12); figure pivot is (50,80), assembly pivot (244,92); football pivot (60,60). Transform the figure rigidly. Do not spin individual limbs.

Normal use: figure at least 48px high, assembly approximately 120–160px wide in a header, football at least 24px. The review deliberately also shows the figure at 24px to reveal its lower-size limit. Transparent separation around the foot is intentional. On a dark/blue surface, a single white override can supply a reversed monochrome mark; no new file is required. The reviewer sees this variant too. Avoid multi-color recoloring of the figure.

The review header is 402px wide with a compact title and bounded decoration. It is a composition study, not replacement product UI. Use Flutter text and safe areas in the app. Do not ship the review screenshots as backgrounds. The browser replay only illustrates a proposed layer movement; Flutter lifecycle, gesture and reduced-motion tests remain required.

## Provenance and review contract

These are original vector shapes authored for this repository, informed by the approved generated mockups. No official tournament logo or separate downloaded illustration is included. No third-party artwork license has been introduced. Fonts remain in the existing design/experiments/south-africa-2010/type folder with their OFL licenses. Exact asset hashes and IDs are in the revision manifest.

Every new or materially revised illustration must be presented to the user before integration. Record explicit approval against the exact revision and hashes; do not infer approval from passing structural QA. If changes are requested, keep R1 as the reviewed reference and produce R2; update the manifest and design references accordingly. The PNG contact sheet is a review export, not a runtime asset requiring a raster pipeline.

No shaded hero PNG or stadium master was required by the original four layouts. The later Home extension created the concrete need and its H2 PNG is separately approved below. Functional icons, avatars, scores, badges, buttons and confetti remain widgets/painter geometry.

The approved SVG geometry is frozen. The entrance study was adjusted after review to place the smaller football at the mounted figure’s foot before its short outward roll; this changes only browser composition/timing, not the approved assets. The user explicitly approved this corrected entrance replay. It is the implementation reference; final Flutter motion remains subject to runtime validation. The authoring script refuses to overwrite approved R1 masters; future changes need a new revision.

Runtime mapping: the approved hashes are checked by `tool/generate_south_africa_artwork.py` before compiling paths into Dart. `SouthAfricaArtwork` paints those paths; `FootOriginEntrance` supplies the reviewed ball composition. Fonts are also bundled in `assets/fonts/` with their OFL licenses. No generated mockup PNG is a production background.

## Home composition H1 — pending review

The [Home H1 review](home-r1/review.html) presents two new, text-free SVG compositions derived from the exact leftmost-phone reference supplied on 2026-09-09. [Its manifest](home-r1/manifest.json) records the attachment hash, frozen R1 inputs and exact H1 hashes. `home-hero.svg` arranges four rigid foosball figures and rods, the approved football geometry and one new asymmetric ribbon field. `home-brand-flare.svg` is a small three-path accent; the wordmark and approved tagline remain live type.

H1 is **not approved or integrated**. The review page uses live HTML fixture content only to assess scale and hierarchy at 402 × 874 and 320 × 568. Do not treat its names, scores, dates, totals or navigation glyphs as asset content. After explicit approval, reproduce the compositions through the existing generated painter/path system; do not add an SVG runtime or ship the review page/screenshots.

## Home raster direction H2 — approved

The [H2 raster review](home-h2/review.html) presents the user's preferred PNG direction against H1. Its approved hero is a 1516 × 1038 sRGBA PNG generated with the built-in image tool from the exact left-phone reference. It introduces restrained dimensional shading and yellow rim light while keeping four figures mounted on rods, the football and the ribbon sweep. The [H2 manifest](home-h2/manifest.json) records the prompts, exact hash, rejected direct-transparency attempt and deterministic alpha extraction.

H2 was **explicitly approved by the user on 2026-09-09** at SHA-256 `44530a3c4f352a2cb2a413c529c3b002b125a345045fd2e874bf386158dd73de`. The built-in tool's direct transparency attempt baked a checkerboard and was rejected. A subsequent flat-magenta precision edit was converted to real alpha using the bundled deterministic chroma-key workflow, then losslessly optimized. Wordmark, tagline, CTA label/icon, data rows and navigation remain Flutter widgets; none are embedded in the PNG. Any pixel, alpha, dimension or encoding change creates a new revision and requires renewed approval.

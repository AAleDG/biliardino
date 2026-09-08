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

No shaded hero PNG or stadium master is required by the approved four layouts. Add one only for a concrete layout need and present it for approval. Functional icons, avatars, scores, badges, buttons and confetti remain widgets/painter geometry.

The approved SVG geometry is frozen. The entrance study was adjusted after review to place the smaller football at the mounted figure’s foot before its short outward roll; this changes only browser composition/timing, not the approved assets. The user explicitly approved this corrected entrance replay. It is the implementation reference; final Flutter motion remains subject to runtime validation. The authoring script refuses to overwrite approved R1 masters; future changes need a new revision.

Runtime mapping: the approved hashes are checked by `tool/generate_south_africa_artwork.py` before compiling paths into Dart. `SouthAfricaArtwork` paints those paths; `FootOriginEntrance` supplies the reviewed ball composition. Fonts are also bundled in `assets/fonts/` with their OFL licenses. No generated mockup PNG is a production background.

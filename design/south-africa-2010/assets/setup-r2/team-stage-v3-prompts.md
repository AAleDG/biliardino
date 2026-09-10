# setup-r2 team-stage v3 generation chain

## Geometry revision from rejected v1

Use case: precise-object-edit

Asset type: transparent decorative PNG layer behind live Flutter team cards

Input images: Image 1 is the rejected edit target; Image 2 is the authoritative close-up reference crop from the middle phone. Follow Image 2 for scale, restraint, positions, ribbon direction, and white separators.

Primary request: Replace the artwork in Image 1 with a MUCH MORE RESTRAINED team-stage ribbon composition matching Image 2. Remove the oversized circular/oval ribbon loops entirely. The blue and orange rounded team-card masses visible in Image 2 are live UI and MUST NOT be drawn into this PNG.

Required composition: mostly transparent canvas. At the far left, one broad dark-to-cobalt-blue sweep enters from the left edge and curves behind only the upper/outer shoulder of the future blue card. At the upper right, a yellow sweep with a nearby orange sweep enters from the right/top-right edge and curves behind only the upper/outer shoulder of the future orange card. In the narrow gap between future cards, include a slim green blade with a WHITE separation near the upper center, plus a restrained lower central fan rising from the bottom edge: green blade, WHITE separator, yellow blade, WHITE separator, red blade, with a small orange/yellow edge on the right. Match the placements and relative thicknesses from Image 2. Ribbons may extend underneath where live cards will cover them, but must not surround or outline the card areas.

Composition/framing: transparent 4:3 canvas matching Image 1 dimensions; leave the two large future card rectangles almost entirely transparent; preserve a clear narrow central corridor for live VS text; artwork occupies only the outer shoulders and narrow central/bottom areas, approximately the restrained visual amount seen in Image 2.

Style/medium: crisp polished flat poster illustration, smooth high-resolution edges, saturated colors, subtle depth only where present in the reference

Constraints: genuine alpha transparency; decorative ribbon shapes only; preserve the transparent background. No ivory/black/white background fill. White is permitted ONLY as narrow opaque separator ribbons between colored shapes, exactly as visible in Image 2. No team-card panels, rounded rectangles, player rows, people, icons, letters, VS text, other text, numbers, football, phone hardware, navigation, logo, or watermark. Do not reproduce the UI. Change only the ribbon artwork; keep this as the upper/team-stage asset.

## Alpha correction after invalid baked-checker output

Use case: background-extraction

Asset type: corrected transparent decorative PNG for a Flutter UI

Input image: this is the exact edit target. Preserve every colored and white ribbon shape, position, scale, curvature, overlap, edge crop, and color exactly as shown.

Primary request: remove ONLY the gray checkerboard background and convert all checkerboard/background pixels into genuine alpha transparency. The checkerboard is not artwork. Do not redraw, rearrange, add, remove, thicken, thin, recolor, or crop any ribbon.

Constraints: output an RGBA PNG with actual transparent pixels wherever the checkerboard currently appears. Keep the narrow opaque white separator ribbons as artwork; remove only gray checker squares and gray checker texture. No replacement background, no checkerboard, no ivory, no black fill. Add no text, UI, cards, football, icons, people, hardware, logos, or watermark. This is a surgical background extraction; change nothing else.

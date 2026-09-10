# Lower flourish v5 provenance

- Date: 2026-09-10
- Scope: decorative lower ribbon-and-football layer for the `Nuova Partita` setup screen
- Exact visual reference crop: `reference/lower-flourish-user-crop.png`, SHA-256 `5cfb22958cb7fdfc2ab0d527d6d66f3859669b74c3330cfb03c4260ee986d71f`
- Content boundary: ribbons and football only. The green start action, all text, team cards, navigation, phone hardware, and other controls remain live Flutter UI.

## Generation chain

1. `lower-flourish-v1.png` was generated with built-in ImageGen from the exact crop and full supplied board. The brief required the lower yellow/green/red/blue/black ribbon sweep and cropped football, extensive empty area above, no UI/text/hardware, and transparent negative space. The composition was retained, but the output was opaque RGB with a baked irregular checkerboard.
2. `lower-flourish-v2.png` and `lower-flourish-v3.png` were surgical ImageGen background-extraction attempts. Both remained opaque RGB; v3 provided the cleanest retained composition.
3. `lower-flourish-v4-chroma.png` was a surgical ImageGen edit of v3 that replaced only the checkerboard field with a near-flat magenta key. It remained an opaque RGB intermediate and is not suitable for runtime use.
4. A GIMP select-by-color workflow was attempted against v4. No GIMP export was accepted because the clear action could not be verified reliably; the source and candidate files were left unchanged.
5. At the user's suggestion, `lower-flourish-v5-transparent.png` was derived programmatically from immutable v4 with Pillow/NumPy. RGB bytes are copied unchanged. Only the alpha channel is authored: pixels are transparent when `min(R,B) > 25`, `max(R,B)/min(R,B) < 3.5`, and `((R+B)/2)-G > 25`; all other pixels are opaque. This removes the magenta key and preserves the artwork colors without color-to-alpha spill into the football panels.

## Validation

- Dimensions: 1448 x 1086
- Format: PNG RGBA 8-bit
- Alpha values: binary `{0, 255}`
- Transparent pixels: 1,179,894
- Opaque pixels: 392,634
- Opaque strong-magenta pixels: 0
- SHA-256: `bb0c574dc80cdebeb47252cf100a05d6732001ac13fe75791706c530ccd3cc8a`
- Review renders: full-resolution ivory, checkerboard, and a 460 x 260 reference-scale context with a separately drawn button
- Approval: explicitly approved by the user on 2026-09-10 for this exact PNG. Combined setup composition and runtime integration remain separate gates.

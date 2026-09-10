# Team-stage v10 GIMP edit record

- Date: 2026-09-10
- Source: `candidates/team-stage-v3.png`
- Source SHA-256: `e85c845233cd5194d938bc7661567929778e6b6fe00460421be97c6b57fbe2b6`
- Output: `candidates/team-stage-v10-gimp-white-to-alpha.png`
- Output SHA-256: `45b320cee3d42d4140f3bd8787159e28bba10f56aa4ac2b1aefb2af5be91ee4d`
- Tool: GIMP 3.0.6 for macOS, controlled through direct computer use
- Operation: `Colors > Color to Alpha…`
- Selected color: white (`#FFFFFF`)
- Transparency threshold: `0.000`
- Opacity threshold: `1.000`
- Generative edit: none

The operation removes the white contribution into alpha without reconstructing,
recoloring, moving, expanding, or cropping the ribbon geometry. The original v3
file remains unchanged. The resulting PNG keeps the 1448 x 1086 RGBA canvas.

Validation:

- original-resolution GIMP preview inspected before applying the filter;
- exported PNG inspected on canonical ivory, checkerboard, and beneath separate
  live-style team cards;
- alpha range remains 0-255, with 80.961% fully transparent, 19.013% partially
  transparent, and 0.026% fully opaque pixels;
- composition over white differs from the original v3 white composite by a
  normalized mean absolute channel error of `0.0000800208`, attributable to the
  color-to-alpha/export rounding;
- user explicitly approved the GIMP live preview as “perfect” before export and
  asked for the saved-file verification.

This approval covers only this exact team-stage PNG. It does not approve the
not-yet-generated lower ribbon/football flourish, combined setup composition, or
runtime integration.

# team-stage v9 mechanical edit

Source: `candidates/team-stage-v3.png`

Operation host: Blender MCP with NumPy and ImageMagick byte I/O. No generative model was called.

Deterministic operation:

1. Read the 1448 x 1086 PNG as unmodified 8-bit RGBA bytes.
2. Select visible low-saturation separator pixels where alpha is greater than 16, maximum RGB is greater than 100, and RGB chroma is at most 80.
3. Expand that separator mask by eight pixels into visible artwork to include the antialiased separator fringe.
4. For every connected repair region, find the Euclidean-nearest source pixel from a nearby saturated ribbon interior where alpha is at least 240 and chroma is greater than 100.
5. Copy that source pixel's complete RGBA value into the repair region. Preserve every pixel outside the repair mask byte-for-byte.

Validation:

- Separator core: 45,249 pixels.
- Repair band: 90,831 pixels.
- Changed: 87,951 pixels, all inside the repair band.
- Pixels outside the repair band: byte-identical to v3.
- Fully transparent exterior: identical to v3 (1,271,903 pixels).
- Original v3 remains preserved as the source artifact.
- Intermediate failed cleanup attempts were moved to Trash and are recoverable; they are not approval candidates.

"""User-authorized chroma extraction; preserve original source and dimensions."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

parser = argparse.ArgumentParser()
parser.add_argument('source', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
if args.output.exists():
    raise SystemExit('Refusing to overwrite an existing candidate')
source = Image.open(args.source).convert('RGB')
rgb = np.asarray(source, dtype=np.float64)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
excess = np.minimum(r, b) - g
key = (r > 240) & (b > 240) & (g < 20) & (excess > 230)
if key.mean() < .1:
    raise SystemExit('Source does not have the required flat magenta background')
# Only adjust the keyed region and its two-pixel boundary. Object interiors
# retain the original RGB values, including white/yellow football panels.
near_key = (np.asarray(Image.fromarray((key * 255).astype('uint8')).filter(ImageFilter.MaxFilter(5))) > 0) | (excess > 8)
alpha = np.ones(r.shape, dtype=np.float64)
alpha[near_key] = 1 - np.clip(excess[near_key] / 255, 0, 1)
magenta = np.array([255., 0., 255.])
# Estimate antialiased coverage against the closest solid foreground sample.
# This avoids a pink fringe on yellow edges, which a simple hue threshold misses.
ys, xs = np.nonzero(near_key & ~key)
resolved = np.zeros(len(ys), dtype=bool)
foreground = rgb[ys, xs].copy()
offsets = sorted(((dy, dx) for dy in range(-6, 7) for dx in range(-6, 7)),
                 key=lambda pair: pair[0]**2 + pair[1]**2)
for dy, dx in offsets:
    iy = np.clip(ys + dy, 0, source.height-1)
    ix = np.clip(xs + dx, 0, source.width-1)
    take = ~resolved & ~near_key[iy, ix]
    foreground[take] = rgb[iy[take], ix[take]]
    resolved[take] = True
    if resolved.all():
        break
direction = foreground - magenta
denominator = np.sum(direction*direction, axis=1)
coverage = np.sum((rgb[ys, xs]-magenta)*direction, axis=1) / np.maximum(denominator, 1)
alpha[ys[resolved], xs[resolved]] = np.clip(coverage[resolved], 0, 1)
alpha[key] = 0
alpha[alpha < .015] = 0
edge = (alpha > 0) & (alpha < 1)
out = rgb.copy()
out[edge] = np.clip((rgb[edge] - (1-alpha[edge, None])*magenta) / alpha[edge, None], 0, 255)
spill = np.maximum(np.minimum(out[..., 0], out[..., 2]) - out[..., 1], 0)
spill[~near_key] = 0
out[..., 0] -= spill
out[..., 2] -= spill
out[alpha == 0] = 0
rgba = np.dstack([np.rint(out).astype('uint8'), np.rint(alpha*255).astype('uint8')])
image = Image.fromarray(rgba)
image.save(args.output)
for name, color in [('ivory', '#F8F5EB'), ('white', '#FFFFFF'), ('dark', '#111111')]:
    background = Image.new('RGBA', image.size, color)
    background.alpha_composite(image)
    background.convert('RGB').save(args.output.with_name(args.output.stem + '-' + name + '.png'))
report = {
    'sourceSha256': hashlib.sha256(args.source.read_bytes()).hexdigest(),
    'outputSha256': hashlib.sha256(args.output.read_bytes()).hexdigest(),
    'method': 'flat magenta key, boundary alpha and magenta decontamination; unchanged interiors',
    'dimensionsUnchanged': image.size == source.size,
    'interiorRgbUnchanged': bool(np.array_equal(rgba[~near_key, :3], np.asarray(source)[~near_key])),
    'transparentPixels': int((rgba[..., 3] == 0).sum()),
    'partialAlphaPixels': int(((rgba[..., 3] > 0) & (rgba[..., 3] < 255)).sum()),
    'opaquePixels': int((rgba[..., 3] == 255).sum()),
    'approval': 'pending-user-review',
}
args.output.with_suffix('.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))

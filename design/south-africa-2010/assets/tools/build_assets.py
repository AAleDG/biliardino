from pathlib import Path
import json, hashlib
root=Path(__file__).resolve().parents[4]
out=root/'design/south-africa-2010/assets/r1'
ink='#111111'
figure='''<g id="figure" fill="#111111">
  <circle id="head" cx="50" cy="28" r="21"/>
  <path id="body" d="M39 47 C22 50 15 63 16 79 L22 110 Q28 130 35 160 L65 160 Q72 130 78 110 L84 79 C85 63 78 50 61 47 L61 51 Q50 57 39 51 Z"/>
  <path id="foot" d="M29 167 Q29 162 36 162 H64 Q71 162 71 167 L66 199 Q65 207 50 207 Q35 207 34 199 Z"/>
</g>'''
assembly=f'''<g id="rod" fill="{ink}"><path d="M8 104 L352 70 Q357 70 358 76 Q358 82 352 83 L9 117 Q3 117 2 111 Q2 105 8 104 Z"/></g>
<g id="player" transform="translate(194 12)">{figure}</g>'''
ball='''<g id="ball" fill="none" stroke="#111111" stroke-width="4" stroke-linejoin="round">
  <circle id="outline" cx="60" cy="60" r="52"/>
  <g id="seams"><path d="M60 39 L80 54 L72 78 H48 L40 54 Z M60 39 V20 M80 54 L99 47 M72 78 L84 95 M48 78 L36 95 M40 54 L21 47"/></g>
  <g id="panels" fill="#111111" stroke="none"><path d="M60 39 L80 54 L72 78 H48 L40 54 Z M46 10 Q60 6 74 10 L72 20 H48 Z M10 43 L21 40 L25 50 L9 64 Z M110 43 L99 40 L95 50 L111 64 Z M25 99 L32 87 L43 91 L45 110 Z M95 99 L88 87 L77 91 L75 110 Z"/></g>
</g>'''
header='''<path id="yellow" fill="#FFC700" d="M0 10 C87 71 213 52 402 6 V15 C227 63 100 103 0 44 Z"/>
<path id="green" fill="#087F3E" d="M0 50 C111 107 234 65 402 20 V31 C259 74 126 133 0 83 Z"/>
<path id="blue" fill="#0057B8" d="M134 104 C243 85 326 40 402 37 V50 C337 50 302 73 254 102 Z"/>
<path id="red" fill="#C62828" d="M274 104 C325 81 367 56 402 56 V61 C363 75 336 94 317 104 Z"/>'''
corner='''<path id="yellow" fill="#FFC700" d="M0 0 C62 77 155 116 300 132 H243 C114 115 43 84 0 44 Z"/>
<path id="green" fill="#087F3E" d="M0 53 C54 98 127 121 229 132 H153 C84 114 35 97 0 80 Z"/>
<path id="blue" fill="#0057B8" d="M0 87 C46 107 82 122 132 132 H69 C41 123 19 113 0 104 Z"/>
<path id="red" fill="#C62828" d="M0 111 L50 132 H0 Z"/>'''
entries=[
('foosball-figure','0 0 100 220',figure,'Reusable rigid figure', 'Header/splash figure; black silhouette. Do not articulate limbs like a human mascot.',{'pivot':[50,80],'layers':['figure','head','body','foot']},'runtime-master'),
('foosball-rod','0 0 360 240',assembly,'Foosball figure and rod','Header decoration; title stays outside this artwork. The rod is separate from the rigid figure.',{'pivot':[244,92],'layers':['rod','player'],'figureTranslation':[194,12]},'runtime-master'),
('football','0 0 120 120',ball,'Football mark','Splash and optional decorative goal/result accent; preserve existing functional icons.',{'pivot':[60,60],'layers':['ball','outline','seams','panels']},'runtime-master'),
('ribbon-header','0 0 402 112',header,'Header ribbon sweep','Reusable geometry reference for responsive CustomPainter; transparent gaps reveal parent background.',{'layers':['yellow','green','blue','red']},'geometry-reference'),
('ribbon-corner','0 0 300 132',corner,'Corner ribbon sweep','Optional clipped bottom-left decoration, behind content and excluded from input/semantics.',{'layers':['yellow','green','blue','red']},'geometry-reference')]
manifest={'revision':'R1','approval':'pending-user-review','source':'Root DESIGN.md and approved four South Africa 2010 mockups','authoring':'Original SVG path/primitive artwork authored for this repository; no ImageGen or raster tracing used for these masters. Existing mockups were generated previously.','palette':['#111111','#FFC700','#087F3E','#0057B8','#C62828'],'assets':[]}
for stem,vb,body,title,use,animation,role in entries:
 text=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}">\n<title>{title}</title>\n{body}\n</svg>\n'
 p=out/'svg'/f'{stem}.svg';p.write_text(text)
 manifest['assets'].append({'id':stem,'file':f'svg/{stem}.svg','role':role,'viewBox':vb,'use':use,'animation':animation,'sha256':hashlib.sha256(text.encode()).hexdigest(),'approval':'pending-user-review','minimumDisplay': '48px high' if stem.startswith('foosball') else ('24px square' if stem=='football' else 'responsive decoration')})
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(root/'design/south-africa-2010/assets/README.md').write_text('''# South Africa 2010 artwork

R1 is **pending user approval**. Open [the review](r1/review.html) or inspect [the manifest](r1/manifest.json). The root DESIGN.md remains the design authority. This folder contains editable SVG candidates and review geometry, not a new approved visual direction.

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
''')

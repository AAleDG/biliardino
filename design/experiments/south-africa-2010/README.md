# South Africa 2010 — design review packet

Prepared 7 September 2026 for [issue 11](https://gitlab.nttdata-emea.com/italy/solution-services/mobile-creative-technology/nextgen/table-football/-/work_items/11). **The user approved the four mockups and design baseline on 2026-09-07.** This packet makes no application-code, dependency or persisted-data changes.

Open [the offline gallery](gallery.html) to compare and enlarge the four mockups, inspect the proposed palette and see real font specimens. Images and font files are embedded in the gallery; sibling document/download links work from this folder.

| Deliverable | Purpose |
| --- | --- |
| [Players](mockups/01-players.png) | Actual six-player roster and presence controls |
| [Match setup](mockups/02-match-setup.png) | Upper/lower scroll positions covering mode, rules, complete teams, rivalry availability and all four assignments |
| [Live match](mockups/03-live-match.png) | 9–10, win-by-two, both add/undo controls and disabled result registration |
| [Leaderboard](mockups/04-leaderboard.png) | Current scorer data/badges with a compact podium |
| [DESIGN.md](../../../DESIGN.md) | Approved tokens, layout, component states, motion, artwork and Flutter mapping |
| [Research](RESEARCH.md) | Google format suitability, sources, tooling and limits |
| [Mockup brief](MOCKUP_BRIEF.md) | Exact example state, review questions and required later states per screen |
| [Prompts](prompts.json) / [provenance](generation.json) | Built-in ImageGen prompts, input roles, source files and the live-screen correction |

## What was checked

The generated images were visually inspected for names, presence/selection states, both team assignments, scores, buttons, existing badge labels and five-tab navigation. The live-screen correction restored the exact +1 GOAL label and improved disabled-button text contrast. All final images are copied into this packet; original generated files were left intact. The offline gallery was rendered in headless Chrome at 1600 × 1280 and visually inspected for image loading and layout.

The document passes Google DESIGN.md CLI **0.4.0** with **0 errors and 0 warnings**. The saved result is [design-lint.json](design-lint.json). Reproduce from the repository root:

```sh
npx --yes --package @google/design.md@0.4.0 designmd lint DESIGN.md
```

## Known prototype limitations

- Lettering is generated and not an exact rendering of Barlow; the gallery's separate specimens use the real files.
- Minor texture/shading and icon inconsistencies are raster artifacts, not approved design rules. Preserve existing functional iconography in Flutter; for example the live mockup keeps Annulla but omits its minus icon.
- The setup board uses schematic panel proportions. Its two views specify content and hierarchy, not final measured phone geometry or proven touch-target sizes.
- Color pairs in the document have been checked; that does not validate every pixel or composited state of a generated image.
- No animation footage or Flutter implementation was produced. Motion timing, interruptions, reduced motion, large text, VoiceOver and full functional regressions require later implementation review.

## Worktree checkpoint

The user approved the design and requested a separate worktree before deciding the next implementation steps.

- Branch: codex/south-africa-2010-design-implementation.
- Fetched base: origin/codex/south-africa-2010-design-implementation at ad701db6dc49b2828696c7eee6831135508df0f9.
- Canonical specification: the worktree root DESIGN.md.
- Current scope: approved design checkpoint only. Application implementation has not started.
- Next step: decide the implementation sequence from this isolated checkout.

This packet and the root specification are scoped to issue 11. Italia ’90 exploration files were not brought into this worktree.

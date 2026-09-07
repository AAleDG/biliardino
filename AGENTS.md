# South Africa 2010 design work

Read the root `DESIGN.md` before changing UI, themes, assets or motion. It is the canonical, user-approved South Africa 2010 design baseline for issue #11. The four mockups were approved on 2026-09-07; application implementation has not started at this checkpoint.

The review packet is in `design/experiments/south-africa-2010/`. Read its `MOCKUP_BRIEF.md` for example states and `README.md` for provenance, validation and known raster limitations. The packet's nested `DESIGN.md` is only a pointer to the canonical root file.

Keep visual decisions in the root specification and map its tokens into reusable Flutter components. Preserve the existing navigation, labels, match rules, data model and behavior. Follow the South Africa 2010 direction only; the separate Italia '90 experiment is outside this branch's scope. Generated sample content is not a feature specification.

Validate specification changes with `npx --yes --package @google/design.md@0.4.0 designmd lint DESIGN.md`. Application implementation requires meaningful widget/golden coverage, `flutter analyze`, `flutter test`, and iPhone simulator review including large text, VoiceOver and reduced motion.

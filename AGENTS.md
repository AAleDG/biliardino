# South Africa 2010 design work

Read the root `DESIGN.md` before changing UI, themes, assets or motion. It is the canonical, user-approved South Africa 2010 design baseline for issue #11. The four mockups were approved on 2026-09-07; all screen migrations are implemented; consult the active packet and implementation receipt for verification status.

The review packet is in `design/experiments/south-africa-2010/`. Read its `MOCKUP_BRIEF.md` for example states and `README.md` for provenance, validation and known raster limitations. The packet's nested `DESIGN.md` is only a pointer to the canonical root file.

The active local execution packet is `.agent-work/feature-plans/south-africa-2010/` (ignored, never commit). Read its plan, progress/resume state and active runbook before continuing the refactor. New artwork is in `design/south-africa-2010/assets/`; the user requires explicit approval of newly created assets before integration. The user explicitly approved all five R1 SVG assets on 2026-09-07; the manifest records their exact hashes. New or materially revised assets still require approval. Keep asset approval status current when the user reviews them.

Keep visual decisions in the root specification and map its tokens into reusable Flutter components. Preserve the existing navigation, labels, match rules, data model and behavior. Follow the South Africa 2010 direction only; the separate Italia '90 experiment is outside this branch's scope. Generated sample content is not a feature specification.

Validate specification changes with `npx --yes --package @google/design.md@0.4.0 designmd lint DESIGN.md`. Application implementation requires meaningful widget/golden coverage, `flutter analyze`, `flutter test`, and iPhone simulator review including large text, VoiceOver and reduced motion.

## Simulator for this feature

Use only **iPhone 17 Pro Max**, running iOS 26.5, UDID `9BD8A107-8FB1-4B79-83FC-9400DE997961`, for development and simulator validation of the South Africa 2010 feature. This replaces the retired iOS 26.0 device following the user-authorized simulator migration on 2026-10-01.

Target that UDID explicitly in Flutter, simctl, screenshot and UI-automation commands; never use the ambiguous `booted` selector when multiple simulators are running. Boot this device when needed; do not create, clone, boot or select another simulator for this feature. If this device is unavailable, record the issue and continue only work that does not require a simulator until it is available again. Preserve its existing app data; isolate synthetic validation fixtures at the application/test-data level rather than by creating a different simulator. Compact-screen coverage stays in widget/golden test viewports.

## Runtime style foundation

On `codex/runtime-style-selection`, resume foundation work from the ignored `.agent-work/feature-plans/runtime-style-selection/` packet when present. Its `progress.md` and `implement.md` own execution state; the older South Africa packet reference above applies to the design migration. `PROJECT_DOCUMENTATION.md` owns the presentation architecture and its current limitations.

This increment registers South Africa only and keeps the selector hidden. Preserve the South Africa source UI and existing golden baselines; do not import Italia assets or screens as part of foundation completion. Route new presentation entrypoints through the existing presentation boundary while keeping repositories, Cubits and the Navigator stable. Cross-style local-state transfer needs separate validation when another presentation is introduced.

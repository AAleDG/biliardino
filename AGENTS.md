# South Africa 2010 design work

Read the root `DESIGN.md` before changing UI, themes, assets or motion. It is the canonical, user-approved South Africa 2010 design baseline for issue #11. The four mockups were approved on 2026-09-07; application implementation has not started at this checkpoint.

The review packet is in `design/experiments/south-africa-2010/`. Read its `MOCKUP_BRIEF.md` for example states and `README.md` for provenance, validation and known raster limitations. The packet's nested `DESIGN.md` is only a pointer to the canonical root file.

The active local execution packet is `.agent-work/feature-plans/south-africa-2010/` (ignored, never commit). Read its plan, progress/resume state and active runbook before continuing the refactor. New artwork is in `design/south-africa-2010/assets/`; the user requires explicit approval of newly created assets before integration. The user explicitly approved all five R1 SVG assets on 2026-09-07; the manifest records their exact hashes. New or materially revised assets still require approval. Keep asset approval status current when the user reviews them.

Keep visual decisions in the root specification and map its tokens into reusable Flutter components. Preserve the existing navigation, labels, match rules, data model and behavior. Follow the South Africa 2010 direction only; the separate Italia '90 experiment is outside this branch's scope. Generated sample content is not a feature specification.

Validate specification changes with `npx --yes --package @google/design.md@0.4.0 designmd lint DESIGN.md`. Application implementation requires meaningful widget/golden coverage, `flutter analyze`, `flutter test`, and iPhone simulator review including large text, VoiceOver and reduced motion.

## Simulator for this feature

Use only the existing **iPhone 17 Pro Max 26.0 AppStore** simulator, running iOS 26.0, UDID `293A02E2-FC2D-4D72-93E4-C1EE93CA537E`. The user explicitly selected this already-open device for all development and simulator validation of the South Africa 2010 feature.

Target that UDID explicitly in Flutter, simctl, screenshot and UI-automation commands; never use the ambiguous `booted` selector when multiple simulators are running. Do not create, clone, boot or select another simulator for this feature. If this device is unavailable, record the issue and continue only work that does not require a simulator until it is available again. Preserve its existing app data; isolate synthetic validation fixtures at the application/test-data level rather than by creating a different simulator. Compact-screen coverage stays in widget/golden test viewports.

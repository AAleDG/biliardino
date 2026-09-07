# Google DESIGN.md — suitability for Biliardino

Research date: 2026-09-07. Primary sources only. Recommendation: adopt a provisional DESIGN.md for this experiment, then revise it after the user validates the four mockups.

## Findings

Google's format combines optional YAML tokens with Markdown rationale. Exact values belong in tokens; prose explains their application. The defined groups cover colors, typography, spacing, rounded corners and component properties, with references such as `{colors.primary}`. Its eight ordered core sections cover identity through practical guardrails. Additional sections can be preserved, which lets us document motion and asset responsibilities. [Format specification](https://github.com/google-labs-code/design.md/blob/9bf8eae67128b6cc55ad9bf86665767deb4c11cd/docs/spec.md)

The official CLI can lint, compare revisions and export DTCG or Tailwind tokens. It checks references, structure and specified component foreground/background pairs; it does not offer a Flutter exporter. The format remains alpha. The npm release available during this review was **0.4.0**; upstream main resolved to **9bf8eae67128b6cc55ad9bf86665767deb4c11cd**. Pin the CLI invocation for reproducibility rather than adding a dependency to the application. [Official repository and CLI reference](https://github.com/google-labs-code/design.md/blob/9bf8eae67128b6cc55ad9bf86665767deb4c11cd/README.md), [published package](https://www.npmjs.com/package/@google/design.md/v/0.4.0)

Google presents DESIGN.md as a portable, evolving design description that can carry identity between tools. This supports keeping our decisions in a reviewable document alongside the screen references. [Google announcement](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-design-md/)

## Application to this repository

Use one file for the South Africa 2010 experiment. It must not accidentally govern the existing Italia '90 exploration, so it lives inside this experiment folder during review. When implementation begins, explicitly supply this file as the design authority for the issue's target branch.

Our adaptation uses CSS-style px dimensions as Flutter logical pixels and maps type roles into TextTheme, palette roles into ColorScheme/theme extensions, and component variants into shared widgets. This is an explicit project convention, not a built-in capability of Google's format.

Motion is documented as a project-specific Markdown section with durations, triggers, reduced-motion alternatives and cancellation rules. A second extension assigns each visual element to Flutter geometry, a component, SVG or PNG. Neither extension is claimed to be a standard typed token group or automatically exported to Dart.

The user's current scope permits design documents and generated mockups; application code, dependencies and behavior remain unchanged. Palette and font choices stay provisional. The generated lettering is not proof that a named font was used, and generated colors are not pixel-exact token samples.

## Validation boundary

Lint can catch mistakes in the design document. It cannot validate the actual mockup pixels, Dynamic Type, VoiceOver, tap areas, score transitions, reduced motion, database behavior or performance. Component contrast findings cover only the declared pairs, not composited decoration or all UI states. Keep real widget/golden and simulator validation in the implementation plan.

Version-pinned validation command:

```sh
npx --yes --package @google/design.md@0.4.0 designmd lint DESIGN.md
```

The saved report is [design-lint.json](design-lint.json): **0 errors, 0 warnings** after validation. The first pass flagged a 4.44:1 presence-text pair, which was corrected by using the darker green text value. It also exposed an outline token incorrectly modeled as text; the final component describes the outline fill separately. No Flutter build or regression suite is needed for this documentation-and-mockups turn; those remain required during implementation.

## Approval and worktree update

The user approved the four mockups and design baseline on 2026-09-07. The packet was copied to the dedicated South Africa 2010 branch worktree; the canonical specification was promoted to its root DESIGN.md. The original research above records the pre-approval evaluation.

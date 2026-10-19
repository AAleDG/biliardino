# Shared tab transition reference corrections

These 81 additive snapshots cover MR !25 on the installed Flutter 3.44.9 /
Dart 3.12.2 toolchain. The user authorized correction of style precedence,
behavioral test assertions and reviewed golden updates on 19 October 2026.
The 15 October approvals in root DESIGN.md own the 30dp corners, no internal
separators, 1vs1-first ranking hierarchy and 16/12/24dp spacing.

The captures retain each style's palette, including Italia's blue ranking
selection. Changes are confined to the shared controls and the resulting
ranking viewport/scroll positions. Small changes in other Italia screens
are confined to the shared navigation indicator's edges. No runtime artwork,
fonts, SDK, comparison tolerance or statistical fixtures changed.

All 81 before/after pairs were inspected. Original donor, issue and previously
accepted correction PNGs remain byte-identical. The bounded routing table in
`test/support/tab_transition_goldens.dart` selects only these replacements;
all other comparisons use their existing reference. Comparisons remain exact.
`provenance.json` records both hashes and pixel difference bounds for every pair.

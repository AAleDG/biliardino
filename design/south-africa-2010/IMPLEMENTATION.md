# South Africa 2010 implementation receipt

Updated 8 September 2026. Issue #11. Branch: `codex/south-africa-2010-design-implementation`.

All planned screens and motion are implemented. Automated regression, static analysis, design checks and iOS simulator build pass. Final accessibility acceptance remains open: actual VoiceOver traversal and native reduced-motion on/off/runtime replay could not be completed on the exclusively authorized simulator. This is a local implementation checkpoint, not release or merge approval.

## Delivered scope

| Surface | Implementation and evidence |
| --- | --- |
| Shared foundation | Bundled Barlow/Barlow Condensed with OFL licenses, semantic colors/type/spacing, Material interaction states, approved vector painter, headers and five-tab navigation. Actual-font component goldens and contrast/state tests. |
| Players and setup | Grouped roster, separate profile/presence/menu controls, busy dialogs, adaptive team assignment and rules, persistent kickoff. Existing player/rules/rivalry tests and compact/large-text goldens. |
| Live scoring | Solid team panels, scorer sheet, undo/reset/leave/save/correction behavior preserved. Compact landscape scoring and scroll reachability regression. |
| Motion | Approved foot-origin entrance, coalesced nonblocking goal feedback, immediate victory actions, bounded 36-particle burst, runtime motion policy, cancellation on hidden tab/disposal and safe late-save delivery. Lifecycle tests and inspected simulator frame sequences. |
| History and rankings | Calm history rows, adaptive safe-area filters/details, compact first-visible podium, General/Scorers and real ranking badges, CSV actions. Existing filtering/editing/legacy-scorer tests, podium lifecycle and screen goldens. |
| Profile, data and bootstrap | Adaptive metrics/relationships, existing import/export/retry behavior. Profile/data goldens plus existing backup/database/bootstrap tests. |

Models, Cubits, repositories, database schema and services have no diff from application baseline `ad701db6dc49b2828696c7eee6831135508df0f9`. No timer, theme selector or data migration was added.

## Validation

Environment: local macOS, Flutter 3.44.9 / Dart 3.12.2. Final source checkpoint: `b937a86429233630c5a234f839c4b8c3c94f5af8`. The passing checks ran on its exact source content before the commit; subsequent edits are documentation/evidence only.

| Check | Result |
| --- | --- |
| `flutter test --no-pub --reporter expanded` | 152 tests passed, including retained behavioral regression, new lifecycle/layout tests and reviewed actual-font goldens. |
| `flutter analyze --no-pub` | No issues. |
| Changed Dart formatting and `git diff --check` | Passed. |
| `flutter build ios --simulator --debug --no-pub` | Passed; Xcode build 22.8 seconds. |
| Pinned `@google/design.md@0.4.0` lint | Zero errors and warnings. |
| Approved SVG structure/hash validation | Five masters passed; generated paths byte-identical under the checked compiler, including Python optimization mode. Bundled font bytes match approved specimens. |
| Source review | Main-agent full-diff correctness/reuse/lifecycle review and independent read-only Luna max review of P5 plus the integrated diff from `ad701db`: no material high-confidence defects. The companion did not rerun tests; the main-agent checks above supply validation. |

Widget/golden viewports include 402×874, 320×568 at 200% text, and 568×320 landscape for scorer/goal behavior. These are test viewports, not additional simulators. Real loaded fonts and production widgets are used. New tests do not replace the pre-existing domain/service regression suite.

## Native observations

Only **iPhone 17 Pro Max 26.0 AppStore**, iOS 26.0, UDID `293A02E2-FC2D-4D72-93E4-C1EE93CA537E` was used. A copied build with review-only bundle ID `com.biliardino.southafrica.review` isolates synthetic data; production bundle settings and the user's existing app data remain unchanged.

Observed flows include populated/empty screens, player add/archive/reactivate/profile, assignments/kickoff, successive goals, saved result/rematch, both rankings, history filtering/reset, edit and deletion. JSON export reached Save to Files. Real picker cancellation and restore-confirmation cancellation returned normally. An unsupported backup was rejected with all database rows unchanged. Valid restore removed a temporary player and restored the exact exported six-player/one-match fixture. CSV sharing opened the native sheet and cancellation returned normally; nothing was sent to an external recipient.

Large-text profile/ranking/history/filter layouts were inspected on the device, then the original content-size category `large` was restored. The latest build is installed and left on Players with six synthetic players. History is empty following the tested deletion; the valid export is retained only in the review app/local evidence.

Retained images: [current Players](verification/players-pro-max.png), [corrected entrance frame review](verification/entrance-review.png), [available Accessibility settings](verification/accessibility-settings.png). Entrance frames are from the P4 corrected-motion build; later checks did not modify entrance geometry. Detailed command logs, native captures, data comparisons and replay videos remain in the ignored local execution packet until landing; reviewed regression goldens are tracked under `test/goldens/`.

## Open validation and limits

- **VoiceOver:** the selected simulator's Accessibility menu exposes no VoiceOver session. AX labels/frames were inspected, but no VoiceOver traversal, activation, announcement or focus pass is claimed. Unlock: an operable VoiceOver session on the authorized environment, or explicit authorization for another validation environment.
- **Native reduced motion:** Settings navigation was unstable and toggle attempts continued to read `0`; no native on/off/runtime replay pass is claimed. Automated production-widget tests prove runtime settlement, static goal hold, immediate actions and splash handoff. Unlock: an operable Reduce Motion setting on the selected simulator, then replay entrance/goals/victory and change it while the app is active.
- Debug simulator recordings establish visual sequencing, not physical-device frame-budget performance. No 60fps or profile-mode certification is claimed.

No required scope was waived. P6/P7 remain open for these runtime gates; the implementation is ready for local review, not marked awaiting merge. No push, PR, merge or release was requested or performed.

## Ownership and provenance

[Root DESIGN.md](../../DESIGN.md) owns visuals and motion. [PROJECT_DOCUMENTATION.md](../../PROJECT_DOCUMENTATION.md) owns architecture. [Asset inventory](assets/README.md) and [R1 manifest](assets/r1/manifest.json) own approval, hashes and entrance provenance. All five SVGs and corrected foot-origin entrance were explicitly approved; no unseen artwork is accepted by this receipt.

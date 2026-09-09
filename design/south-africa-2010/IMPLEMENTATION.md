# South Africa 2010 implementation receipt

Updated 9 September 2026. Issue #11. Branch: `codex/south-africa-2010-design-implementation`.

## Home dashboard extension checkpoint — 9 September 2026

The user approved the exact transparent H2 Home hero at SHA-256 `44530a3c4f352a2cb2a413c529c3b002b125a345045fd2e874bf386158dd73de`. Approval covers only the decorative PNG recorded in the [H2 manifest](assets/home-h2/manifest.json); wordmark, tagline, controls, rows and navigation remain live Flutter UI. P9 artwork review, P10 foundation and P11 Home integration are complete. P10 adds typed Home/Giocatori/Partita/Classifica/Altro navigation, full Storico/Dati routes with persistent History filters, preserved match visibility/leave behavior and a reactive dashboard data owner. P11 bundles the approved PNG unchanged and adds the live wordmark/tagline, start-or-resume action, recent results, ranking, empty/sparse/long-name states, destination links and row semantics.

P11 validation adds nine Home widget cases and eight inspected real-font Home goldens across 402×874, 320×568 at 200% text, 568×320 at 200% text, populated/empty and scrolled content states. The complete suite passes 177 tests. The established screen goldens were regenerated for the typed navigation shell and inspected; a stale Players test was corrected to select Giocatori explicitly rather than accepting an accidental Home capture. `flutter analyze --no-pub`, the simulator debug build, the approved H2 hash and `git diff --check` pass at this checkpoint.

P12 hardening reviewed the exact `bdf4201…039795a` Home delivery for destination and match-state consumers, provider/subscription lifecycles, repository-derived data, routes, failure paths, reflow, semantics and artwork provenance. No production defect was found. The only evidenced gap was missing automated coverage of the active-match system-back path, so a widget regression now verifies both cancel and confirmed abort through `PopScope` without changing production behavior. The full suite passes 178 tests; analysis, scoped formatting, design lint, H2 approval/hash/transparency checks, H1 structure/provenance checks and diff whitespace pass. The independent `review-and-simplify-changes` pass found only two behavior-neutral architecture cleanups outside this Home scope; they were not folded into the feature. Because P12 changed no production source or asset, P11 running-app evidence on the authorized simulator remains applicable. P13 final verification and handoff are recorded below.

P13 final review used the user-selected `$autoreview` workflow with `gpt-5.6-sol` at high reasoning and the P0–P3 threshold. Its binary-safety gate correctly refused the mixed PNG/source branch diff, so the code review was rerun against an exact final source tree whose synthetic parent neutralized only the unchanged binary blobs; the real artwork and goldens stayed under their separate hash, transparency, provenance, rendered-inspection and Flutter-golden gates. AutoReview found two P2 Home accessibility defects: custom semantic nodes exposed labels without tap actions, and the fixed 44dp match-date column clipped ordinary dates at 200% text. Production source checkpoint `f239e07` adds semantic activation to the start/resume, recent-result and ranking actions, and uses a wrapping large-text result layout that preserves intrinsic score/date widths. Widget tests now assert the semantic tap actions and the expanded date width. The two affected compact/landscape content goldens were regenerated only after focused tests passed and were visually inspected.

Final verification on that production source passes 179 tests, clean analysis, scoped formatting, `git diff --check`, the simulator debug build in 15.6 seconds, pinned DESIGN lint, all five approved R1 structure/hashes, unchanged generated-vector output, H1 structure/provenance and the exact approved H2 hash/transparency contract. On the exclusively authorized Pro Max, an isolated `com.biliardino.southafrica.review` build preserved its six-player/five-match fixture and the production app data. Accessibility-driven activation opened setup from the Home CTA, Storico from a result row and Paolo's profile from a ranking row. A maximum-accessibility-text capture shows full natural-width dates and wrapped match details without overflow; the original `large` content-size category was restored. The current Accessibility menu still exposes no VoiceOver session, and a direct AX tap on Reduce Motion still reads back `0`; neither native traversal nor native motion toggling/runtime replay is claimed as passed.

On 9 September 2026 the user reviewed this final simulator evidence, accepted the unavailable native VoiceOver traversal and Reduce Motion toggle/runtime replay as deferred checks for a later release-hardening stage, and confirmed the complete South Africa refactor and Home dashboard delivery. These two unverified checks remain explicit limitations; they do not block completion of the current feature branch.

The corrected Home presentation gives the approved 1516×1038 hero the full safe-area width and its intrinsic ratio with contain behavior; the top and bottom are no longer clipped by a mismatched cover frame. The wordmark, action and data retain 16dp gutters. The Home-only action now uses the reference's 72dp capsule, white perimeter, restrained shadow, larger Barlow Condensed lockup and brighter blue without changing shared controls. At 402×874 the full hero means the fifth result and four-entry ranking require scrolling; on the authorized Pro Max all five latest results remain visible in the captured first fold. This is the deliberate approved-token divergence from the poster: 48dp interactive rows and the substantial uncropped hero are not compressed merely to force every row above the fold. Enlarged text stacks section headings and links; navigation label rendering is bounded to keep all five fixed destinations stable while their full accessibility labels remain exposed.

For the original R2 scope, all planned screens and motion are implemented. Automated regression, static analysis, design checks and iOS simulator build pass. Final accessibility acceptance remains open: actual VoiceOver traversal and native reduced-motion on/off/runtime replay could not be completed on the exclusively authorized simulator. This is a historical local implementation checkpoint, not validation of the later Home extension or release/merge approval.

## Delivered scope

| Surface | Implementation and evidence |
| --- | --- |
| Shared foundation | Bundled Barlow/Barlow Condensed with OFL licenses, semantic colors/type/spacing, Material interaction states, approved vector painter, headers and five-tab navigation. Actual-font component goldens and contrast/state tests. |
| Home dashboard | Exact approved transparent H2 hero at full safe-area width and intrinsic ratio, live wordmark/tagline, reference-specific capsule start/resume action, five unfiltered latest results, four existing-points rankings, full-history/leaderboard/profile actions, empty/sparse/long-name/reflow states and concise semantics. |
| Players and setup | Grouped roster, separate profile/presence/menu controls, busy dialogs, adaptive team assignment and rules, persistent kickoff. Existing player/rules/rivalry tests and compact/large-text goldens. |
| Live scoring | Solid team panels, scorer sheet, undo/reset/leave/save/correction behavior preserved. Compact landscape scoring and scroll reachability regression. |
| Motion | Approved foot-origin entrance, coalesced nonblocking goal feedback, immediate victory actions, bounded 36-particle burst, runtime motion policy, cancellation on hidden tab/disposal and safe late-save delivery. Lifecycle tests and inspected simulator frame sequences. |
| History and rankings | Calm history rows, adaptive safe-area filters/details, compact first-visible podium, General/Scorers and real ranking badges, CSV actions. Existing filtering/editing/legacy-scorer tests, podium lifecycle and screen goldens. |
| Profile, data and bootstrap | Adaptive metrics/relationships, existing import/export/retry behavior. Profile/data goldens plus existing backup/database/bootstrap tests. |

At the original R2 source checkpoint, models, Cubits, repositories, database schema and services had no diff from application baseline `ad701db6dc49b2828696c7eee6831135508df0f9`. The current extension adds only navigation/derived-state Cubit ownership around the unchanged models, repositories, database schema, scoring and persistence services. No timer, theme selector or data migration was added.

## Validation

Environment: local macOS, Flutter 3.44.9 / Dart 3.12.2. Original R2 final source checkpoint: `b937a86429233630c5a234f839c4b8c3c94f5af8`. The passing checks in this table ran on its exact source content before the commit; the Home extension and its P13 evidence are recorded in the checkpoint paragraphs above.

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

The P11 spot check installed the current source under the same isolated review bundle, first observed the empty Home, then added five synthetic matches only to its verified six-player database. Device captures cover the populated first fold and the scrolled four-entry ranking. A later fidelity capture verifies the unchanged approved PNG at full safe-area width without upper/lower crop and the corrected Home-only capsule action. Accessibility inspection confirmed one Home CTA node, five 48dp result rows, four ranking actions, live section links and five primary tab labels; the decorative H2 is excluded from traversal. Device-scoped taps opened Classifica, setup, Storico and the selected player profile from Home.

Large-text profile/ranking/history/filter layouts were inspected on the device. P11 also switched the authorized simulator temporarily from its recorded `large` category to `accessibility-extra-extra-extra-large`, observed the scrolling/reflowing Home, and restored `large`. The latest review build is installed with six synthetic players and five synthetic matches, isolated from the production bundle. Local P11 captures remain under ignored `qa/`; the valid prior export remains only in the review app/local evidence.

Retained images: [current Players](verification/players-pro-max.png), [corrected entrance frame review](verification/entrance-review.png), [available Accessibility settings](verification/accessibility-settings.png). Entrance frames are from the P4 corrected-motion build; later checks did not modify entrance geometry. Detailed command logs, native captures, data comparisons and replay videos remain in the ignored local execution packet until landing; reviewed regression goldens are tracked under `test/goldens/`.

## Open validation and limits

- **VoiceOver:** the selected simulator's Accessibility menu exposes no VoiceOver session. AX labels/frames were inspected, but no VoiceOver traversal, activation, announcement or focus pass is claimed. The user explicitly accepted this as deferred and non-blocking for the current feature branch; complete it during later release hardening when an operable environment is available.
- **Native reduced motion:** Settings navigation was unstable and toggle attempts continued to read `0`; no native on/off/runtime replay pass is claimed. Automated production-widget tests prove runtime settlement, static goal hold, immediate actions and splash handoff. The user explicitly accepted the native toggle/replay as deferred and non-blocking for the current feature branch.
- Debug simulator recordings establish visual sequencing, not physical-device frame-budget performance. No 60fps or profile-mode certification is claimed.

No implementation scope was waived. The user accepted the two unavailable native accessibility checks as deferred release-hardening work and confirmed the feature complete. P9-P13 and the full South Africa refactor are complete; the final feature branch is ready for review after push. No MR, merge or release action was performed.

## Ownership and provenance

[Root DESIGN.md](../../DESIGN.md) owns visuals and motion. [PROJECT_DOCUMENTATION.md](../../PROJECT_DOCUMENTATION.md) owns architecture. [Asset inventory](assets/README.md), [R1 manifest](assets/r1/manifest.json) and [H2 manifest](assets/home-h2/manifest.json) own approval, hashes and artwork provenance. All five SVGs, the corrected foot-origin entrance and the exact H2 Home PNG were explicitly approved; no unseen artwork is accepted by this receipt.

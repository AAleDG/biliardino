# In-app feedback verification — 13 October 2026

The feedback implementation has passed final verification on `codex/feedback-form-discovery`, based on `0d6108ff09a779b8b17269370e0e061f0dc38f67`. The R4 contract records explicit acceptance of the 18 reviewed reference corrections and owner-confirmed email delivery evidence. All required checks pass. This receipt records the verified content before its publication commit. Commit/MR identities are tracked by Git and the MR; no merge or release is authorized. Prepare a dependent MR against `codex/runtime-style-selection`, or verify that parent has landed before changing the target.

## Behavior and visual acceptance

Both Altro presentations open the same full-screen feedback route. A required message and optional email submit JSON to Formspree with only app version/build, platform and selected style. A serialized settings queue keeps one local draft across close/reopen, style changes and restart. Sending locks editing, duplicate requests and Back until acknowledgement, error or timeout. Failure preserves the draft for manual retry. Success clears it and shows “Grazie! Feedback inviato.” with “Torna ad Altro”; a local cleanup failure cannot turn acknowledged delivery into a retry.

Both decorative R2 backgrounds and the live Flutter forms were explicitly approved. [The manifest](r2/manifest.json) identifies the artwork; [the live-form record](r2/live-form-acceptance.json) records accepted typography/controls and the subsequent Italia button-centering correction. Italia’s Anton capitals use a text-scaled 3.5dp optical offset within unchanged button bounds. Normal native rendering and normal/200%/keyboard Flutter captures were reviewed. All ten feedback golden images were inspected. Text, logos, fields and controls remain live widgets.

## Final checks

| Check | Result |
|---|---|
| Focused feature and affected regression suite | 54 passed, including six feedback layout/golden tests |
| Full suite | 449 passed, zero failures |
| Flutter analysis | No issues |
| Current-production-source iOS simulator build | Passed; production source unchanged afterward |
| Dart formatting | 23 changed files checked, zero changes |
| Pinned DESIGN.md lint 0.4.0 | Zero errors/warnings |
| Correctness and reuse/quality reviews | Complete; no material findings |
| Protected artwork/fonts/instructions/goldens | 396 checked; approved Altro snapshot and two owning test mappings changed; 18 approved correction images added; original reference images preserved |

The 18 inherited snapshot mismatches are resolved with the exact additive [reference correction set](../../test/goldens/reference-corrections/README.md) approved by the user on 13 October 2026. Nine player/ranking captures reflected earlier issue 18 avatar/layout changes; the filter captures include the corrected “Rivalità” accent. Seven history captures also contain sparse, stable font/paint edge shades; the historical renderer cause was not established. Each candidate was reviewed beside its retained original and reproduced byte-for-byte on the unchanged base with the installed Flutter 3.44.9. All originals and donor provenance remain unchanged; tests select only this bounded correction set and retain exact comparisons and interaction assertions.

Final analysis, formatting and pinned design lint pass. Production source/resources match the simulator-reviewed build by SHA-256, so the completed build/native evidence remains current after these test/reference/document-only changes. No alternate Flutter version was used for final validation.

## Native and delivery evidence

The selected iPhone 17 Pro Max iOS 26.5 used the isolated `com.biliardino.feedback.qa` app. Comparison with the production build found 92 identical resource files; differences are limited to root bundle identity/signature. Both styles’ real entry, form, Back and safe-area layouts were reviewed. Controls remain reachable at the largest native accessibility text size; the South Africa send action also fits fully above the software keyboard. A local draft survived close and a South Africa → Italia style switch, then was cleared through the native UI and reopened empty. Native restart persistence was verified before the delivery test.

Reduce Motion was enabled through actual iOS Settings, both feedback routes were opened and closed, then the original off setting was restored. Text size is restored to `large`, software keyboard hidden and QA style restored to Italia. Actual native accessibility headings, fields, inline validation and action order were inspected. The user explicitly removed VoiceOver validation (“No voice over check man”); it was not run or reported as passed. Existing normal/runtime QA app data was not operated.

Exactly one anonymous message was authorized and sent: “Biliardino feedback verification — 13 October 2026. One test submission.” The native form acknowledged success, its real SQLite draft was empty, return led to Altro and reopen was empty. The owner confirmed **“I received the email.”** No second submission occurred. The separate Formspree dashboard row was not inspected because the browser is signed out. The user explicitly accepted the email receipt plus native acknowledgement and draft-clear/return/empty-reopen observations as delivery evidence under R4.

[The structured receipt](verification.json) retains source/resource identities, checks, the historical base-comparison hashes and final test/reference identities and delivery evidence. Raw logs and native captures remain in the ignored feature packet until verified landing.

## Handoff and platform limits

All required R4 verification gates are satisfied. The MR draft is prepared in the ignored feature packet; the packet and raw evidence remain until verified primary-branch landing. The branch depends on runtime-style-selection, which is not present in the current local master. Prepare a dependent MR against that branch or verify its landing before retargeting.

Android native runtime has not been tested. macOS delivery is unsupported/unverified in this iOS/Android increment. No additional external submission is authorized.

## Target-branch synchronization — 14 October 2026

MR !24 incorporates target commit `f2922dfb0864d3ae57ad24c8342ba42ac5bab825`. The Italia golden-test conflict preserves the target’s newer live-score, team-assignment and award-recognition acceptance references, which take precedence for those screens, and keeps the approved corrections for the remaining screens. Original reference images stay retained. The checks above describe the pre-synchronization verified feedback state; no tests or reviews were rerun, as explicitly instructed by the user.

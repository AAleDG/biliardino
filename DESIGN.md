---
version: alpha
name: Biliardino — South Africa 2010
description: Approved visual baseline for issue 11 plus the approved 2026-09-09 Home dashboard extension and transparent H2 hero.
colors:
  primary: "#0057B8"
  on-primary: "#FFFFFF"
  primary-pressed: "#00428D"
  home-action: "#005ECB"
  home-action-pressed: "#004A9F"
  background: "#F8F5EB"
  surface: "#FFFFFF"
  ink: "#111111"
  text-secondary: "#5C5C55"
  outline: "#85857C"
  divider: "#DDD9CE"
  success: "#087F3E"
  success-pressed: "#066631"
  success-container: "#E7F2E9"
  warning-container: "#FFF0B8"
  yellow: "#FFC700"
  error: "#C62828"
  error-container: "#FBE9E7"
  team-one: "#0057B8"
  team-one-container: "#E8F0FA"
  team-two: "#FF7900"
  team-two-container: "#FFF0E1"
  disabled-container: "#E5E2D9"
  disabled-content: "#5C5C55"
typography:
  display-score:
    fontFamily: Barlow Condensed
    fontSize: 112px
    fontWeight: 900
    lineHeight: 1
    letterSpacing: -1px
  display-event:
    fontFamily: Barlow Condensed
    fontSize: 56px
    fontWeight: 900
    lineHeight: 1
    letterSpacing: 0px
  headline-screen:
    fontFamily: Barlow Condensed
    fontSize: 32px
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: 0px
  headline-section:
    fontFamily: Barlow Condensed
    fontSize: 22px
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: 0px
  title-player:
    fontFamily: Barlow
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: 0px
  body:
    fontFamily: Barlow
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0px
  body-strong:
    fontFamily: Barlow
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0px
  label-action:
    fontFamily: Barlow Condensed
    fontSize: 20px
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: 0.2px
  label-home-action:
    fontFamily: Barlow Condensed
    fontSize: 26px
    fontWeight: 900
    lineHeight: 1
    letterSpacing: 0.2px
  label-utility:
    fontFamily: Barlow
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: 0px
  caption:
    fontFamily: Barlow
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0px
  navigation:
    fontFamily: Barlow
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: 0px
rounded:
  none: 0px
  small: 8px
  control: 12px
  panel: 16px
  sheet: 24px
  full: 9999px
spacing:
  hairline: 1px
  micro: 4px
  small: 8px
  medium: 12px
  page: 16px
  section: 24px
  large: 32px
  touch-minimum: 48px
  action-height: 56px
components:
  app-shell:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink}"
    padding: "{spacing.page}"
  screen-heading:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink}"
    typography: "{typography.headline-screen}"
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-action}"
    rounded: "{rounded.control}"
    height: "{spacing.action-height}"
    padding: "{spacing.page}"
  button-primary-pressed:
    backgroundColor: "{colors.primary-pressed}"
    textColor: "{colors.on-primary}"
  button-home-action:
    backgroundColor: "{colors.home-action}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-home-action}"
    rounded: "{rounded.full}"
    height: 72px
  button-home-action-pressed:
    backgroundColor: "{colors.home-action-pressed}"
    textColor: "{colors.on-primary}"
  button-start:
    backgroundColor: "{colors.success}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-action}"
    height: "{spacing.action-height}"
    rounded: "{rounded.control}"
  button-start-pressed:
    backgroundColor: "{colors.success-pressed}"
    textColor: "{colors.on-primary}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.label-utility}"
    height: "{spacing.touch-minimum}"
    rounded: "{rounded.control}"
  button-destructive:
    backgroundColor: "{colors.error}"
    textColor: "{colors.on-primary}"
    height: "{spacing.touch-minimum}"
    rounded: "{rounded.control}"
  control-disabled:
    backgroundColor: "{colors.disabled-container}"
    textColor: "{colors.disabled-content}"
    height: "{spacing.touch-minimum}"
  navigation:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-secondary}"
    typography: "{typography.navigation}"
  navigation-selected:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    typography: "{typography.navigation}"
  player-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.title-player}"
    padding: "{spacing.medium}"
  avatar-neutral:
    backgroundColor: "{colors.background}"
    textColor: "{colors.ink}"
    size: 40px
    rounded: "{rounded.full}"
  switch-on:
    backgroundColor: "{colors.primary}"
    rounded: "{rounded.full}"
  switch-off:
    backgroundColor: "{colors.outline}"
    rounded: "{rounded.full}"
  switch-thumb:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.full}"
  presence-on:
    backgroundColor: "{colors.success-container}"
    textColor: "{colors.success-pressed}"
    typography: "{typography.label-utility}"
  presence-off:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.text-secondary}"
    typography: "{typography.label-utility}"
  field:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    height: "{spacing.action-height}"
    rounded: "{rounded.control}"
  field-outline:
    backgroundColor: "{colors.outline}"
    width: "{spacing.hairline}"
  list-divider:
    backgroundColor: "{colors.divider}"
    height: "{spacing.hairline}"
  team-one-panel:
    backgroundColor: "{colors.team-one}"
    textColor: "{colors.on-primary}"
    typography: "{typography.display-score}"
    rounded: "{rounded.panel}"
  team-two-panel:
    backgroundColor: "{colors.team-two}"
    textColor: "{colors.ink}"
    typography: "{typography.display-score}"
    rounded: "{rounded.panel}"
  team-one-slot:
    backgroundColor: "{colors.team-one-container}"
    textColor: "{colors.team-one}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.small}"
  team-two-slot:
    backgroundColor: "{colors.team-two-container}"
    textColor: "{colors.ink}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.small}"
  ranking-first:
    backgroundColor: "{colors.yellow}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
  ranking-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.body-strong}"
  warning:
    backgroundColor: "{colors.warning-container}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
  error:
    backgroundColor: "{colors.error-container}"
    textColor: "{colors.error}"
    typography: "{typography.body}"
  dialog:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sheet}"
    padding: "{spacing.section}"
  snackbar:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.surface}"
    typography: "{typography.body}"
  ribbon-yellow:
    backgroundColor: "{colors.yellow}"
  ribbon-green:
    backgroundColor: "{colors.success}"
  ribbon-blue:
    backgroundColor: "{colors.primary}"
  ribbon-red:
    backgroundColor: "{colors.error}"
---

# Biliardino — South Africa 2010

## Overview

**Status: approved design baseline, 2026-09-07; Home extension and H2 artwork approved, 2026-09-09.** This specification accompanies four raster mockups for GitLab issue 11 and the later leftmost-phone Home dashboard request. It is the canonical baseline for the Flutter implementation on this feature branch. Final verification status is recorded in the implementation receipt. Generated pixels do not override the exact tokens or product rules written here; the one approved generated asset is identified by its exact manifest hash below.

The app tracks office table-football players, presence, matches and statistics. Its identity should feel like an energetic South Africa 2010 football poster translated into a useful mobile tool: warm white, confident black condensed titles, sweeping ribbons, deliberate blocks of color and black foosball silhouettes. The header carries the character; the working content stays calm and legible.

The issue mood board remains the source for the original four-screen direction. The user's new 2026-09-09 request deliberately supersedes the earlier dashboard/navigation exclusion only for the leftmost-phone Home screen. Primary navigation becomes Home, Giocatori, Partita, Classifica and Altro; Altro keeps Storico and Dati reachable as full routes. Preserve player management, 1v1/2v2, rules, rivalry, scoring, confirmations, historical corrections, statistics and backups. The timer, English team names, style switcher and Italia '90 vocabulary remain out of scope.

Source format: [Google DESIGN.md specification](https://github.com/google-labs-code/design.md/blob/9bf8eae67128b6cc55ad9bf86665767deb4c11cd/docs/spec.md), read 2026-09-07. The file uses its canonical section order and adds project-specific sections afterward. See [RESEARCH.md](design/experiments/south-africa-2010/RESEARCH.md) for tooling and limitations.

## Colors

Use the frontmatter as the approved palette baseline. Values were deliberately chosen for this application; they are not asserted to be pixel samples or official tournament brand values.

Warm background and white panels dominate everyday screens. Blue marks general actions, selection and the active tab. Green marks presence text/status, success and kickoff; switches use blue for their selected track across the app. Yellow adds energy and highlights first place. Red serves errors/destructive actions, and can appear as a narrow decorative ribbon. Orange is reserved for the second team in match contexts.

Team identity has its own tokens even where values match a brand token. Keep Squadra 1 on the left and Squadra 2 on the right; also label them and show selected/check states. Presence uses text plus the switch position, never just a dot. Use neutral initials outside a match so avatar hues do not compete with teams or status.

Calculated solid-color pairs: ink/background 17.31:1; secondary text/background 6.18:1; white/blue 6.87:1; white/green 5.10:1; white/red 5.62:1; ink/yellow 12.07:1; ink/orange 7.18:1. White/orange is only 2.63:1, so orange panels use ink text. Status text on pale green uses the darker success-pressed value: the original success value produced only 4.44:1 on that pale surface. Pale dividers are decorative; essential input outlines use the stronger outline token. The field-outline component describes the filled outline itself, with 3.72:1 contrast against white; it is not a text style. Validate rendered disabled, selected, focus and overlay states separately.

## Typography

Use **Barlow Condensed 800/900** for screen headings, short action labels and score/celebration moments. Use **Barlow 400/600** for names, explanatory text, metadata and navigation. Real font specimens and licenses are stored in [type/](design/experiments/south-africa-2010/type/README.md) for the offline review gallery. The shared Flutter foundation now bundles those exact files and licenses under `assets/fonts/` and registers both families locally. Generated lettering is a visual approximation, not a font asset.

The type scale is defined above. Scores may scale from 80 to 112 logical pixels to accommodate two digits and constrained layouts. Preserve large-text settings for utility content; allow names to wrap and row height to grow instead of shrinking all text. Use aligned numeral widths for statistics where supported by the selected font, verified in Flutter.

Keep the application's existing label casing. Major display headings may remain uppercase; names and explanations stay readable in their existing casing. Avoid excessive tracking, faux-condensing, outlined titles and glow.

## Layout

The reference viewport is 402 × 874 logical pixels, including system safe areas. Token dimensions written as px map to Flutter logical pixels, not physical screenshot pixels. Respect the actual device's insets; never hard-code a Dynamic Island into the application.

Use 16-pixel page gutters, a 4-pixel base rhythm, 24-pixel section gaps and at least 48 × 48 logical pixels for interactive targets. The approved Home hero is the deliberate exception to the page gutter: it spans the safe-area width at its intrinsic 1516:1038 ratio with contain/fit-width behavior, so no upper or lower artwork is cropped. Its wordmark, action and data sections retain the standard gutters. Primary bottom actions start at 56 pixels high and grow with text. Labels and overflow menus remain separate tappable areas.

Home is the initial post-splash destination. Preserve the leftmost-phone hierarchy: live wordmark and tagline, substantial approved H2 hero, prominent blue start/resume action, recent results and ranking summaries. The page scrolls when five match rows plus four ranking rows do not safely fit; do not shrink the hero or interactive targets merely to force all data above the fold. Players remains a separate primary destination. Its masthead stays compact, and larger rosters and accessibility sizes scroll. The user-approved 11 September refinement places the existing shallow ribbon above a centered GIOCATORI title and centered wrapping summary pills. Active rows form one calm grouped panel; archived players remain fully visible in a separate ARCHIVIATI group below, omitted when empty. Keep the original compact NUOVO action on the right so the approved bottom-left corner ribbons remain visible. Header and roster scroll together at constrained sizes; preserve full names, separate actions and bottom padding so the final row clears the floating action. No new illustration or ribbon master is introduced.

Match setup is one scrolling screen ordered as heading, mode, compact match-options summary, available-player summary and team composition. The summary shows at most four stable-order rows; larger rosters remain reachable through the full roster sheet. Rules, automatic assignment and rivalry remain available in the options sheet. The pinned kickoff capsule sits 12 logical pixels above the opaque bottom navigation. Preserve the default 2v2 mode and Italian team labels; actual mode determines slot count. This replaces the original setup ordering under the approved Nuova Partita reference revision. Never squeeze the entire setup into an unreadably dense phone.

The user selected concept D for match options on 2026-09-10: a compact summary with a blue edit affordance opens a scrollable bottom sheet instead of expanding the setup page. Keep the active rules visible in the summary and keep its bounds stable as rule mode changes. Use a full-width, equal-segment blue rule selector, labeled goal stepper and blue switches. Preserve immediate rule persistence and clearly state that changes apply immediately; a single top close control and swipe dismissal close the sheet without reverting changes. Automatic team assignment closes the sheet to reveal the result. Rivalry retains its complete-team eligibility and confirmation. Keep all controls as live Flutter widgets; the generated concept is a direction reference, not a production image.

The user approved the matching **horizon-arc** panel decoration on 2026-09-10. It is the canonical accent for future branded custom panels and bottom sheets: one shallow ribbon band clipped by the top rounded edge, with yellow entering from the left, blue spanning the middle and orange closing the right. Do not add red or green to this panel treatment. Reuse the shared `SheetRibbonAccent` painter behind the drag handle, keep the body surface calm and preserve all controls as Flutter widgets. This is a deliberate family resemblance, not permission to decorate native/system sheets or destructive confirmation dialogs automatically.

The Partita in corso reference revision uses one illustrated scoreboard with blue and orange score fields, a dark curved central division and separate team cards below. The user approved the dimensional figures, straight rods and football master plus normalized score/edge geometry on 2026-09-11; exact hashes, source, extraction and preview evidence live in `design/south-africa-2010/assets/live-r1/manifest.json`. The source was generated against near-magenta and converted programmatically to genuine alpha. Initial approval covered those pixels and preview geometry; the subsequent final interactive composition approval is recorded below.

Keep Squadra 1/2 labels, scores, player names and all controls as live Flutter widgets. The user requested a coordinated reference-fidelity refinement on 2026-09-11: convex rounded scoreboard shoulders, cream-separated tapered ribbons beneath both scores, layered lower green/yellow/black and yellow/red/orange/blue ribbons, and directional gradients. The live scoreboard and team-card headings use white on deeper blue/orange-red surfaces; ordinary orange controls retain ink. The follow-up contour correction raises both score-field intersections with the screen sides without moving the central crest or lower edge, and extends the upper shoulders beyond the viewport rather than ending in contained rounded corners. The upper-left blue accent is broader and longer than the right green accent, with a curved tapered edge. The user explicitly approved the final integrated composition after the lower-crest and stronger orange-header refinements. The approved simulator capture is `orange-header-review.png`; its image and source identities are recorded in the live-r1 manifest. Preserve the existing score pulse, goal notification and victory/confetti timings, and keep illustration static. Each team card offers +1 and a separate undo action with at least 48-pixel targets. Reset remains confirmed and is reached through the header ellipsis. Show the real rules pill and optional rivalry summary; no timer is added. The blue, four-pixel-white-bordered REGISTRA RISULTATO capsule sits 12 pixels above the existing bottom navigation and preserves free/target rule eligibility and busy states.

On compact screens and large text, reduce decoration, let team labels/names grow, stack cards and scroll the header, scores, rules and result action together. On normal phones, keep the result action outside the scrolling content. Multi-digit scores fit within the curved colored area without truncation. The scorer picker reuses the approved SheetRibbonAccent, team avatars and an explicit close action; confirmations and celebration surfaces retain their existing style.

Leaderboard and profile use compact headers and readable rows. Preserve the podium as a smaller graphic group so the full ranking is not pushed unnecessarily far down. Dialogs and sheets must remain scrollable with the keyboard and large text.

## Elevation & Depth

Use solid fills, spacing and subtle dividers for hierarchy. Ordinary list panels have no drop shadow. Interactive secondary controls use a visible outline. Bottom sheets may use a standard restrained shadow and dim scrim to separate modal content. No neon, scanlines, glow or glass panels. The live-match reference refinement is a scoped exception to solid decorative fills: use directional gradients inside its score fields, ribbon paths and team-card headings. Ordinary controls and other screens retain their existing treatment.

The approved dimensional Home illustration keeps its shading inside the PNG. It does not introduce a separate gradient system into buttons or cards.

## Shapes

Use 8-pixel radii for small slots, 12 for buttons and inputs, 16 for grouped panels and 24 for sheet top corners. The prominent Home action follows the reference with a full capsule, four-pixel white perimeter and restrained shadow; this does not change ordinary application buttons. Avatars, rank medallions and presence switches are circular or pill shaped because of their roles.

The distinctive graphic is an asymmetric ribbon sweep: broad yellow, green and blue arcs with a narrow red accent and warm-white separation. Use a small shared set of normalized paths for header, corner and celebration compositions. Avoid a generic repeated rainbow stripe on every row. Black foosball figures should be simple recognizable silhouettes on a rod, not the Italia '90 Ciao mascot.

## Components

The frontmatter provides core colors, typography and dimensions. Component variants below define behavior-sensitive states without changing business logic.

| Component family | Required treatment and states |
| --- | --- |
| App shell/header/navigation | Home, Giocatori, Partita, Classifica and Altro; selected indicator, opaque navigation surface, safe areas, keyboard/focus support; Storico/Dati routes and retained leave-match confirmation |
| Home dashboard | Live wordmark/tagline, approved decorative H2 hero, start/resume state, up to five unfiltered recent matches and four played ranking entries, empty/sparse/long-name/reflow states and repository-driven updates |
| Primary/start/secondary/destructive buttons | Normal, pressed, focused, disabled and busy; progress replaces an icon without changing the action's meaning; no duplicate submission |
| Player row/avatar/presence | Active, present, absent, archived and mutating; name/profile target, presence semantics, overflow actions; archived status replaces switch |
| Input/dialog/sheet | Label, helper/error, focus, keyboard, cancellation, confirmation and operation failure; use the same surfaces for add/rename/archive, scorer selection, filters and corrections. Branded custom panels reuse the approved yellow/blue/orange `SheetRibbonAccent`; native/system sheets and destructive confirmations remain restrained. |
| Mode/rules controls | 1v1 and 2v2; free and first-to-N; conditional goal target and win-by-two controls; saving-rules disables dependent actions |
| Team slot/assignment | Empty, selected, available, full and disabled; S1/S2 labels plus selection checks; capacity of one or two follows mode |
| Rivalry | Available only with complete teams; preserve activation confirmation, active/deactivate state, first-duel empty message and existing overview statistics |
| Score panel | Both teams, 0, one/two-digit values, goal increment, undo disabled at zero, awaiting confirmation and saving; label controls with team and score |
| Goal/victory overlay | Scorer announcement; result, names and scores; rematch/change-team actions; reduced-motion form; see Motion |
| Match row/details/editor | Date grouping, mode, both teams, winner cue, scores, actions; filtered/unfiltered emptiness; correction validation and missing legacy scorer handling |
| Ranking/podium/stat/badge | General and Scorers, one/two/three podium entrants, ties in source-defined order, full ranking, existing badges, profile navigation and export availability |
| Profile | Presence, points, six statistics, recent form, relationships including ties, head-to-head and personal history; empty/not-found forms |
| Data actions/bootstrap/feedback | Loading/busy, empty where applicable, ready, failure/retry, export feedback and restore confirmation; retain native file picker/share sheet |

A short screen title, player name and numeric metric are always real text widgets. Decorative layers exclude themselves from semantics and do not intercept input. Avatar initials remain generated from the name; photographs are not introduced.

### Shared switch decision — 11 September 2026

The user selected the existing match-options switch appearance for every switch in the app: blue selected track, white thumb, neutral outlined-token off track, and the shared disabled colors with platform disabled treatment. Players presence, match rules/rivalry and history editing all use adaptive switches driven by AppTheme; on iOS this preserves the reference's compact pill geometry. A theme adaptation preserves the common palette when Flutter adapts shape. No screen supplies its own switch color. Presence labels remain green with explicit In ufficio/Assente text, independent of switch styling. Keep enabled/toggled semantics, platform interaction, focus and at least 48dp targets. This is a control-style decision, not new artwork.

## Do's and Don'ts

- Do use consistent shared components and semantic tokens across every state.
- Do keep all existing content reachable through the five approved primary destinations, preserving persistence, calculations and confirmation rules.
- Do preserve Italian labels; proposed copy changes require explicit review.
- Do use the mockups to review composition and character, and this file for exact implementation values.
- Do accommodate text scaling, VoiceOver, reduced motion and small/landscape layouts.
- Do keep first-to-N result registration gated by the existing victory condition and confirmation.
- Do not add the mood board's timer, English team names or any navigation beyond the approved Home/Giocatori/Partita/Classifica/Altro arrangement.
- Do not turn screenshots into runtime backgrounds or rasterize controls/text.
- Do not create a new illustration or unique component for every screen.
- Do not combine this direction with Italia '90 or introduce a runtime theme selector.
- Do not treat unvalidated generated pixels as an approved final UI or an accessibility test.

## Motion

This section is a project extension. Durations and lifecycle rules are explicit prose because the current core format has no typed motion group. The runtime counterparts live in AppMotion/MotionAwareState. Goal/victory/splash, score controls and the first-visible podium consume that policy; the development-only tool/motion_preview.dart replays the actual entrance and overlays without opening storage. No animation package is required.

| Role | Duration | Presentation and reduced-motion equivalent |
| --- | --- | --- |
| Presence/selection | 180 ms | Short fill/check/crossfade; immediate final state with reduced motion |
| Navigation indicator | 220 ms | Ease-out movement; immediate selected position with reduced motion |
| Score change | 220 ms | Small scale/fade without elastic overshoot; immediate score update with reduced motion |
| Dialog/sheet/content | 220–280 ms | Standard route transition; no decorative stagger; immediate or platform reduced-motion behavior |
| Podium entry | 400 ms | One short rise/reveal, rows readable immediately; final podium immediately with reduced motion |
| Goal | 1100 ms total | 180 ms ribbon entry, 700 ms readable hold, 220 ms exit; static 1100 ms announcement with reduced motion |
| Victory entry | 500 ms | Compact ribbon/result reveal; actions operable immediately; full static result with reduced motion |
| Victory particles | 2000 ms | Bounded ribbon confetti burst; no particles with reduced motion |
| Splash | 1000 ms plus up to 220 ms handoff | Brief football/ribbon/title reveal; immediate handoff with reduced motion after bootstrap is ready |

The user approved the corrected [foot-origin entrance replay](design/south-africa-2010/assets/r1/review.html?preview=foot-origin): the figure stays fixed on its rod, a smaller ball starts beside its foot, holds briefly and rolls outward. The reference uses a 32px ball, 150ms initial hold, 24px travel and approximately 90° rotation within 1000ms. Preserve that spatial relationship when adapting to Flutter; use the settled composition immediately with reduced motion. The approval record and exact review-page hash live in the asset manifest. Runtime lifecycle and rendering validation remain required.

Feedback should answer an event, not loop around idle content. Keep haptics at the existing meaningful goal, kickoff, undo and victory events; do not add repeated haptics to decorative frames. Loading feedback must remain understandable with reduced motion.

Score data updates immediately, independent of artwork. Rapid goals must not create stacked full-screen announcements: replace/coalesce the visible visual effect while retaining correct scorer/score semantics. Goal feedback remains nonblocking. Victory isolates background interaction and semantics, but its own actions never wait for confetti. Cancel controllers/overlays on dismissal, rematch, change-team and tab changes. Entry reveals must not finish invisibly on offscreen IndexedStack pages.

## Assets and Flutter mapping

| Design element | Implementation |
| --- | --- |
| Palette/type/spacing/radii | ThemeData, TextTheme and named theme extensions/constants derived from this document |
| Controls and data surfaces | Reusable Flutter widgets, retaining existing Cubit events and repository contracts |
| Ribbons/arcs/pitch lines | Shared CustomPainter/clip geometry; normalized paths scale with layout |
| Foosball figure/football/stadium | A small local versioned SVG set, with separate layers when motion needs them |
| Home shaded hero | Approved transparent PNG `home-hero-transparent.png`; decorative and excluded from semantics |
| Nuova Partita team-stage ribbons | Approved transparent PNG `team-stage-v10-gimp-white-to-alpha.png`; decorative, geometry-frozen and excluded from semantics |
| Nuova Partita lower flourish | Approved transparent PNG `lower-flourish-v5-transparent.png`; decorative ribbon/football layer, geometry-frozen and excluded from semantics |
| Confetti | Bounded programmatic ribbon particles, deterministic seed for golden tests |
| Fonts | Local Barlow and Barlow Condensed files plus licenses |

The approved SVG masters use restricted paths/circles/translations. `tool/generate_south_africa_artwork.py` verifies their approved hashes and compiles the geometry into `lib/widgets/design/artwork_paths.dart`; the shared painter renders it without an SVG runtime dependency. Regenerate from reviewed masters rather than hand-editing generated paths. No runtime reference may point to the issue upload or a generated-image cache path.

The approved vector masters are available in the [R1 asset review](design/south-africa-2010/assets/r1/review.html), with an [inventory and usage guide](design/south-africa-2010/assets/README.md) and [hashed manifest](design/south-africa-2010/assets/r1/manifest.json). These include a rigid foosball figure, its rod assembly, a football and two ribbon geometry references. **All five R1 SVG assets were explicitly approved by the user on 2026-09-07 at the manifest hashes.** The Home dashboard uses the separately approved [H2 transparent PNG](design/south-africa-2010/assets/home-h2/png/home-hero-transparent.png), approved on 2026-09-09 at SHA-256 `44530a3c4f352a2cb2a413c529c3b002b125a345045fd2e874bf386158dd73de`; its [manifest](design/south-africa-2010/assets/home-h2/manifest.json) owns generation, alpha and approval provenance. Any material artwork change still requires explicit review. Ribbon SVGs remain reference geometry for the shared painter; review screenshots are not runtime assets.

The Nuova Partita revision has two separately approved transparent layers. [team-stage-v10-gimp-white-to-alpha.png](design/south-africa-2010/assets/setup-r2/approved/team-stage-v10-gimp-white-to-alpha.png) was approved from the GIMP live preview on 2026-09-10 at SHA-256 `45b320cee3d42d4140f3bd8787159e28bba10f56aa4ac2b1aefb2af5be91ee4d`; it is the unchanged v3 composition with white converted to alpha in GIMP 3.0.6. [lower-flourish-v5-transparent.png](design/south-africa-2010/assets/setup-r2/approved/lower-flourish-v5-transparent.png) was separately approved on 2026-09-10 at SHA-256 `bb0c574dc80cdebeb47252cf100a05d6732001ac13fe75791706c530ccd3cc8a`; it preserves the ImageGen v4 RGB composition and replaces only the magenta key with deterministic binary alpha. The [setup-r2 manifest](design/south-africa-2010/assets/setup-r2/manifest.json) owns exact provenance and review hashes. The byte-identical approved files live separately from rejected and intermediate candidates. These approvals cover the individual layers only. The static HTML composition was rejected on 2026-09-10 because its artwork/card and CTA/tab-bar placement did not represent the intended screen. Direct Flutter integration is now the composition approval surface; the corrected running composition was explicitly approved by the user on 2026-09-10 after independent fidelity review and simulator verification. The manifest’s approvedSimulatorReview records the actual simulator evidence; the earlier rejected HTML and widget candidates remain historical.

### Nuova Partita composition correction — 10 September 2026

The user approved a focused Flutter correction after the independent middle-phone fidelity review. Keep both setup-r2 PNG byte streams unchanged. Let the live team cards determine the central artwork bounds; uniformly scale and clip the decorative layer within that stage so its lower fan does not extend into the footer. The footer aligns the lower PNG’s visible alpha edge (row 993 of its 1086-row canvas) to the navigation boundary. Retaining a 12-pixel CTA clearance intentionally leaves a partially obscured football rather than the reference’s large navigation-free illustration band. At large text sizes, omit the decorative footer along with the central ribbons so expanded utility content stays on a calm background.

The original accepted correction used a compact options disclosure, an external roster heading, warmer roster surfaces, a continuous inset team panel and occupied slots at least 48 pixels tall. Setup-local display variants strengthen mode labels, VS and kickoff without changing other screens’ type scale. Preserve dark foregrounds on orange where required by the approved contrast policy. The user explicitly accepted the corrected running composition on 2026-09-10, describing it as perfect. This approves the reviewed Flutter placement and styling in addition to the previously approved immutable PNGs.

## Review coverage and implementation sequence

The original screen migration is implemented: shared tokens, Material theme, font registration, asset painter, navigation/header treatment and motion policy are present. Players and setup use grouped roster rows, adaptive team and mode controls, explicit busy states and a green pinned kickoff action. Live scoring uses solid team panels and responsive controls. Goal, victory and splash share the live accessibility policy; history uses calm grouped rows and shared filter controls; rankings use a compact first-visible podium with real badges; profiles reflow metrics and relationships; data actions retain the native picker/share flow. The later extension now has its typed Home/Giocatori/Partita/Classifica/Altro shell, full Storico/Dati routes with retained History filters, repository-derived dashboard state and reference-aligned Home composition. The exact approved H2 is bundled unchanged; wordmark, tagline, start/resume action, results, ranking and links remain live Flutter widgets. Historical iOS simulator results cover only the original migration; the P11 receipt adds targeted Home evidence. Actual VoiceOver traversal and native reduced-motion toggling remain unverified manual gaps that the user explicitly deferred to later release hardening; they do not block completion of this feature branch. See the [implementation receipt](design/south-africa-2010/IMPLEMENTATION.md).

The four mockup deliverables cover populated players, complete setup (two scroll positions), live match and leaderboard. Their examples are recorded in [MOCKUP_BRIEF.md](design/experiments/south-africa-2010/MOCKUP_BRIEF.md). Remaining states are covered by the component matrix, not silently omitted from implementation.

The visual direction, four original mockups and exact H2 Home hero are approved. The user authorized phased execution using feature-plan-scaffold, with new assets presented for explicit approval. For the Home extension, P9 artwork review, P10 navigation/data foundation and P11 Home UI integration are complete; hardening and final verification remain. Work belongs on the issue's South Africa 2010 implementation branch. Artwork approval does not claim final implementation acceptance or authorize merging/deployment.

The final implementation must run flutter analyze and flutter test, retain existing functional tests, add representative component/state goldens, and review the complete navigation flow on iPhone. Raster mockups and DESIGN.md lint cannot establish runtime performance, font metrics, hit areas, contrast over illustrations, correct VoiceOver behavior or persistence correctness.


### Live-score layout at constrained sizes

At ordinary phone sizes the score-panel actions stay pinned below each team while long player content can scroll within the panel. When the available body is shorter than 360 logical pixels, the scoreboard scrolls as a whole so the rule summary, both score controls and registration action remain reachable. Display scores/team labels fit their bounded region; names and utility content retain the accessibility text scale. Goal feedback coalesces into one nonblocking announcement and yields to the winning-result confirmation.

At compact landscape heights, goal feedback uses a horizontal banner with a fixed display heading and scaled scorer text. Scorer selection scrolls with full safe areas. Filter and detail sheets reserve bottom safe-area space so actions clear the home indicator.

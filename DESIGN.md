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

Keep Squadra 1/2 labels, scores, player names and all controls as live Flutter widgets. The user requested a coordinated reference-fidelity refinement on 2026-09-11: convex rounded scoreboard shoulders, cream-separated tapered ribbons beneath both scores, layered lower green/yellow/black and yellow/red/orange/blue ribbons, and directional gradients. The live scoreboard and team-card headings use white on deeper blue/orange-red surfaces; ordinary orange controls retain ink. The follow-up contour correction raises both score-field intersections with the screen sides without moving the central crest or lower edge, and extends the upper shoulders beyond the viewport rather than ending in contained rounded corners. The upper-left blue accent is broader and longer than the right green accent, with a curved tapered edge. The user explicitly approved the final integrated composition after the lower-crest and stronger orange-header refinements. The approved simulator capture is `orange-header-review.png`; its image and source identities are recorded in the live-r1 manifest. Preserve the existing score pulse and goal notification timings, and keep illustration static. The victory reveal follows the approved October 2026 revision described under Motion. Each team card offers +1 and a separate undo action with at least 48-pixel targets. Reset remains confirmed and is reached through the header ellipsis. Show the real rules pill and optional rivalry summary; no timer is added. The blue, four-pixel-white-bordered REGISTRA RISULTATO capsule sits 12 pixels above the existing bottom navigation and preserves free/target rule eligibility and busy states.

On compact screens and large text, reduce decoration, let team labels/names grow, stack cards and scroll the header, scores, rules and result action together. On normal phones, keep the result action outside the scrolling content. Multi-digit scores fit within the curved colored area without truncation. The scorer picker reuses the approved SheetRibbonAccent, team avatars and an explicit close action; confirmations and celebration surfaces retain their existing style.

Leaderboard and profile use compact navigation headers and readable rows. The approved Profilo Figurina direction below adds an illustrated identity hero beneath the profile navigation header. Preserve the podium as a smaller graphic group so the full ranking is not pushed unnecessarily far down. Dialogs and sheets must remain scrollable with the keyboard and large text.

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

### Tap feedback — 15 October 2026

The user requested removal of the expanding Material tap ripple throughout both runtime styles. South Africa 2010 and Italia ’90 use `NoSplash.splashFactory` in their shared theme definitions so buttons, navigation and tappable rows inherit this behavior. Retain pressed colors, selection states, keyboard focus indicators, semantics and existing haptics.

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
| Tab and mode selection | 180 ms | Ease-in-out moving indicator/fill, immediate label colors; immediate final selection with reduced motion |
| Score change | 220 ms | Small scale/fade without elastic overshoot; immediate score update with reduced motion |
| Dialog/sheet/content | 220–280 ms | Standard route transition; no decorative stagger; immediate or platform reduced-motion behavior |
| Podium entry | 400 ms | One short rise/reveal, rows readable immediately; final podium immediately with reduced motion |
| Goal | 1100 ms total | 180 ms ribbon entry, 700 ms readable hold, 220 ms exit; static 1100 ms announcement with reduced motion |
| Victory entry | 850 ms | Opposing South Africa ribbon sweeps frame the title and settle at the edges; actions operable immediately; full static result with reduced motion |
| Splash | 1000 ms plus up to 220 ms handoff | Brief football/ribbon/title reveal; immediate handoff with reduced motion after bootstrap is ready |

The user approved the corrected [foot-origin entrance replay](design/south-africa-2010/assets/r1/review.html?preview=foot-origin): the figure stays fixed on its rod, a smaller ball starts beside its foot, holds briefly and rolls outward. The reference uses a 32px ball, 150ms initial hold, 24px travel and approximately 90° rotation within 1000ms. Preserve that spatial relationship when adapting to Flutter; use the settled composition immediately with reduced motion. The approval record and exact review-page hash live in the asset manifest. Runtime lifecycle and rendering validation remain required.

On 2026-10-01 the user selected proposal 3, the South Africa ribbon reveal, to replace the victory card/confetti composition. The approved implementation uses yellow, green, blue and red painter ribbons, a large VITTORIA heading, the winning team's color pill, live names and the final score on ivory. Ribbons sweep in once from opposite edges and settle as a decorative border; there are no particles or repeated motion. RIVINCITA and CAMBIA SQUADRE retain their existing callbacks and are enabled immediately. At short heights or enlarged text, ribbons shrink to the safe outer edges and the result/actions scroll within a clear central viewport. Goal feedback, registration/confirmation, match rules and navigation are unchanged. `tool/victory_preview.dart` replays the production overlay with sample data and no storage. **The user explicitly approved the new painter and integrated animation on 2026-10-01, replying “perfect” to the Simulator preview.** The [approval manifest](design/south-africa-2010/assets/victory-r1/manifest.json) records the exact source and [approved video](design/south-africa-2010/assets/victory-r1/approved-preview.mp4) hashes. Victory golden images cover the settled result and compact enlarged-text layouts.

The 15 October 2026 tab follow-up adopts the interaction from the reviewed Transport direction selector in thread `b907bdaf-9636-48b4-8db9-d0ef0c7682cc` for both South Africa 2010 and Italia ’90. A single selected fill slides beneath persistent labels in segmented controls; the primary navigation keeps its existing short top rule with the same timing. Segmented controls have one outer border and no separators between choices, per the user's simulator review. All tab/segment tracks and selected fills use the same 30dp radius on every corner in both styles, including the vertical enlarged-text layout; remove the earlier asymmetric inner-corner treatment. Labels and selection semantics change immediately, without a grey intermediate fill. Main destination and ranking tab/mode changes reveal only the current content with a 180 ms ease-out fade, retaining the mounted screen tree and local state. Ranking keeps its native manual swipe gesture; taps change the pane immediately and fade it in. Repeated selections do not replay motion, rapid changes replace the active reveal, and reduced motion settles the indicator and content immediately, including runtime setting changes. Match leave/save guards, filters, routes and persistence remain owned by the existing application logic. Horizontally overflowing choice labels scroll to the selected item without recreating the moving indicator. Mode/rule selectors retain native button focus and mutually exclusive selection semantics, with visual/touch targets of at least 48dp. This follow-up changes control motion only and introduces no artwork. Native playback and runtime testing are assigned to the user for this increment.

Feedback should answer an event, not loop around idle content. Keep haptics at the existing meaningful goal, kickoff, undo and victory events; do not add repeated haptics to decorative frames. Loading feedback must remain understandable with reduced motion.

Score data updates immediately, independent of artwork. Rapid goals must not create stacked full-screen announcements: replace/coalesce the visible visual effect while retaining correct scorer/score semantics. Goal feedback remains nonblocking. Victory isolates background interaction and semantics, but its own actions never wait for the reveal. Cancel controllers/overlays on dismissal, rematch, change-team and tab changes. Entry reveals must not finish invisibly on offscreen IndexedStack pages.

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

## Classifica podium and Nastri components

The user approved the Classifica podium perspective and gradient revision, followed by the Nastri component direction. Preserve the blue second-place pedestal on the left, raised yellow winner in the center and green third-place pedestal on the right. Side pedestals expose inward-receding inner faces. The yellow/green loop and foreground ribbons use directional gradients; the figures and football reuse the unchanged approved live-r1 raster. Exact artwork identity and approval evidence are recorded in `design/south-africa-2010/assets/classifica-r1/manifest.json`. Integrated-screen acceptance is separate from this artwork approval.

Use one blue/yellow/green ring treatment for every Classifica avatar, with the initial as a live widget. The ring does not encode team membership or player identity. The approved Profilo Figurina identity hero reuses this ring; keep neutral shared avatars in other contexts. Achievement badges use compact folded ribbons with live icons and labels: yellow with ink for Capoclassifica, red with white for Bomber. The existing trophy icon above first place is yellow. Complete-ranking rows use flat primary-blue angular ends for rank and metric, with a calm white information surface; do not add gradients to these rows. Preserve badge eligibility and tie ordering.

Keep all three decorative podium blocks and numbers for one or two qualifying players; absent places have no player content or action. Zero qualifiers retain the existing mode-specific empty state. Long names, large text and constrained viewports use readable stacked entries. On short landscape screens the header can scroll away to leave room for ranking content. Keep names, metrics, badges, profile targets and CSV controls as live widgets. Generale and Marcatori preserve their existing metrics and ranking rules; CSV continues to export the general ranking from either tab.

Classifica and Nuova Partita share `BrandChoiceSelector`: the same pill outline, blue selected fill, uniform 30dp corners and 28px Barlow Condensed action labels. Mode labels retain their existing copy and semantics; Generale/Marcatori remain connected to their page controller, including swipe selection. The shared selector scrolls horizontally when an unbroken label cannot fit at the current text scale.

### Classifica pairs — approved 7 October 2026

Classifica has a compact 1vs1/2vs2 control above Generale/Marcatori. The 1vs1 view ranks individuals; 2vs2 ranks recurring unordered pairs. Keep the approved South Africa podium, painters, fonts and palette. Pair identities reuse two existing ranking rings with live names; long names and enlarged text retain the readable stacked fallback. Points, attributed goals and badges stay live. CSV exports Generale for the selected mode from either tab.

Pair podium places and complete-ranking rows open Profilo coppia. Its approved composition uses a yellow identity panel, the existing achievement ribbons and white statistics/member/opponent/history panels. Both member rows link to their existing individual profiles. Preserve complete shared history and archived members. This approval covers the reviewed Flutter layouts; no new artwork master is introduced.

## Profilo Figurina — direction approved 12 September 2026

The user selected Figurina for the profile refresh: a prominent yellow identity hero with black foosball artwork and sweeping brand ribbons, followed by one calm panel grouping the six existing statistics and compact recent form. Keep the player name, ring initial, presence/archive status, points and earned badges as live widgets. Preserve every metric and the complete relationships, head-to-head and personal-history content. The reviewed Flutter hero, relationship sweeps and footer are approved for integration; the user accepted the running composition and subsequent B gradient refinement.

Keep the yellow hero and make achievement ribbons visibly distinct from its background. The user approved a compact ivory backing behind the existing yellow/ink Capoclassifica and red/white Bomber ribbons. Preserve their shared colors and allow the backing and badges to wrap with content. Do not infer a new badge rule or recolor shared badges from generated pixels.

For Intesa e rivalità, the user explicitly approved the first detail prototype: a small bottom-right sweep of tapered yellow, green and blue ribbons with white separation and a narrow red accent, clipped within each rounded white card. Preserve the original group and martial-arts icon shapes; the proposed replacement foosball emblems were rejected. Keep the names and counts clear of the decoration, use flat information surfaces and omit the former straight left-edge color stripe. This is a scoped relationship-card treatment, not a replacement for the existing sheet accent or decoration for every row.

The generated composition is not authorization for new row actions, navigation, a slogan, modified statistics or fabricated data. Existing profile/back behavior and complete history remain available. Long names, tied relationships, empty states, large text and constrained viewports must reflow and scroll. Reuse approved decorative assets where suitable; any newly authored or materially revised SVG, PNG or painter master still requires explicit review before integration. A concept approval does not approve unseen artwork or establish runtime validation.

The approved decoration uses normalized Flutter Bézier paths with directional gradients from central brand colors. Dimensional figure/rod and football details reuse source rectangles of the unchanged `live-r1/live-scene.png`; no screen content is rasterized. Exact approved geometry and PNG identity are recorded in `design/south-africa-2010/assets/profile-figurina/manifest.json` and checked by `check_profile_assets.py`. Long names, additional earned badges and enlarged text use an expanding yellow identity panel; decoration yields to readable content. The footer scrolls with the content and is omitted in constrained large-text/short-landscape layouts.

Figurina gradient refinement B is approved: a broad radial highlight on the yellow hero blends toward a warm golden edge; hero ribbons use directional shading and restrained highlights, with a subtler version on relationship sweeps. White information surfaces and the existing footer treatment stay unchanged.

## Storico Tabellone — direction selected 12 September 2026

The user selected Tabellone for Storico without the top-right foosball figure. Keep a compact navigation header and filter summary, date-grouped white match cards and prominent central scores. Team 1 stays blue on the left and team 2 orange on the right; scores use flat fills with white on blue and ink on orange. Preserve a winner cue beyond color, separate match-detail and overflow actions, and the complete existing filter, correction and deletion behavior. The count remains live with correct singular/plural copy.

Header, paired card-base sweeps and the broader footer use decorative Flutter Bézier paths with restrained directional gradients. Names, scores, dates, format/rivalry, counts, icons and controls remain widgets; no new raster artwork is needed. The user explicitly approved the Flutter-rendered header, paired card sweeps and footer geometry with directional gradients on 12 September 2026. Exact source and preview identities are recorded in `design/south-africa-2010/assets/history-tabellone/manifest.json`. The user separately approved the integrated running Tabellone screen on 12 September 2026. Materially revised painter artwork requires renewed review. Names and scores reflow at large text or constrained widths, and decoration yields to scrolling content rather than squeezing it. The other screens and existing filter/detail/edit sheets retain their current behavior and visual treatment.

## Correggi partita — Distinta approved 13 September 2026

The user approved the integrated Distinta editor: a full-height route with compact date/time controls, the shared blue format selector and two stacked team cards. Each white card groups player replacement, final team score and scorer counts; headers use flat team blue with white text and orange with ink text. Reuse the unchanged approved profile corner sweep and sheet ribbon accent. No new raster or painter master is introduced. Names, numbers, icons and controls remain live Flutter widgets.

Remove Altre opzioni and per-goal dropdowns. In 2v2, per-player counters assign only available goals; changing a score leaves any missing or excess attribution explicit. In 1v1, show known attribution and require one explicit confirmation for missing goals. Keep Rivalità directly available in 1v1, and preserve an existing flagged 2v2 record with a way to clear its flag. Player replacement remains beside each name and requires confirmation before invalidating known goals.

Save and cancellation stay reachable. At enlarged text or short heights, the title scrolls with the form and Save uses the shorter SALVA label. Roster heading, search and results share a scrollable sheet so keyboard space does not hide choices. The time picker uses numeric input only, with no dial or mode toggle. Its fields use ivory when idle and brand blue with white text when selected, with body typography rather than the scoreboard display style. Draft cancellation, failed-save recovery, existing History entry points and repository ownership are preserved; this approval does not broaden other screens or change scoring rules.

## Altro and Dati — Pass artwork approved 13 September 2026

Both routes share one Pass header, ticket template and footer. The user approved the combined header with Dati’s blue sweep and Altro’s red, green and yellow sweeps, then increased the top-right blue/red separation. Reuse Altro’s ticket proportions, centred side notches, dashed perforation, icon compartment and upper-right ribbon for both routes. Tickets are single live actions; format badges and descriptions wrap with content. At large text sizes, icons move above content and perforations yield to readability.

The shared footer preserves the approved blue sweep, smooth yellow taper and continuous green/red/black ribbons extending through the bottom clipping edge. Green meets black without an ivory gap; the black sweeps frame the existing cropped football. Exact approved geometry, decorative gradient stops and unchanged live-r1 PNG identity belong to `design/south-africa-2010/assets/pass/manifest.json`. These decorative colors remain in the shared artwork master; semantic application colors stay unchanged.

Altro keeps Storico and Dati navigation with the existing bottom bar. Dati groups Crea backup and Esporta risultati under ESPORTA and Ripristina backup under RIPRISTINA, retaining JSON/CSV formats and explicit replacement confirmation. Export actions use share icons; restore uses a file action icon. All controls and labels remain widgets. The user separately approved the integrated running Altro and Dati screens on 13 September 2026.

On 2026-10-01 the user requested a fixed frame for Altro: its heading and outer header ribbons stay at the top, and its footer ribbons/football stay immediately above the bottom navigation. Only ARCHIVIO E DATI and the tickets scroll in the space between them; the ticket decorations move with their cards. Reuse the approved Pass artwork without changing its paths, gradients or raster source. In compact or enlarged-text layouts, retain the simplified header and reduce the fixed footer to 32 logical pixels so the actions remain reachable. Dati retains its existing scrolling composition.

## Runtime appearance selection — concept approved 7 October 2026

The user approved the two-state Aspetto concept for the dual-style integration. This is a scoped exception to the earlier style-switcher exclusion: add an ASPETTO action below the existing Storico/Dati actions in Altro, using each presentation's current action components. Open a full-screen route with back to Altro and no bottom tab bar. Existing destinations keep their accepted compositions; this approval does not restyle either donor's Home or Classifica.

Both presentations use the same content order: ASPETTO, “Scegli lo stile dell’app.”, and stacked South Africa 2010 / Italia ’90 preview cards. A selected outline, filled check and In uso badge identify the active style. The page frame, typography and selected color follow the current presentation: South Africa blue and Italia brick red. Each card's decorative preview keeps its own donor identity regardless of the surrounding style. Outer decorations stay fixed; content scrolls and decorations simplify when text size or available height requires it.

Tapping a card changes the style without Apply/Save or an app restart, and the Aspetto route stays open. Show the committed choice after persistence succeeds; a failed write keeps the old appearance and offers recoverable feedback. Preserve a single application data/state store and existing navigation, drafts and operations. Implementation and runtime verification are recorded in `design/runtime-style-selection/IMPLEMENTATION.md`; concept acceptance alone is not runtime verification.

Reuse live Flutter views for headings, labels, cards, borders, selection marks and layout, and existing widgets/painters for framing where possible. Decorative previews reuse the approved South Africa transparent Home hero and Italia's existing tricolour football and Ciao SVGs; approved raster layers remain valid where the existing implementation needs them. Do not use the generated concept or a captured application screen as a runtime screen/card image, instantiate functional Home screens for previews, or rasterize interactive content. The approval covers the reviewed composition and existing-art reuse; unseen or materially revised artwork still requires explicit user review.

On 7 October 2026 the user reviewed the running selector and approved a scoped frame correction. Reuse each style's working-screen header and back control: South Africa's centred Pass title and icon-only chevron; Italia's compact BILIARDINO masthead, arrow and page title. The cards retain their shared content order and selection behavior. Remove the separate circular ball badge from the Italia preview and centre the existing Ciao mascot without modifying its SVG.

Aspetto's non-interactive outer artwork fills the screen behind the system safe areas and remains fixed while cards scroll. Protect back/title/cards with real system insets; preserve status-bar contrast and reachable final actions. South Africa uses the existing page header and footer masters at their intrinsic aspect ratios, cropping the footer at the physical screen edge rather than stretching it into a shallow box. At compact or enlarged text sizes omit the header decoration and show a shallow crop of the proportional footer, giving scrolling choices priority. Italia reuses its existing working-page backdrop outside the safe-area content. Fixed display headings fit the available width; Italia's brand lockup retains its original type size while instructions, card labels and feedback honor the full user text scale. These changes apply only to Aspetto; existing donor page compositions and all artwork masters remain unchanged. This approval covers the specified reuse and layout correction; Flutter/native previews record implementation conformance.

On 7 October 2026 the user clarified the Aspetto Italia card composition: add the existing tricolour football (`football-mark.svg` / ItaliaFootball) on the left and retain the existing Ciao mascot on the right. Centre the two artworks as one group horizontally and vertically within the preview area, preserving their proportions and scaling the group down when needed. This supersedes the earlier Ciao-only preview and corrects the initial football-only implementation. Both asset masters and their existing masthead/Home usage remain unchanged.

The user also approved keeping the illustrated South Africa podium when additional achievement badges would otherwise force ordinary names/scores into stacked cards. In both 1vs1/2vs2 and Generale/Marcatori, retain Capoclassifica and Bomber in the podium columns. Display every other earned ribbon immediately below the illustration, grouped under the corresponding player or pair name using existing white surfaces, typography and ribbon components. Fit calculations use the same inline badge set as rendering. Genuine constrained names, metrics, viewport widths and large text keep the readable stacked fallback, which shows all badges within each entry and needs no duplicate additional group. Preserve every badge's eligibility, descriptions, rank/tie ordering, metrics, profile targets and CSV rules. This changes presentation only and introduces no artwork master or Italia ranking redesign.


### Classifica additional awards — ticket artwork approved 13 October 2026

The user selected concept 3 for the additional awards below the South Africa podium. Use a notched white ticket with a yellow identity compartment, the existing ranking rings, a dashed perforation and one live folded ribbon plus readable description per award. Individuals and pairs share this composition. Preserve eligibility, tie ordering, primary podium badges, metrics, profile navigation and the existing stacked podium fallback; no new card action is introduced. Descriptions come from actual PlayerBadge data, including the live streak value, rather than the prototype fixture.

Reuse PassTicketShape, the shared ticket perforation, RankingIdentity, existing badge geometry and shared color/font tokens. Short ordinary identities use the side compartment; long names or enlarged text reflow into a yellow header with awards below. Decoration yields to readable content. No new runtime PNG or SVG is required. The user explicitly approved the exact ticket sweep painter and its running Alex/Eva rendering on 13 October 2026. Its approved source SHA-256 is `47f879ba609c28dfb4aeedbff2901439e75a5b70f6855b7a717622fa35abdc95`; exact source and review image identities are recorded in [the ticket manifest](design/runtime-style-selection/ranking-award-tickets/manifest.json). New or materially revised artwork still requires explicit review. Review provenance lives under design/runtime-style-selection/ranking-award-tickets/.


## Feedback — dual-style concepts approved 13 October 2026

The user approved both feedback screen concepts and their shared form scope on 13 October 2026, replying “q9: we are aligned” to the combined review. The exact [Italia ’90 concept](design/feedback/r1/italia90-feedback.png), [South Africa 2010 concept](design/feedback/r1/south-africa-feedback.png), [comparison](design/feedback/r1/feedback-comparison.png), prompts and artifact hashes are retained in [the generation and approval record](design/feedback/r1/generation.json). These are review images generated through CLIProxyAPI, not runtime screen backgrounds or newly approved production artwork masters. The user subsequently authorized autonomous implementation on the separate feedback branch.

Use the same calm form hierarchy in both presentations: FEEDBACK heading, short invitation, a prominent multiline message field, optional email, explanatory context copy and a full-width primary action. Entry belongs directly in Altro; the full-screen form has a back control and no bottom navigation. Reuse each style's accepted utility-screen frame: Italia's compact BILIARDINO masthead, Anton/Barlow pairing, ivory canvas, brick-red action and peripheral tricolour/pitch decoration; South Africa's centred Barlow Condensed title, ivory canvas, blue action and Pass ribbon frame. Use current shared tokens and existing approved artwork rather than interpreting generated colors, grain, font shapes or simplified footer crops as new masters.

The user subsequently required pixel-perfect reproduction of these exact proposals. Treat their specific form geometry, visual hierarchy, field fills, action proportions and artwork crops as the comparison target; the current frame defaults are only reusable starting points. Compare running Flutter captures directly with the retained PNGs before accepting snapshot baselines. Any unresolved visual difference must be corrected or explicitly reviewed rather than silently dismissed as a generation artifact.

Keep labels, explanatory copy and controls clear of artwork. Content scrolls with the keyboard and enlarged text; decoration yields to readability. Error, sending and confirmation states follow the same presentation's controls and typography. The static concepts do not establish runtime contrast, input outlines, keyboard clearance, font metrics, accessibility or delivery validation. Any newly authored or materially revised artwork still requires separate explicit validation.

The user explicitly approved both isolated R2 feedback backgrounds on 13 October 2026, replying “Approve both R2 backgrounds” after reviewing them at the intended 402×874 proportions. Their exact hashes, sizes and generation provenance are recorded in [the R2 manifest](design/feedback/r2/manifest.json). These feedback-only backdrops remove all form text, controls and the masthead logo from the approved screen concepts while retaining peripheral decoration. Reuse live Flutter widgets and the existing football SVG for the masthead. Other screens and original artwork masters retain their current assets. Integrated typography/layout verification remains required; background approval does not assert pixel-perfect font rendering or runtime acceptance.

The user subsequently accepted the displayed live Flutter forms on 13 October 2026, replying “Accept these live forms”. The [accepted capture and correction record](design/feedback/r2/live-form-acceptance.json) preserves this visual baseline: existing font and logo shapes, stronger field outlines and solid action colors are accepted alongside the approved R2 backgrounds. This decision supersedes the unresolved generated-lettering and control-styling differences in the original proposals. Italia’s INVIA FEEDBACK label uses a text-scaled 3.5-logical-pixel optical offset to center Anton’s visible capitals inside the unchanged button bounds, correcting the user-reported alignment issue. Compact and keyboard layouts prioritize readable, centered wrapping controls and scrolling. Runtime behavior, accessibility and delivery still require their own verification.

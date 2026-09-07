---
version: alpha
name: Biliardino — South Africa 2010
description: Approved visual baseline for issue 11. User approved the four mockups and direction on 2026-09-07. Application behavior remains unchanged.
colors:
  primary: "#0057B8"
  on-primary: "#FFFFFF"
  primary-pressed: "#00428D"
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

**Status: approved design baseline, 2026-09-07.** This specification accompanies four raster mockups for GitLab issue 11. The user approved the four mockups and this direction before requesting this dedicated worktree. It is the baseline for future implementation, not a claim that the application already uses these styles. Generated pixels do not override the exact tokens or product rules written here.

The app tracks office table-football players, presence, matches and statistics. Its identity should feel like an energetic South Africa 2010 football poster translated into a useful mobile tool: warm white, confident black condensed titles, sweeping ribbons, deliberate blocks of color and black foosball silhouettes. The header carries the character; the working content stays calm and legible.

The issue mood board is the direction source. Its sample dashboard, timer, English team names and navigation are not product requirements. Preserve Giocatori, Partita, Storico, Classifica and Dati in that order, player management, 1v1/2v2, rules, rivalry, scoring, confirmations, historical corrections, statistics and backups. This experiment has no style switcher or Italia '90 design vocabulary.

Source format: [Google DESIGN.md specification](https://github.com/google-labs-code/design.md/blob/9bf8eae67128b6cc55ad9bf86665767deb4c11cd/docs/spec.md), read 2026-09-07. The file uses its canonical section order and adds project-specific sections afterward. See [RESEARCH.md](design/experiments/south-africa-2010/RESEARCH.md) for tooling and limitations.

## Colors

Use the frontmatter as the approved palette baseline. Values were deliberately chosen for this application; they are not asserted to be pixel samples or official tournament brand values.

Warm background and white panels dominate everyday screens. Blue marks general actions, selection and the active tab. Green marks presence, success and kickoff. Yellow adds energy and highlights first place. Red serves errors/destructive actions, and can appear as a narrow decorative ribbon. Orange is reserved for the second team in match contexts.

Team identity has its own tokens even where values match a brand token. Keep Squadra 1 on the left and Squadra 2 on the right; also label them and show selected/check states. Presence uses text plus the switch position, never just a dot. Use neutral initials outside a match so avatar hues do not compete with teams or status.

Calculated solid-color pairs: ink/background 17.31:1; secondary text/background 6.18:1; white/blue 6.87:1; white/green 5.10:1; white/red 5.62:1; ink/yellow 12.07:1; ink/orange 7.18:1. White/orange is only 2.63:1, so orange panels use ink text. Status text on pale green uses the darker success-pressed value: the original success value produced only 4.44:1 on that pale surface. Pale dividers are decorative; essential input outlines use the stronger outline token. The field-outline component describes the filled outline itself, with 3.72:1 contrast against white; it is not a text style. Validate rendered disabled, selected, focus and overlay states separately.

## Typography

Use **Barlow Condensed 800/900** for screen headings, short action labels and score/celebration moments. Use **Barlow 400/600** for names, explanatory text, metadata and navigation. Real font specimens and licenses are stored in [type/](design/experiments/south-africa-2010/type/README.md) for the offline review gallery; they are not yet registered in the application. Bundle the selected font files and their license locally when implementation starts. Generated lettering is a visual approximation, not a font asset.

The type scale is defined above. Scores may scale from 80 to 112 logical pixels to accommodate two digits and constrained layouts. Preserve large-text settings for utility content; allow names to wrap and row height to grow instead of shrinking all text. Use aligned numeral widths for statistics where supported by the selected font, verified in Flutter.

Keep the application's existing label casing. Major display headings may remain uppercase; names and explanations stay readable in their existing casing. Avoid excessive tracking, faux-condensing, outlined titles and glow.

## Layout

The reference viewport is 402 × 874 logical pixels, including system safe areas. Token dimensions written as px map to Flutter logical pixels, not physical screenshot pixels. Respect the actual device's insets; never hard-code a Dynamic Island into the application.

Use 16-pixel page gutters, a 4-pixel base rhythm, 24-pixel section gaps and at least 48 × 48 logical pixels for interactive targets. Primary bottom actions start at 56 pixels high and grow with text. Labels and overflow menus remain separate tappable areas.

Screen mastheads are compact. The players header decoration should consume at most about 100 pixels beneath the top safe area. Six ordinary roster rows should fit at the reference size; larger rosters and accessibility sizes scroll. Do not add a dashboard ahead of the roster.

Match setup is one scrolling screen with a pinned kickoff action above the existing bottom navigation. Mode, rules, team composition, rivalry and player selection remain available in the existing order. A mockup showing two scroll positions is not a new multi-step wizard. Never squeeze the entire setup into an unreadably dense phone.

Live scoring prioritizes two large score panels, names, add/undo controls, rules and the real save state. Artwork stays in the upper band or panel edges. Bottom navigation remains present. On narrow/landscape or large-text layouts, permit scrolling and reflow of surrounding content while keeping team association clear.

Leaderboard and profile use compact headers and readable rows. Preserve the podium as a smaller graphic group so the full ranking is not pushed unnecessarily far down. Dialogs and sheets must remain scrollable with the keyboard and large text.

## Elevation & Depth

Use solid fills, spacing and subtle dividers for hierarchy. Ordinary list panels have no drop shadow. Interactive secondary controls use a visible outline. Bottom sheets may use a standard restrained shadow and dim scrim to separate modal content. No neon, scanlines, glow, glass panels or decorative gradients.

If a dimensional foosball illustration is approved later, its shading belongs inside the artwork. It must not introduce a separate gradient system into buttons or cards.

## Shapes

Use 8-pixel radii for small slots, 12 for buttons and inputs, 16 for grouped panels and 24 for sheet top corners. Avatars, rank medallions and presence switches are circular or pill shaped because of their roles.

The distinctive graphic is an asymmetric ribbon sweep: broad yellow, green and blue arcs with a narrow red accent and warm-white separation. Use a small shared set of normalized paths for header, corner and celebration compositions. Avoid a generic repeated rainbow stripe on every row. Black foosball figures should be simple recognizable silhouettes on a rod, not the Italia '90 Ciao mascot.

## Components

The frontmatter provides core colors, typography and dimensions. Component variants below define behavior-sensitive states without changing business logic.

| Component family | Required treatment and states |
| --- | --- |
| App shell/header/navigation | Five existing destinations, selected indicator, opaque navigation surface, safe areas, keyboard/focus support; retained leave-match confirmation |
| Primary/start/secondary/destructive buttons | Normal, pressed, focused, disabled and busy; progress replaces an icon without changing the action's meaning; no duplicate submission |
| Player row/avatar/presence | Active, present, absent, archived and mutating; name/profile target, presence semantics, overflow actions; archived status replaces switch |
| Input/dialog/sheet | Label, helper/error, focus, keyboard, cancellation, confirmation and operation failure; use the same surfaces for add/rename/archive, scorer selection, filters and corrections |
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

## Do's and Don'ts

- Do use consistent shared components and semantic tokens across every state.
- Do keep all five tabs, existing content, persistence, calculations and confirmation rules.
- Do preserve Italian labels; proposed copy changes require explicit review.
- Do use the mockups to review composition and character, and this file for exact implementation values.
- Do accommodate text scaling, VoiceOver, reduced motion and small/landscape layouts.
- Do keep first-to-N result registration gated by the existing victory condition and confirmation.
- Do not add the mood board's timer, dashboard home, alternate navigation or English team names.
- Do not turn screenshots into runtime backgrounds or rasterize controls/text.
- Do not create a new illustration or unique component for every screen.
- Do not combine this direction with Italia '90 or introduce a runtime theme selector.
- Do not treat unvalidated generated pixels as an approved final UI or an accessibility test.

## Motion

This section is a project extension. Durations and lifecycle rules are explicit prose because the current core format has no typed motion group. Map these roles to one Flutter motion policy when implementation starts; no animation package is required by this proposal.

| Role | Proposed duration | Presentation and reduced-motion equivalent |
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

Feedback should answer an event, not loop around idle content. Keep haptics at the existing meaningful goal, kickoff, undo and victory events; do not add repeated haptics to decorative frames. Loading feedback must remain understandable with reduced motion.

Score data updates immediately, independent of artwork. Rapid goals must not create stacked full-screen announcements: replace/coalesce the visible visual effect while retaining correct scorer/score semantics. Goal feedback remains nonblocking. Victory isolates background interaction and semantics, but its own actions never wait for confetti. Cancel controllers/overlays on dismissal, rematch, change-team and tab changes. Entry reveals must not finish invisibly on offscreen IndexedStack pages.

## Assets and Flutter mapping

| Design element | Planned implementation |
| --- | --- |
| Palette/type/spacing/radii | ThemeData, TextTheme and named theme extensions/constants derived from this document |
| Controls and data surfaces | Reusable Flutter widgets, retaining existing Cubit events and repository contracts |
| Ribbons/arcs/pitch lines | Shared CustomPainter/clip geometry; normalized paths scale with layout |
| Foosball figure/football/stadium | A small local versioned SVG set, with separate layers when motion needs them |
| Optional shaded hero | Transparent PNG only if the dimensional art treatment is approved |
| Confetti | Bounded programmatic ribbon particles, deterministic seed for golden tests |
| Fonts | Local Barlow and Barlow Condensed files plus licenses |

SVG rendering may require a Flutter dependency; make that decision after the asset set is approved. There is no need to add an SVG renderer if the final marks remain simple programmatic paths. No runtime reference may point to the issue upload or a generated-image cache path.

The approved vector masters are available in the [R1 asset review](design/south-africa-2010/assets/r1/review.html), with an [inventory and usage guide](design/south-africa-2010/assets/README.md) and [hashed manifest](design/south-africa-2010/assets/r1/manifest.json). These include a rigid foosball figure, its rod assembly, a football and two ribbon geometry references. **All five R1 SVG assets were explicitly approved by the user on 2026-09-07 at the manifest hashes.** The user still requires review of newly created or materially revised artwork before integration. Ribbon SVGs are reference geometry for a shared painter; the review PNG is not a runtime asset. A shaded PNG or stadium silhouette is conditional on a concrete composition need and would require its own review.

## Review coverage and implementation sequence

The four mockup deliverables cover populated players, complete setup (two scroll positions), live match and leaderboard. Their examples are recorded in [MOCKUP_BRIEF.md](design/experiments/south-africa-2010/MOCKUP_BRIEF.md). Remaining states are covered by the component matrix, not silently omitted from implementation.

The visual direction and four mockups are approved. The user authorized phased execution using feature-plan-scaffold, with new assets presented for explicit approval. The sequence is discovery/baseline; artwork preparation and review; foundations and chrome; players/setup; live scoring and celebrations; history/rankings/profiles/data/bootstrap; hardening; final regression, golden, accessibility and simulator verification. Work belongs on the issue's South Africa 2010 implementation branch. This approval does not claim implementation completion or authorize merging/deployment.

The final implementation must run flutter analyze and flutter test, retain existing functional tests, add representative component/state goldens, and review the complete navigation flow on iPhone. Raster mockups and DESIGN.md lint cannot establish runtime performance, font metrics, hit areas, contrast over illustrations, correct VoiceOver behavior or persistence correctness.

# Four mockups — review brief

Status: approved by the user on 2026-09-07. These are four views of one proposed visual system, not four competing styles. App code and persisted data are not changed by this work.

## Shared constraints

- Style authority: issue 11's South Africa 2010 mood board and the accompanying [DESIGN.md](../../../DESIGN.md).
- Keep Giocatori, Partita, Storico, Classifica and Dati, with the current tab selected.
- Keep full top/bottom safe areas and the home indicator in the raster references. Real Flutter safe areas come from the device.
- Use real names and source-derived labels. No dashboard home, match timer, style selector or unrelated features.
- Images establish visual direction; exact font metrics, token colors, touch targets and accessibility are implementation checks.

## 01 — Players home

File: [01-players.png](mockups/01-players.png).

Keep the six players in current order: Andrea, Giulia, Luca, Marco, Paolo, Sara. Andrea/Luca/Marco/Paolo are present; Giulia/Sara are absent. Show 4/6 presenti, Pronti a giocare, all six switches, overflow menus, initials, NUOVO and the five tabs. Giocatori is selected.

Review emphasis: does the compact foosball/ribbon masthead convey the reference while keeping the roster easy to scan? Are the neutral avatars and explicit presence states clear?

Archived-player and empty-roster variants inherit the component rules and remain required during implementation; they are not extra populated rows in this screenshot.

## 02 — Match setup

File: [02-match-setup.png](mockups/02-match-setup.png).

One deliverable shows two scroll positions of the same screen. It is not a wizard. The upper view covers mode, rules, random/balanced controls and complete team cards. The lower view covers the team-card context, rivalry availability and every present-player assignment row. The pinned kickoff action and five tabs remain visible in both.

Consistent example state: 2v2; Primo a N; target 10; win-by-two on; Squadra 1 Andrea/Luca; Squadra 2 Marco/Paolo; rivalry off but available because both teams are complete. Andrea/Luca have S1 selected, Marco/Paolo S2. Giulia/Sara are absent and do not appear in assignment. Kickoff is enabled; Partita is selected.

Review emphasis: hierarchy and density of the controls, unambiguous assignment, readable team slots, and whether the second scroll position feels like a natural continuation.

Also required later: 1v1, free scoring, incomplete teams, unavailable players, full/disabled assignment, saving rules, active rivalry and its overview/confirmation.

## 03 — Live match

File: [03-live-match.png](mockups/03-live-match.png).

The same two teams now play at 9–10, with PRIMO A 10 · +2. This deliberately exercises a two-digit score before the win-by-two condition is met. Both team add/undo controls are available. REGISTRA RISULTATO is disabled because the automatic target-score condition has not been met. Keep back/reset and all five tabs, Partita selected.

Squadra 1 uses white lettering on blue; Squadra 2 uses dark lettering on orange. No winner announcement, timer or rivalry banner is present in this state.

Review emphasis: score dominance, two-digit fit, readability of names and orange-side text, access to scoring/undo, and restrained artwork.

Later state coverage includes the 2v2 scorer picker, 1v1 immediate scorer attribution, zero/undo-disabled, free-score manual saving, goal feedback, result confirmation/correction, save failure and victory/rematch. Motion duration and cancellation are specified in DESIGN.md.

## 04 — Leaderboard

File: [04-leaderboard.png](mockups/04-leaderboard.png).

Marcatori is selected. Preserve the installed app's four-scorer example: Marco 7 gol, Paolo 3 gol, Andrea 2 gol, Luca 1 gol. On the podium Paolo is second on the left, Marco first in the center, Andrea third on the right. Marco has Capoclassifica and Bomber; Paolo has Capoclassifica. These are source-defined awards, not podium labels invented for the mockup. The remainder row is Luca, rank 4, with the source text 1 partite · 0 vittorie. Classifica is selected in the five-tab navigation. Retain the export affordance.

Review emphasis: a lower, solid podium without neon columns, long badge labels, preserved ranking information and visual consistency with home.

General ranking, longer lists, fewer than three ranked players, empty states and profile navigation remain implementation coverage. Four players here is the actual reference dataset, not a constraint on list size.

## Approved review baseline

The user approved the set. Future changes affecting ribbon/artwork prominence, typography, roster/form density, team-panel contrast or podium treatment should be reflected in the shared root specification. Approval establishes the visual direction; it does not assert pixel-perfect native font/color implementation or complete state testing.

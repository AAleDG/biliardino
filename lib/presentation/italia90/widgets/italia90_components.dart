import 'package:flutter/material.dart';

import '../../../models/player.dart';
import '../theme/italia90_motion.dart';
import '../theme/italia90_tokens.dart';
import 'avatar.dart';
import 'design/ranking_podium_artwork.dart';
import 'italia90_artwork.dart';

class BrandMasthead extends StatelessWidget {
  const BrandMasthead({
    super.key,
    this.compact = false,
    this.leading,
    this.actions = const [],
    this.mark,
    this.markKey,
  });
  final bool compact;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? mark;
  final Key? markKey;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (leading != null) ...[leading!, const SizedBox(width: 4)],
      Expanded(
        child: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            'BILIARDINO',
            maxLines: 1,
            softWrap: false,
            style: compact ? Italia90.heading : Italia90.display,
          ),
        ),
      ),
      if (actions.isNotEmpty) ...[const SizedBox(width: 4), ...actions],
      if (mark != null) ...[
        const SizedBox(width: 12),
        KeyedSubtree(
          key: markKey,
          child: ExcludeSemantics(child: mark!),
        ),
      ],
    ],
  );
}

/// Compact persistent lockup used by every destination except Home.
class ItaliaCompactMasthead extends StatelessWidget {
  const ItaliaCompactMasthead({
    super.key,
    this.semanticsKey,
    this.footballKey,
    this.leading,
    this.actions = const [],
  });

  final Key? semanticsKey;
  final Key? footballKey;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Semantics(
    key: semanticsKey,
    header: true,
    label: 'BILIARDINO',
    child: BrandMasthead(
      compact: true,
      leading: leading,
      actions: actions,
      markKey: footballKey,
      mark: const ItaliaFootball(size: 40),
    ),
  );
}

/// The approved Home brand lockup, including Home-only supporting copy.
///
/// The optional subtitle makes the Home-only supporting copy explicit so it is
/// not repeated by working-screen headers.
class ItaliaHomeMasthead extends StatelessWidget {
  const ItaliaHomeMasthead({
    super.key,
    this.showSubtitle = true,
    this.compact = false,
    this.wordmarkSize,
    this.markSize,
    this.ruleWidth,
    this.ruleInset = 0,
    this.ruleOffsetY = 0,
    this.markOffsetY = 0,
    this.leading,
    this.actions = const [],
    this.semanticsKey,
    this.footballKey,
  });

  final bool showSubtitle;
  final bool compact;
  final double? wordmarkSize, markSize, ruleWidth;
  final double ruleInset;
  final double ruleOffsetY, markOffsetY;
  final Widget? leading;
  final List<Widget> actions;
  final Key? semanticsKey;
  final Key? footballKey;

  @override
  Widget build(BuildContext context) => Semantics(
    key: semanticsKey,
    header: true,
    label: 'BILIARDINO',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  'BILIARDINO',
                  style: Italia90.display.copyWith(
                    fontSize: wordmarkSize ?? (compact ? 42 : 60),
                    height: 0.92,
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[const SizedBox(width: 4), ...actions],
            const SizedBox(width: 12),
            Transform.translate(
              offset: Offset(0, markOffsetY),
              child: _ItaliaHomeLogo(
                footballKey: footballKey,
                size: markSize ?? (compact ? 56 : 80),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: ruleInset),
            child: Transform.translate(
              offset: Offset(0, ruleOffsetY),
              child: _ItaliaTricolourBar(
                width: ruleWidth ?? (compact ? 64 : 84),
              ),
            ),
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 7),
          const Text(
            key: ValueKey('home-subtitle'),
            'PICCOLE PARTITE\nGRANDI AMICIZIE',
            style: TextStyle(
              fontFamily: 'Italia Barlow',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.18,
              letterSpacing: 2.6,
            ),
          ),
        ],
      ],
    ),
  );
}

class _ItaliaHomeLogo extends StatelessWidget {
  const _ItaliaHomeLogo({required this.footballKey, required this.size});

  final Key? footballKey;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      KeyedSubtree(
        key: footballKey,
        child: ItaliaFootball(size: size),
      ),
      const SizedBox(height: 1),
      Text(
        "ITALIA '90",
        style: Italia90.label.copyWith(
          fontSize: 11,
          letterSpacing: 1,
          height: 1,
        ),
      ),
    ],
  );
}

class _ItaliaTricolourBar extends StatelessWidget {
  const _ItaliaTricolourBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 3,
    child: Row(
      children: [
        SizedBox(
          width: width * 0.5,
          height: 3,
          child: const ColoredBox(color: Italia90.green),
        ),
        SizedBox(
          width: width * 0.1667,
          height: 3,
          child: const ColoredBox(color: Italia90.surface),
        ),
        SizedBox(
          width: width * 0.3333,
          height: 3,
          child: const ColoredBox(color: Italia90.red),
        ),
      ],
    ),
  );
}

/// Numbered setup section band shared by the Italia '90 working screens.
class ItaliaSectionBand extends StatelessWidget {
  const ItaliaSectionBand({
    super.key,
    required this.title,
    required this.step,
    this.titleFontSize = 20,
    this.height,
  });

  final String title;
  final int step;
  final double titleFontSize;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    final bandHeight = height ?? (compact ? 40.0 : 56.0);
    final accentWidth = compact ? 64.0 : 76.0;
    final stepLabel = step.toString().padLeft(2, '0');
    return Semantics(
      header: true,
      label: title,
      child: ExcludeSemantics(
        child: SizedBox(
          height: bandHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Italia90.panelRadius),
            child: ColoredBox(
              color: Italia90.primary,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    right: accentWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: Italia90.heading.copyWith(
                              color: Colors.white,
                              fontSize: titleFontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: accentWidth,
                    child: ItaliaDiagonalStripes(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          stepLabel,
                          style: Italia90.heading.copyWith(
                            color: Italia90.primary,
                            fontSize: titleFontSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paper-slip action used by the data-management screen.
///
/// The top rule is decorative; the whole slip remains one accessible action.
class ItaliaDataActionSlip extends StatelessWidget {
  const ItaliaDataActionSlip({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final contentColor = enabled ? Italia90.ink : Italia90.muted;
    final accentColor = enabled ? Italia90.primary : Italia90.muted;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: '$title. $subtitle',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: Italia90.panel,
          elevation: 0,
          child: InkWell(
            onTap: onPressed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 9,
                  child: ColoredBox(color: Italia90.primary),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 56,
                        child: Center(
                          child: Icon(icon, size: 42, color: accentColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Italia90.heading.copyWith(
                                color: accentColor,
                                fontSize: 22,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Italia90.body.copyWith(
                                color: contentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        height: 56,
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            size: 30,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable diagonal accents for the red bands used across working screens.
class ItaliaDiagonalStripes extends StatelessWidget {
  const ItaliaDiagonalStripes({
    super.key,
    this.backgroundColor = Italia90.brickContainer,
    this.stripeColor = Colors.white,
    this.child,
  });

  final Color? backgroundColor;
  final Color stripeColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ItaliaDiagonalStripesPainter(
      backgroundColor: backgroundColor,
      stripeColor: stripeColor,
    ),
    child: child,
  );
}

class _ItaliaDiagonalStripesPainter extends CustomPainter {
  const _ItaliaDiagonalStripesPainter({
    required this.backgroundColor,
    required this.stripeColor,
  });

  final Color? backgroundColor;
  final Color stripeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor!);
    }
    final stripePaint = Paint()..color = stripeColor;
    final firstStripe = Path()
      ..moveTo(size.width * 0.22, size.height)
      ..lineTo(size.width * 0.52, 0)
      ..lineTo(size.width * 0.68, 0)
      ..lineTo(size.width * 0.38, size.height)
      ..close();
    final secondStripe = Path()
      ..moveTo(size.width * 0.58, size.height)
      ..lineTo(size.width * 0.88, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.7, size.height)
      ..close();
    canvas
      ..drawPath(firstStripe, stripePaint)
      ..drawPath(secondStripe, stripePaint);
  }

  @override
  bool shouldRepaint(_ItaliaDiagonalStripesPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.stripeColor != stripeColor;
}

/// Keeps the action name visible during work and makes its busy state accessible.
class ItaliaAction extends StatelessWidget {
  const ItaliaAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.result = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool result;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    key: key,
    container: true,
    button: true,
    enabled: !busy && onPressed != null,
    label: busy ? '$label, in corso' : label,
    onTap: busy ? null : onPressed,
    child: ExcludeSemantics(
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: result
            ? FilledButton.styleFrom(backgroundColor: Italia90.red)
            : null,
        child: _ItaliaActionContent(label: label, busy: busy, icon: icon),
      ),
    ),
  );
}

/// Centers the label in the button while keeping leading status/icon content
/// in a stable accessory slot.
class _ItaliaActionContent extends StatelessWidget {
  const _ItaliaActionContent({
    required this.label,
    required this.busy,
    required this.icon,
  });

  final String label;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final leading = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Italia90.muted,
            ),
          )
        : icon == null
        ? null
        : Icon(icon, size: 22);

    if (leading == null) {
      return Center(child: Text(label, textAlign: TextAlign.center));
    }

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(label, textAlign: TextAlign.center),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: Center(child: leading),
          ),
        ],
      ),
    );
  }
}

/// Presentation only. Repository actions and menu contents stay with the screen.
class ItaliaRosterRow extends StatelessWidget {
  const ItaliaRosterRow({
    super.key,
    required this.name,
    required this.present,
    required this.onProfile,
    required this.onPresence,
    required this.actions,
    this.archived = false,
    this.presenceKey,
    this.avatarColor,
    this.avatarSize = 40,
  });
  final String name;
  final bool present;
  final bool archived;
  final Key? presenceKey;
  final VoidCallback onProfile;
  final ValueChanged<bool>? onPresence;
  final Widget actions;
  final Color? avatarColor;
  final double avatarSize;

  @override
  Widget build(BuildContext context) => Material(
    color: Italia90.panel,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              label: 'Profilo di $name',
              onTap: onProfile,
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(Italia90.panelRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        PlayerAvatar(
                          name: name,
                          size: avatarSize,
                          color: avatarColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: Italia90.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                archived
                                    ? 'Archiviato'
                                    : present
                                    ? 'In ufficio'
                                    : 'Assente',
                                style: Italia90.body.copyWith(
                                  fontSize: 16,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: present && !archived
                                      ? Italia90.success
                                      : Italia90.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!archived)
            Semantics(
              key: presenceKey,
              container: true,
              label: 'Presenza di $name',
              toggled: present,
              enabled: onPresence != null,
              onTap: onPresence == null ? null : () => onPresence!(!present),
              child: ExcludeSemantics(
                child: Switch(value: present, onChanged: onPresence),
              ),
            ),
          actions,
        ],
      ),
    ),
  );
}

class TeamSummary extends StatelessWidget {
  const TeamSummary({super.key, required this.team, required this.playerNames});
  final ItaliaTeam team;
  final List<String> playerNames;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final name in playerNames)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: team.container,
              borderRadius: BorderRadius.circular(Italia90.panelRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  PlayerAvatar(name: name, size: 32, color: team.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: Italia90.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class TeamScorePanel extends StatelessWidget {
  const TeamScorePanel({
    super.key,
    required this.team,
    required this.players,
    required this.score,
    required this.onAdd,
    required this.onUndo,
    this.enabled = true,
  });
  final ItaliaTeam team;
  final List<Player> players;
  final int score;
  final ValueChanged<String> onAdd;
  final VoidCallback onUndo;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ItaliaTeamScoreCard(team: team, score: score),
        const SizedBox(height: 10),
        ItaliaTeamRoster(
          team: team,
          players: players,
          largeText: largeText,
          enabled: enabled,
          score: score,
          onAdd: onAdd,
        ),
      ],
    );
  }
}

class ItaliaScoreValue extends StatelessWidget {
  const ItaliaScoreValue({
    super.key,
    required this.score,
    required this.style,
    this.fit = BoxFit.scaleDown,
  });

  final int score;
  final TextStyle style;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(score),
    tween: Tween(begin: 0.96, end: 1),
    duration: Italia90Motion.durationOf(context, Italia90Motion.score),
    curve: Italia90Motion.curve,
    child: FittedBox(
      fit: fit,
      child: Text('$score', style: style),
    ),
    builder: (context, scale, child) =>
        Transform.scale(scale: scale, child: child),
  );
}

class _ItaliaTeamScoreCard extends StatelessWidget {
  const _ItaliaTeamScoreCard({required this.team, required this.score});

  final ItaliaTeam team;
  final int score;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = (constraints.maxWidth * 1.15).clamp(190.0, 248.0);
      return ClipPath(
        clipper: _ItaliaTeamScoreClipper(team),
        child: ColoredBox(
          color: team.color,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      team.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: Italia90.heading.copyWith(
                        color: team.onColor,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        key: ValueKey('score-team-${team.number}'),
                        container: true,
                        liveRegion: true,
                        label: 'Punteggio ${team.label.toUpperCase()}: $score',
                        child: ExcludeSemantics(
                          child: ItaliaScoreValue(
                            score: score,
                            style: Italia90.score.copyWith(
                              color: team.onColor,
                              fontSize: 112,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ItaliaTeamScoreClipper extends CustomClipper<Path> {
  const _ItaliaTeamScoreClipper(this.team);

  final ItaliaTeam team;

  @override
  Path getClip(Size size) {
    const slant = 18.0;
    final path = Path();
    if (team == ItaliaTeam.one) {
      path
        ..moveTo(0, slant)
        ..lineTo(size.width, 0);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, slant);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_ItaliaTeamScoreClipper oldClipper) =>
      oldClipper.team != team;
}

class ItaliaTeamRoster extends StatelessWidget {
  const ItaliaTeamRoster({
    super.key,
    required this.team,
    required this.players,
    required this.largeText,
    required this.enabled,
    required this.score,
    required this.onAdd,
    this.avatar,
    this.nameStyle,
  });

  final ItaliaTeam team;
  final List<Player> players;
  final bool largeText;
  final bool enabled;
  final int score;
  final ValueChanged<String> onAdd;
  final Widget? avatar;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox(height: 92);
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / players.length;
        final stack = largeText && itemWidth < 150;
        final items = [
          for (var index = 0; index < players.length; index++)
            _ItaliaTeamRosterPlayer(
              team: team,
              player: players[index],
              enabled: enabled,
              score: score,
              onAdd: onAdd,
              avatar: avatar,
              nameStyle: nameStyle,
              actionKey: index == 0
                  ? ValueKey('score-add-team-${team.number}')
                  : ValueKey('score-add-team-${team.number}-player-$index'),
            ),
        ];
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                items[index],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final item in items) Expanded(child: item)],
        );
      },
    );
  }
}

class _ItaliaTeamRosterPlayer extends StatelessWidget {
  const _ItaliaTeamRosterPlayer({
    required this.team,
    required this.player,
    required this.enabled,
    required this.score,
    required this.onAdd,
    required this.actionKey,
    required this.avatar,
    required this.nameStyle,
  });

  final ItaliaTeam team;
  final Player player;
  final bool enabled;
  final int score;
  final ValueChanged<String> onAdd;
  final Key actionKey;
  final Widget? avatar;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar ?? _ItaliaFoosballPlayerBadge(team: team),
        const SizedBox(height: 4),
        Text(
          player.name,
          textAlign: TextAlign.center,
          style:
              nameStyle ??
              Italia90.body.copyWith(fontWeight: FontWeight.w700, height: 1.1),
        ),
        const SizedBox(height: 6),
        Semantics(
          key: actionKey,
          container: true,
          button: true,
          enabled: enabled,
          label:
              'Aggiungi un goal a ${player.name} per ${team.label.toUpperCase()}. '
              'Punteggio attuale $score.',
          onTap: enabled ? () => onAdd(player.id) : null,
          child: ExcludeSemantics(
            child: FilledButton(
              onPressed: enabled ? () => onAdd(player.id) : null,
              style: FilledButton.styleFrom(
                backgroundColor: Italia90.surface,
                foregroundColor: team.onNeutralSurface,
                disabledBackgroundColor: Italia90.subtle,
                disabledForegroundColor: Italia90.muted,
                minimumSize: const Size(48, 52),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: BorderSide(color: team.color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: Italia90.label.copyWith(
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
              child: const Text('+1 GOAL'),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ItaliaFoosballPlayerBadge extends StatelessWidget {
  const _ItaliaFoosballPlayerBadge({required this.team});

  final ItaliaTeam team;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: team.color,
      shape: BoxShape.circle,
      border: Border.all(color: Italia90.surface, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: RankingFoosballFigure(shirtColor: team.onColor),
    ),
  );
}

class ItaliaScoreboard extends StatelessWidget {
  const ItaliaScoreboard({
    super.key,
    required this.first,
    required this.second,
    this.showUndo = true,
  });
  final TeamScorePanel first;
  final TeamScorePanel second;
  final bool showUndo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(16) > 22;
      if (constraints.maxWidth < 340 || largeText) {
        return Column(
          children: [
            first,
            const SizedBox(height: 16),
            second,
            if (showUndo) ...[
              const SizedBox(height: 10),
              ItaliaSharedUndoAction(first: first, second: second),
            ],
          ],
        );
      }
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
          if (showUndo) ...[
            const SizedBox(height: 10),
            ItaliaSharedUndoAction(first: first, second: second),
          ],
        ],
      );
    },
  );
}

class ItaliaSharedUndoAction extends StatelessWidget {
  const ItaliaSharedUndoAction({
    super.key,
    required this.first,
    required this.second,
  });

  final TeamScorePanel first;
  final TeamScorePanel second;

  @override
  Widget build(BuildContext context) {
    final firstEnabled = first.enabled && first.score > 0;
    final secondEnabled = second.enabled && second.score > 0;
    final splitLabels = firstEnabled && secondEnabled;
    final teamControls = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _UndoHitTarget(
              key: ValueKey('score-undo-team-${first.team.number}'),
              team: first.team,
              enabled: firstEnabled,
              onPressed: first.onUndo,
              showTeamLabel: splitLabels,
            ),
          ),
          if (splitLabels)
            const SizedBox(width: 1, child: ColoredBox(color: Italia90.error)),
          Expanded(
            child: _UndoHitTarget(
              key: ValueKey('score-undo-team-${second.team.number}'),
              team: second.team,
              enabled: secondEnabled,
              onPressed: second.onUndo,
              showTeamLabel: splitLabels,
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Italia90.surface,
        border: Border.all(color: Italia90.error, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: firstEnabled != secondEnabled
            ? _UndoHitTarget(
                key: ValueKey(
                  'score-undo-team-${firstEnabled ? first.team.number : second.team.number}',
                ),
                team: firstEnabled ? first.team : second.team,
                enabled: true,
                onPressed: firstEnabled ? first.onUndo : second.onUndo,
                showTeamLabel: true,
              )
            : Stack(
                fit: StackFit.loose,
                children: [
                  if (!splitLabels)
                    const Center(
                      child: ExcludeSemantics(
                        child: Text('ANNULLA', style: Italia90.label),
                      ),
                    ),
                  teamControls,
                ],
              ),
      ),
    );
  }
}

class _UndoHitTarget extends StatelessWidget {
  const _UndoHitTarget({
    super.key,
    required this.team,
    required this.enabled,
    required this.onPressed,
    this.showTeamLabel = false,
  });

  final ItaliaTeam team;
  final bool enabled;
  final VoidCallback onPressed;
  final bool showTeamLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    enabled: enabled,
    label: 'Annulla ultimo goal di ${team.label.toUpperCase()}',
    onTap: enabled ? onPressed : null,
    child: ExcludeSemantics(
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: Colors.transparent,
          disabledForegroundColor: Colors.transparent,
          overlayColor: Colors.transparent,
          minimumSize: const Size(0, 64),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: showTeamLabel
            ? SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled ? team.container : Italia90.subtle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ANNULLA',
                            textAlign: TextAlign.center,
                            style: Italia90.label.copyWith(
                              color: enabled
                                  ? team.onNeutralSurface
                                  : Italia90.muted,
                              fontSize: 12,
                              height: 1.1,
                              letterSpacing: .8,
                            ),
                          ),
                          Text(
                            team.label.toUpperCase(),
                            softWrap: true,
                            textAlign: TextAlign.center,
                            style: Italia90.caption.copyWith(
                              color: enabled
                                  ? team.onNeutralSurface
                                  : Italia90.muted,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.expand(),
      ),
    ),
  );
}

/// Two related controls or panels stack before labels or team identities clip.
class ItaliaPair extends StatelessWidget {
  const ItaliaPair({super.key, required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );
}

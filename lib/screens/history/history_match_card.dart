part of '../history_screen.dart';

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.players,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final GameMatch match;
  final List<Player> players;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final names1 = match.team1
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final names2 = match.team2
        .map((id) => StatsService.playerName(players, id))
        .join(' / ');
    final mode = match.mode == MatchMode.oneVsOne ? '1v1' : '2v2';
    return Material(
      key: ValueKey('history-match-${match.id}'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.medium),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpace.small,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpace.micro),
                            Text(
                              DateFormat('HH:mm').format(match.playedAt),
                              style: AppType.utility.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (match.isRivalry)
                          const Text('Rivalità', style: AppType.utility),
                      ],
                    ),
                  ),
                  PopupMenuButton<_MatchAction>(
                    tooltip: 'Azioni partita',
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (action) =>
                        action == _MatchAction.edit ? onEdit() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _MatchAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Correggi'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _MatchAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Elimina'),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    mode,
                    style: AppType.utility.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.medium),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final widths = [
                    _scoreWidth(context, match.t1Score),
                    _scoreWidth(context, match.t2Score),
                  ];
                  final nameWidth =
                      (constraints.maxWidth - widths[0] - widths[1] - 40) / 2;
                  final stacked =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                      nameWidth < 64;
                  Widget team(bool first) => _HistoryTeamScore(
                    matchId: match.id,
                    first: first,
                    names: first ? names1 : names2,
                    score: first ? match.t1Score : match.t2Score,
                    isWinner: match.winningTeam == (first ? 1 : 2),
                    scoreWidth: widths[first ? 0 : 1],
                    stacked: stacked,
                  );
                  return stacked
                      ? Column(
                          key: ValueKey('history-stacked-${match.id}'),
                          children: [
                            team(true),
                            const SizedBox(height: AppSpace.medium),
                            team(false),
                          ],
                        )
                      : Row(
                          key: ValueKey('history-central-${match.id}'),
                          children: [
                            Expanded(child: team(true)),
                            const ExcludeSemantics(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text('–', style: AppType.section),
                              ),
                            ),
                            Expanded(child: team(false)),
                          ],
                        );
                },
              ),
            ),
            const SizedBox(height: AppSpace.small),
            const HistoryRibbonArtwork(HistoryRibbon.card, height: 28),
          ],
        ),
      ),
    );
  }
}

double _textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textScaler: MediaQuery.textScalerOf(context),
    textDirection: Directionality.of(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

double _scoreWidth(BuildContext context, int score) =>
    math.max(52, _textWidth(context, '$score', AppType.event) + 20);

class _HistoryTeamScore extends StatelessWidget {
  const _HistoryTeamScore({
    required this.matchId,
    required this.first,
    required this.names,
    required this.score,
    required this.isWinner,
    required this.scoreWidth,
    required this.stacked,
  });
  final String matchId;
  final bool first;
  final String names;
  final int score;
  final bool isWinner;
  final double scoreWidth;
  final bool stacked;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('history-team-$matchId-team-${first ? 1 : 2}'),
    container: true,
    label:
        'Squadra ${first ? 1 : 2}: $names, punteggio $score${isWinner ? ', vittoria' : ''}',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final alignLeft = first || stacked;
          final nameWidget = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignLeft
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                names,
                textAlign: alignLeft ? TextAlign.left : TextAlign.right,
                style: AppType.bodyStrong,
              ),
              if (isWinner)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpace.micro),
                  child: Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: AppColors.ink,
                  ),
                ),
            ],
          );
          final scoreWidget = Container(
            width: math.min(scoreWidth, constraints.maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: first ? AppColors.teamOne : AppColors.teamTwo,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Text(
              '$score',
              textAlign: TextAlign.center,
              softWrap: false,
              maxLines: 1,
              style: AppType.event.copyWith(
                color: first ? AppColors.onPrimary : AppColors.ink,
              ),
            ),
          );
          if (stacked) {
            final longestWord = names
                .split(RegExp(r'\s+'))
                .fold(
                  0.0,
                  (width, word) => math.max(
                    width,
                    _textWidth(context, word, AppType.bodyStrong),
                  ),
                );
            if (longestWord >
                constraints.maxWidth - scoreWidth - AppSpace.medium) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nameWidget,
                  const SizedBox(height: AppSpace.small),
                  scoreWidget,
                ],
              );
            }
          }
          return Row(
            children: first || stacked
                ? [
                    Expanded(child: nameWidget),
                    const SizedBox(width: AppSpace.small),
                    scoreWidget,
                  ]
                : [
                    scoreWidget,
                    const SizedBox(width: AppSpace.small),
                    Expanded(child: nameWidget),
                  ],
          );
        },
      ),
    ),
  );
}

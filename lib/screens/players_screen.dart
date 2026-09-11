import 'package:flutter/material.dart';
import '../widgets/design/brand_header.dart';
import '../widgets/design/south_africa_artwork.dart';
import '../navigation/app_navigation.dart';
import 'players/player_dialogs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/players/players_cubit.dart';
import '../cubits/players/players_state.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayersCubit, PlayersState>(
      listenWhen: (previous, current) =>
          current.feedback != null && current.feedback != previous.feedback,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(playersFeedbackText(state.feedback!))),
          );
      },
      builder: (context, state) {
        final active = state.active;
        final archived = state.archived;
        final players = [...active, ...archived];
        final presentCount = state.present.length;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isMutating
                ? null
                : () => showPlayerAddDialog(context),
            backgroundColor: state.isMutating
                ? AppColors.disabledContainer
                : AppColors.primary,
            foregroundColor: state.isMutating
                ? AppColors.disabledContent
                : AppColors.onPrimary,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('NUOVO'),
          ),
          body: SafeArea(
            bottom: false,
            child: RibbonBackdrop(
              child: CustomScrollView(
                key: const ValueKey('players-scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      summary: players.isEmpty
                          ? null
                          : _Summary(
                              presentCount: presentCount,
                              total: active.length,
                            ),
                    ),
                  ),
                  if (players.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 96),
                        child: _Empty(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      sliver: SliverList.builder(
                        itemCount: players.length + (archived.isEmpty ? 0 : 1),
                        itemBuilder: (_, index) {
                          if (archived.isNotEmpty && index == active.length) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: active.isEmpty ? 0 : AppSpace.section,
                                bottom: AppSpace.medium,
                              ),
                              child: Semantics(
                                header: true,
                                child: const Text(
                                  'ARCHIVIATI',
                                  style: AppType.section,
                                ),
                              ),
                            );
                          }
                          final i = index > active.length && archived.isNotEmpty
                              ? index - 1
                              : index;
                          final player = players[i];
                          return _PlayerRow(
                            key: ValueKey('player-row-${player.id}'),
                            first: i == 0 || i == active.length,
                            last:
                                i == active.length - 1 ||
                                i == players.length - 1,
                            player: player,
                            onToggle: state.isMutating || player.isArchived
                                ? null
                                : () => context
                                      .read<PlayersCubit>()
                                      .togglePresent(player),
                            onRename: state.isMutating
                                ? null
                                : () => showPlayerRenameDialog(context, player),
                            onArchive: state.isMutating || player.isArchived
                                ? null
                                : () =>
                                      showPlayerArchiveDialog(context, player),
                            onReactivate: state.isMutating || !player.isArchived
                                ? null
                                : () => context
                                      .read<PlayersCubit>()
                                      .reactivatePlayer(player),
                            onOpenProfile: () =>
                                openPlayerProfile(context, player.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.summary});
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < 650 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Column(
      children: [
        SizedBox(
          height: compact ? 12 : 36,
          width: double.infinity,
          child: const SouthAfricaArtwork(
            mark: ArtworkMark.headerRibbon,
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Semantics(
            header: true,
            child: const Text(
              'GIOCATORI',
              style: AppType.screen,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (summary != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: summary!,
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.presentCount, required this.total});

  final int presentCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    const minimumPlayers = 2;
    final ready = presentCount >= minimumPlayers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _Pill(
            text: '$presentCount/$total presenti',
            color: AppColors.primary,
          ),
          _Pill(
            text: ready
                ? 'Pronti a giocare'
                : 'Servono ${minimumPlayers - presentCount} per giocare',
            color: ready ? AppColors.success : AppColors.ink,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    super.key,
    required this.player,
    required this.onToggle,
    required this.onRename,
    required this.onArchive,
    required this.onReactivate,
    required this.onOpenProfile,
    required this.first,
    required this.last,
  });
  final Player player;
  final VoidCallback? onToggle, onRename, onArchive, onReactivate;
  final VoidCallback onOpenProfile;
  final bool first, last;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(first ? AppRadius.panel : 0),
        bottom: Radius.circular(last ? AppRadius.panel : 0),
      ),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _PlayerRowLayout(
            profile: Semantics(
              button: true,
              label: 'Profilo di ${player.name}',
              value: player.isArchived
                  ? 'Archiviato'
                  : player.isPresent
                  ? 'In ufficio'
                  : 'Assente',
              onTap: onOpenProfile,
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        PlayerAvatar(name: player.name, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(player.name, style: AppType.player),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: AppMotion.duration(
                                  context,
                                  AppMotion.selection,
                                ),
                                child: _PresenceBadge(
                                  key: ValueKey(
                                    '${player.isPresent}-${player.isArchived}',
                                  ),
                                  isPresent: player.isPresent,
                                  isArchived: player.isArchived,
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
            controls: [
              if (!player.isArchived)
                Semantics(
                  key: ValueKey('player-presence-${player.id}'),
                  container: true,
                  label: 'Presenza di ${player.name}',
                  toggled: player.isPresent,
                  enabled: onToggle != null,
                  onTap: onToggle,
                  child: ExcludeSemantics(
                    child: Switch.adaptive(
                      value: player.isPresent,
                      onChanged: onToggle == null ? null : (_) => onToggle!(),
                    ),
                  ),
                ),
              PopupMenuButton<_PlayerAction>(
                key: ValueKey('player-actions-${player.id}'),
                tooltip: 'Azioni giocatore: ${player.name}',
                onSelected: (action) {
                  switch (action) {
                    case _PlayerAction.rename:
                      onRename?.call();
                    case _PlayerAction.profile:
                      onOpenProfile();
                    case _PlayerAction.archive:
                      onArchive?.call();
                    case _PlayerAction.reactivate:
                      onReactivate?.call();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _PlayerAction.profile,
                    child: ListTile(
                      leading: Icon(Icons.person_search),
                      title: Text('Profilo'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _PlayerAction.rename,
                    enabled: onRename != null,
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifica nome'),
                    ),
                  ),
                  if (player.isArchived)
                    PopupMenuItem(
                      value: _PlayerAction.reactivate,
                      enabled: onReactivate != null,
                      child: const ListTile(
                        leading: Icon(Icons.unarchive),
                        title: Text('Riattiva'),
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: _PlayerAction.archive,
                      enabled: onArchive != null,
                      child: const ListTile(
                        leading: Icon(Icons.archive_outlined),
                        title: Text('Archivia'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, indent: 12, endIndent: 12),
      ],
    ),
  );
}

class _PlayerRowLayout extends StatelessWidget {
  const _PlayerRowLayout({required this.profile, required this.controls});
  final Widget profile;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          profile,
          Row(mainAxisAlignment: MainAxisAlignment.end, children: controls),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: profile),
        ...controls,
      ],
    );
  }
}

enum _PlayerAction { profile, rename, archive, reactivate }

class _PresenceBadge extends StatelessWidget {
  const _PresenceBadge({
    super.key,
    required this.isPresent,
    required this.isArchived,
  });

  final bool isPresent;
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    final color = isPresent && !isArchived
        ? AppColors.success
        : AppColors.textSecondary;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isArchived
                ? 'Archiviato'
                : isPresent
                ? 'In ufficio'
                : 'Assente',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color),
    ),
    child: Text(text, style: AppType.utility.copyWith(color: color)),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => const Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text('Nessun giocatore', style: AppType.section),
            SizedBox(height: 6),
            Text(
              'Aggiungi il primo player con il pulsante in basso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}

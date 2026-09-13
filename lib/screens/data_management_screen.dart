import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/data_management/data_management_cubit.dart';
import '../repositories/data_management_repository.dart';
import '../services/backup_file_picker.dart';
import '../services/data_file_share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/design/pass_page.dart';
import '../widgets/design/pass_ticket.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        DataManagementCubit(context.read<DataManagementRepository>()),
    child: const _DataView(),
  );
}

class _DataView extends StatelessWidget {
  const _DataView();
  Future<void> _effect(BuildContext context, DataEffect effect) async {
    final cubit = context.read<DataManagementCubit>();
    switch (effect.kind) {
      case DataEffectKind.pick:
        try {
          final source = await context.read<BackupFilePicker>().pickJson();
          cubit.picked(effect.id, source);
        } on Object {
          cubit.picked(effect.id, null, failed: true);
        }
      case DataEffectKind.share:
        final file = effect.export!;
        final box = context.findRenderObject() as RenderBox?;
        try {
          await context.read<DataFileShareService>().share(
            content: file.content,
            fileName: file.fileName,
            mimeType: file.mimeType,
            subject: file.subject,
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          );
          cubit.shareFinished(effect.id, succeeded: true);
        } on Object {
          cubit.shareFinished(effect.id, succeeded: false);
        }
      case DataEffectKind.confirm:
        final summary = effect.summary!;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare il backup?'),
            content: Text(
              'Il backup contiene ${summary.players} giocatori e '
              '${summary.matches} partite. I dati locali verranno sostituiti.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: AppTheme.primaryButton(
                  background: AppColors.error,
                  pressed: AppColors.error,
                ),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        );
        await cubit.confirmed(effect.id, confirmed == true);
      case DataEffectKind.message:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(effect.message!)));
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DataManagementCubit, DataManagementState>(
        listenWhen: (previous, current) =>
            current.effect != null && previous.effect?.id != current.effect!.id,
        listener: (context, state) => _effect(context, state.effect!),
        builder: (context, state) {
          final cubit = context.read<DataManagementCubit>();
          final enabled = !state.busy && !state.refreshRequired;
          Widget ticket(
            String key,
            String title,
            String subtitle,
            IconData icon,
            IconData trailing,
            String format,
            VoidCallback action,
          ) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: PassTicket(
              key: ValueKey(key),
              title: title,
              subtitle: subtitle,
              icon: icon,
              trailing: trailing,
              format: format,
              onTap: enabled ? action : null,
            ),
          );
          return PopScope(
            canPop: !state.busy,
            child: PassPage(
              title: 'DATI',
              onBack: () => Navigator.of(context).maybePop(),
              children: [
                const Text('ESPORTA', style: AppType.section),
                const SizedBox(height: 12),
                ticket(
                  'export-json',
                  'Crea backup',
                  'Giocatori e partite da ripristinare',
                  Icons.note_outlined,
                  Icons.ios_share,
                  'JSON',
                  () => cubit.export(csv: false),
                ),
                ticket(
                  'export-csv',
                  'Esporta risultati',
                  'Per un foglio di calcolo',
                  Icons.table_chart_outlined,
                  Icons.ios_share,
                  'CSV',
                  () => cubit.export(csv: true),
                ),
                const SizedBox(height: 18),
                const Text('RIPRISTINA', style: AppType.section),
                const SizedBox(height: 16),
                ticket(
                  'restore-json',
                  'Ripristina backup',
                  'Sostituisce i dati dopo la conferma',
                  Icons.restore,
                  Icons.file_open_outlined,
                  'JSON',
                  cubit.restore,
                ),
                if (state.busy)
                  Semantics(
                    liveRegion: true,
                    label: 'Operazione in corso',
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                if (state.refreshRequired && !state.busy)
                  TextButton(
                    onPressed: cubit.retryRefresh,
                    child: const Text('Riprova ad aggiornare'),
                  ),
              ],
            ),
          );
        },
      );
}

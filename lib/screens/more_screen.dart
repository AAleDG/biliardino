import 'package:flutter/material.dart';
import '../navigation/app_navigation.dart';
import '../theme/app_theme.dart';
import '../widgets/design/pass_page.dart';
import '../widgets/design/pass_ticket.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => PassPage(
    title: 'ALTRO',
    fixedFrame: true,
    children: [
      const Text('ARCHIVIO E DATI', style: AppType.section),
      const SizedBox(height: 12),
      PassTicket(
        key: const ValueKey('more-history'),
        icon: Icons.history,
        title: 'STORICO',
        subtitle: 'Consulta e correggi le partite',
        trailing: Icons.chevron_right,
        onTap: () => openHistory(context),
      ),
      const SizedBox(height: 14),
      PassTicket(
        key: const ValueKey('more-data'),
        icon: Icons.storage_outlined,
        title: 'DATI',
        subtitle: 'Backup, esportazione e ripristino',
        trailing: Icons.chevron_right,
        onTap: () => openDataManagement(context),
      ),
      const SizedBox(height: 24),
      const Text('PERSONALIZZA', style: AppType.section),
      const SizedBox(height: 12),
      PassTicket(
        key: const ValueKey('more-appearance'),
        icon: Icons.palette_outlined,
        title: 'ASPETTO',
        subtitle: 'Scegli lo stile dell’app',
        trailing: Icons.chevron_right,
        onTap: () => openAppearance(context),
      ),
      const SizedBox(height: 14),
      PassTicket(
        key: const ValueKey('more-feedback'),
        icon: Icons.chat_bubble_outline,
        title: 'INVIA FEEDBACK',
        subtitle: 'Hai un’idea o qualcosa non funziona?',
        trailing: Icons.chevron_right,
        onTap: () => openFeedback(context),
      ),
      const SizedBox(height: 14),
    ],
  );
}

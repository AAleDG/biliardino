import 'package:flutter/material.dart';

import '../navigation/app_navigation.dart';
import '../theme/app_theme.dart';
import '../widgets/design/brand_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: brandAppBar(context, title: 'ALTRO'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ARCHIVIO E DATI', style: AppType.section),
        const SizedBox(height: 8),
        _MoreDestination(
          key: const ValueKey('more-history'),
          icon: Icons.history,
          title: 'Storico',
          subtitle: 'Consulta, filtra e correggi le partite registrate',
          onTap: () => openHistory(context),
        ),
        _MoreDestination(
          key: const ValueKey('more-data'),
          icon: Icons.storage_outlined,
          title: 'Dati',
          subtitle: 'Esporta o ripristina giocatori e partite',
          onTap: () => openDataManagement(context),
        ),
      ],
    ),
  );
}

class _MoreDestination extends StatelessWidget {
  const _MoreDestination({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: 12,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

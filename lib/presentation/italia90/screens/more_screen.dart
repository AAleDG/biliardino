import 'package:flutter/material.dart';

import '../../../navigation/app_navigation.dart';
import '../theme/italia90_tokens.dart';
import '../widgets/italia90_components.dart';
import '../widgets/italia90_page.dart';

/// Secondary navigation destination shared by the persistent shell.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => ItaliaPage(
    title: 'ALTRO',
    mastheadKey: const ValueKey('more-masthead'),
    footballKey: const ValueKey('more-brand-football'),
    child: ListView(
      key: const ValueKey('more-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const Text('ARCHIVIO E DATI', style: Italia90.heading),
        const SizedBox(height: 12),
        ItaliaDataActionSlip(
          key: const ValueKey('more-history'),
          icon: Icons.history,
          title: 'Storico',
          subtitle: 'Consulta e correggi le partite',
          onPressed: () => openHistory(context),
        ),
        const SizedBox(height: 14),
        ItaliaDataActionSlip(
          key: const ValueKey('more-data'),
          icon: Icons.storage_outlined,
          title: 'Dati',
          subtitle: 'Backup, esportazione e ripristino',
          onPressed: () => openDataManagement(context),
        ),
      ],
    ),
  );
}

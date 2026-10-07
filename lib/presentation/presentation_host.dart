import 'package:flutter/material.dart';
import '../models/app_style.dart';
import 'app_presentation.dart';

/// Keeps visited screen owners alive beneath the one application Navigator.
/// Each tree retains its own theme; only the visible tree consumes UI effects.
class PresentationHost extends StatefulWidget {
  const PresentationHost({super.key});
  @override
  State<PresentationHost> createState() => _PresentationHostState();
}

class _PresentationHostState extends State<PresentationHost> {
  final Map<AppStyle, AppPresentation> _visited = {};
  @override
  Widget build(BuildContext context) {
    final current = AppPresentationScope.of(context);
    _visited[current.style] = current;
    final entries = _visited.entries.toList(growable: false);
    return IndexedStack(
      index: entries.indexWhere((entry) => entry.key == current.style),
      children: [
        for (final entry in entries)
          TickerMode(
            key: ValueKey(entry.key),
            enabled: entry.key == current.style,
            child: AppPresentationScope(
              presentation: entry.value,
              active: entry.key == current.style,
              child: Theme(
                data: entry.value.theme,
                child: entry.value.page(AppPage.home),
              ),
            ),
          ),
      ],
    );
  }
}

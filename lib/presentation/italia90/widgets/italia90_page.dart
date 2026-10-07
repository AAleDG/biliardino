import 'package:flutter/material.dart';

import '../theme/italia90_tokens.dart';
import 'italia90_components.dart';
import 'italia_graphic_backdrop.dart';

/// Shared working-screen chrome; screen owners retain navigation and actions.
class ItaliaPage extends StatelessWidget {
  const ItaliaPage({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.showBack = false,
    this.actions = const [],
    this.titleStyle,
    this.titleAccessory,
    this.mastheadKey,
    this.footballKey,
  });
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;
  final TextStyle? titleStyle;
  final Widget? titleAccessory;
  final Key? mastheadKey;
  final Key? footballKey;

  @override
  Widget build(BuildContext context) {
    final shortHeight = MediaQuery.sizeOf(context).height < 500;
    return Scaffold(
      backgroundColor: Italia90.surface,
      body: ItaliaGraphicBackdrop(
        variant: ItaliaBackdropVariant.working,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, shortHeight ? 0 : 10, 20, 0),
                child: ItaliaCompactMasthead(
                  semanticsKey: mastheadKey,
                  footballKey: footballKey,
                  leading: onBack == null && !showBack
                      ? null
                      : IconButton(
                          key: const ValueKey('italia-page-back'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                ),
              ),
              if (actions.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Wrap(spacing: 4, children: actions),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  shortHeight ? 4 : 12,
                  20,
                  shortHeight ? 4 : 8,
                ),
                child: titleAccessory == null
                    ? _PageTitle(title: title, style: titleStyle)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _PageTitle(title: title, style: titleStyle),
                          ),
                          const SizedBox(width: 8),
                          titleAccessory!,
                        ],
                      ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: style == null
        ? Text(title, style: Italia90.pageTitle)
        : FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(title, style: style),
          ),
  );
}

class ItaliaPanel extends StatelessWidget {
  const ItaliaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Italia90.panel,
    borderRadius: BorderRadius.circular(Italia90.panelRadius),
    child: Padding(padding: padding, child: child),
  );
}

class ItaliaEmptyState extends StatelessWidget {
  const ItaliaEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ItaliaPanel(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Italia90.primary),
            const SizedBox(height: 16),
            Text(title, style: Italia90.title, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              description,
              style: Italia90.body.copyWith(color: Italia90.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

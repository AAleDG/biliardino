import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/app_style/app_style_cubit.dart';
import '../models/app_style.dart';
import '../presentation/presentation_operations.dart';
import '../presentation/italia90/theme/italia90_tokens.dart';
import '../presentation/italia90/widgets/italia90_artwork.dart';
import '../presentation/italia90/widgets/italia90_page.dart';
import '../theme/app_theme.dart';
import '../widgets/design/pass_artwork.dart';
import '../widgets/design/pass_page.dart';
import '../widgets/design/foosball_scene.dart';
import 'dashboard_screen.dart' show homeHeroAssetPath;

/// Stable route owner: changing the presentation only changes the visual frame.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});
  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  String? _error;
  Future<void> _select(AppStyle style) async {
    final operations = PresentationOperations.of(context);
    final cubit = context.read<AppStyleCubit>();
    if (cubit.pendingSelection.value != null ||
        operations.blocksSelection ||
        style == cubit.state) {
      return;
    }
    setState(() => _error = null);
    try {
      await cubit.select(style);
    } on Object {
      if (mounted) {
        setState(() => _error = 'Impossibile cambiare stile. Riprova.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppStyleCubit, AppStyle>(
    builder: (context, current) => ListenableBuilder(
      listenable: context.read<AppStyleCubit>().pendingSelection,
      builder: (context, _) {
        final pending = context.read<AppStyleCubit>().pendingSelection.value;
        final blocked = PresentationOperations.of(context).blocksSelection;
        final italia = current == AppStyle.italia90;
        final active = italia ? Italia90.primary : AppColors.primary;
        final body = italia ? Italia90.body : AppType.body;
        final label = italia ? Italia90.heading : AppType.section;
        final compact =
            MediaQuery.sizeOf(context).height < 650 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return _AppearanceFrame(
          italia: italia,
          compact: compact,
          child: ListView(
            key: const ValueKey('appearance-scroll'),
            padding: EdgeInsets.fromLTRB(
              italia ? 20 : 16,
              12,
              italia ? 20 : 16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Text(
                'Scegli lo stile dell’app.',
                style: body.copyWith(fontSize: 20),
              ),
              if (blocked)
                Text(
                  'Attendi la conclusione dell’operazione sui dati.',
                  key: const ValueKey('appearance-data-busy'),
                  style: body,
                ),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    key: const ValueKey('appearance-error'),
                    style: body.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              for (final style in AppStyle.values) ...[
                _StyleCard(
                  style: style,
                  selected: current == style,
                  pending: pending == style,
                  activeColor: active,
                  labelStyle: label.copyWith(fontSize: 24),
                  bodyStyle: body,
                  compact: compact,
                  onTap: pending != null || blocked
                      ? null
                      : () => _select(style),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _AppearanceFrame extends StatelessWidget {
  const _AppearanceFrame({
    required this.italia,
    required this.compact,
    required this.child,
  });
  final bool italia, compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();
    if (italia) {
      // Keep the fixed brand lockup legible; scrolling choices retain the user's
      // full text scale through their original media configuration.
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1,
        child: ItaliaPage(
          title: 'ASPETTO',
          onBack: back,
          child: MediaQuery(data: MediaQuery.of(context), child: child),
        ),
      );
    }
    return FoosballScene(
      builder: (context, scene) => Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final footerHeight = compact
                ? 32.0
                : constraints.maxWidth * 149 / 463;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (!compact)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: AspectRatio(
                          aspectRatio: 466 / 163,
                          child: CustomPaint(
                            painter: PassRibbons(PassRibbonKind.header),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: footerHeight,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ClipRect(
                        key: const ValueKey('appearance-fixed-footer'),
                        child: OverflowBox(
                          alignment: Alignment.bottomCenter,
                          minHeight: constraints.maxWidth * 149 / 463,
                          maxHeight: constraints.maxWidth * 149 / 463,
                          child: CustomPaint(
                            painter: PassRibbons(
                              PassRibbonKind.footer,
                              scene: scene,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      PassPageHeader(
                        title: 'ASPETTO',
                        compact: compact,
                        onBack: back,
                        showArtwork: false,
                        fitTitle: true,
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: footerHeight),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.selected,
    required this.pending,
    required this.activeColor,
    required this.labelStyle,
    required this.bodyStyle,
    required this.compact,
    this.onTap,
  });
  final AppStyle style;
  final bool selected, pending, compact;
  final Color activeColor;
  final TextStyle labelStyle, bodyStyle;
  final VoidCallback? onTap;
  String get label =>
      style == AppStyle.southAfrica2010 ? 'South Africa 2010' : 'Italia ’90';
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    label:
        '$label${selected ? ', In uso' : ''}${pending ? ', Cambio in corso' : ''}',
    child: ExcludeSemantics(
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? activeColor : AppColors.divider,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('appearance-${style.storageValue}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: compact ? 104 : 158,
                  child: _StylePreview(style: style),
                ),
                const SizedBox(height: 10),
                if (compact) Text(label, style: labelStyle),
                if (compact) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!compact)
                      Expanded(child: Text(label, style: labelStyle)),
                    const SizedBox(width: 8),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              'In uso',
                              style: bodyStyle.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (pending)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: activeColor,
                        ),
                      )
                    else
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? activeColor : Colors.transparent,
                          border: selected
                              ? null
                              : Border.all(
                                  color: AppColors.outline,
                                  width: 1.5,
                                ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Decorative art only; no app shells, controllers or repositories in previews.
class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.style});
  final AppStyle style;
  @override
  Widget build(BuildContext context) => style == AppStyle.southAfrica2010
      ? Image.asset(homeHeroAssetPath, fit: BoxFit.contain)
      : const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ItaliaFootball(size: 100),
                SizedBox(width: 24),
                ItaliaCiao(height: 158),
              ],
            ),
          ),
        );
}

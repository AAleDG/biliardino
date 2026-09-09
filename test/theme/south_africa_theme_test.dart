import 'package:biliardino/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Semantic foreground pairs meet normal-text contrast', () {
    final pairs = <(Color, Color)>[
      (AppColors.ink, AppColors.background),
      (AppColors.textSecondary, AppColors.background),
      (AppColors.onPrimary, AppColors.primary),
      (AppColors.onPrimary, AppColors.primaryPressed),
      (AppColors.onPrimary, AppColors.homeAction),
      (AppColors.onPrimary, AppColors.homeActionPressed),
      (AppColors.onPrimary, AppColors.success),
      (AppColors.successPressed, AppColors.successContainer),
      (AppColors.onPrimary, AppColors.error),
      (AppColors.ink, AppColors.teamTwo),
      (AppColors.disabledContent, AppColors.disabledContainer),
      (AppColors.teamOne, AppColors.teamOneContainer),
      (AppColors.ink, AppColors.teamTwoContainer),
    ];
    for (final (foreground, background) in pairs) {
      final a = foreground.computeLuminance(),
          b = background.computeLuminance();
      final contrast =
          (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
      expect(
        contrast,
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on $background',
      );
    }
  });

  test('Theme gives controls visible focus and legible disabled states', () {
    final theme = AppTheme.southAfrica();
    expect(theme.brightness, Brightness.light);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Barlow');
    expect(theme.textTheme.headlineMedium!.fontFamily, 'Barlow Condensed');
    final style = theme.elevatedButtonTheme.style!;
    expect(
      style.side!.resolve({WidgetState.focused})!.width,
      greaterThanOrEqualTo(2),
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.disabled}),
      AppColors.disabledContainer,
    );
    expect(
      style.foregroundColor!.resolve({WidgetState.disabled}),
      AppColors.disabledContent,
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.pressed}),
      AppColors.primaryPressed,
    );
    expect(style.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(48));
  });
}

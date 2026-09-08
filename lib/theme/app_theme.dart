import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design_tokens.dart';
export 'design_tokens.dart';
export 'motion_policy.dart';

abstract final class AppTheme {
  /// Shared busy/disabled/pressed/focus styling; callers supply semantic colors.
  static ButtonStyle primaryButton({
    Color background = AppColors.primary,
    Color foreground = AppColors.onPrimary,
    Color pressed = AppColors.primaryPressed,
  }) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size(AppSpace.touch, AppSpace.action),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevation: const WidgetStatePropertyAll(0),
    textStyle: const WidgetStatePropertyAll(AppType.action),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.disabledContainer
          : states.contains(WidgetState.pressed)
          ? pressed
          : background,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.disabledContent
          : foreground,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.focused)
          ? const BorderSide(color: AppColors.ink, width: 3)
          : BorderSide.none,
    ),
  );

  static ThemeData southAfrica() {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.success,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.disabledContainer,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      surfaceTint: Colors.transparent,
    );
    final secondary =
        OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.disabledContent,
          disabledBackgroundColor: AppColors.disabledContainer,
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: AppColors.outline),
          textStyle: AppType.utility,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.focused)
                  ? AppColors.primary
                  : AppColors.outline,
              width: s.contains(WidgetState.focused) ? 3 : 1,
            ),
          ),
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    final chipLabel = AppType.utility.copyWith(
      color: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.disabledContent
            : states.contains(WidgetState.selected)
            ? AppColors.onPrimary
            : AppColors.ink,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: AppType.bodyFamily,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: const TextTheme(
        displayLarge: AppType.score,
        displayMedium: AppType.event,
        headlineLarge: AppType.screen,
        headlineMedium: AppType.screen,
        headlineSmall: AppType.section,
        titleLarge: AppType.player,
        titleMedium: AppType.bodyStrong,
        titleSmall: AppType.utility,
        bodyLarge: AppType.body,
        bodyMedium: AppType.body,
        bodySmall: AppType.caption,
        labelLarge: AppType.action,
        labelMedium: AppType.utility,
        labelSmall: AppType.navigation,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpace.page,
        titleTextStyle: AppType.screen.copyWith(color: AppColors.ink),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppType.navigation.copyWith(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.ink,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.panel),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton()),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondary),
      textButtonTheme: TextButtonThemeData(
        style: secondary.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: AppType.action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: AppType.body.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppType.utility.copyWith(color: AppColors.primary),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        errorMaxLines: 4,
        contentPadding: const EdgeInsets.all(AppSpace.medium),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.disabledContainer
              : states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface,
        ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.disabledContainer,
        labelStyle: chipLabel,
        secondaryLabelStyle: chipLabel,
        checkmarkColor: AppColors.onPrimary,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: AppType.section.copyWith(color: AppColors.ink),
        contentTextStyle: AppType.body.copyWith(color: AppColors.ink),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppType.body.copyWith(color: AppColors.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.ink,
        titleTextStyle: AppType.bodyStrong,
        subtitleTextStyle: AppType.caption,
        minVerticalPadding: 12,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.disabledContent
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? AppColors.disabledContainer
              : s.contains(WidgetState.selected)
              ? AppColors.success
              : AppColors.outline,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.ink,
        labelStyle: AppType.bodyStrong,
        unselectedLabelStyle: AppType.bodyStrong,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}

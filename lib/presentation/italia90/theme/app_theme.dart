import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'design_tokens.dart';
export 'motion_policy.dart';
import 'design_tokens.dart';
import 'italia90_tokens.dart';

class NttColors {
  NttColors._();

  static const Color primary = Color(0xFF0033A0);
  static const Color primaryDeep = Color(0xFF001A66);
  static const Color accent = Color(0xFF00B5E2);
  static const Color accentSoft = Color(0xFF66D7F0);

  static const Color team1 = Color(0xFF00B5E2);
  static const Color team2 = Color(0xFFFF6B35);

  static const Color success = Color(0xFF7CFC00);
  static const Color warning = Color(0xFFFFC857);

  static const Color surfaceDark = Color(0xFF0A1424);
  static const Color surfaceMid = Color(0xFF142340);
  static const Color surfaceHigh = Color(0xFF1B2D52);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFD0D9E6);
  static const Color textFaint = Color(0xFFAAB8CB);
}

class AppTheme {
  AppTheme._();

  static ButtonStyle primaryButton({
    Color background = AppColors.primary,
    Color foreground = AppColors.onPrimary,
    Color pressed = AppColors.primaryPressed,
  }) {
    return ButtonStyle(
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
  }

  static ThemeData italia90() {
    const scheme = ColorScheme.light(
      primary: Italia90.primary,
      onPrimary: Colors.white,
      primaryContainer: Italia90.brickContainer,
      onPrimaryContainer: Italia90.ink,
      secondary: Italia90.green,
      onSecondary: Colors.white,
      secondaryContainer: Italia90.subtle,
      onSecondaryContainer: Italia90.ink,
      tertiary: Italia90.teamTwo,
      onTertiary: Italia90.ink,
      surface: Italia90.surface,
      onSurface: Italia90.ink,
      surfaceContainerHighest: Italia90.subtle,
      onSurfaceVariant: Italia90.muted,
      outline: Italia90.outline,
      outlineVariant: Italia90.subtle,
      error: Italia90.error,
      onError: Colors.white,
      scrim: Italia90.scrim,
      surfaceTint: Colors.transparent,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Italia90.controlRadius),
    );
    final primaryButton = FilledButton.styleFrom(
      backgroundColor: Italia90.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Italia90.subtle,
      disabledForegroundColor: Italia90.muted,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: Italia90.label,
      shape: shape,
    );
    final secondaryButton = OutlinedButton.styleFrom(
      backgroundColor: Italia90.surface,
      disabledBackgroundColor: Italia90.subtle,
      foregroundColor: Italia90.primary,
      disabledForegroundColor: Italia90.muted,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      side: const BorderSide(color: Italia90.outline),
      textStyle: Italia90.label,
      shape: shape,
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Italia90.controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Italia90.surface,
      canvasColor: Italia90.surface,
      disabledColor: Italia90.muted,
      fontFamily: 'Italia Barlow',
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: TextTheme(
        displayLarge: Italia90.display,
        displayMedium: Italia90.display,
        displaySmall: Italia90.display,
        headlineLarge: Italia90.display,
        headlineMedium: Italia90.heading,
        headlineSmall: Italia90.heading,
        titleLarge: Italia90.title,
        titleMedium: Italia90.body.copyWith(fontWeight: FontWeight.w700),
        titleSmall: Italia90.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: Italia90.body,
        bodyMedium: Italia90.body,
        bodySmall: Italia90.body.copyWith(fontSize: 14),
        labelLarge: Italia90.label,
        labelMedium: Italia90.label.copyWith(fontSize: 14),
        labelSmall: Italia90.label.copyWith(fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Italia90.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Italia90.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: Italia90.heading,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButton.copyWith(
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Italia90.primary,
          disabledForegroundColor: Italia90.muted,
          minimumSize: const Size(48, 48),
          textStyle: Italia90.label,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: Italia90.ink,
          disabledForegroundColor: Italia90.muted,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Italia90.primary,
        foregroundColor: Colors.white,
        extendedTextStyle: Italia90.label,
        elevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: const WidgetStatePropertyAll(Italia90.label),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? Italia90.subtle
                : states.contains(WidgetState.selected)
                ? Italia90.primary
                : Italia90.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? Italia90.muted
                : states.contains(WidgetState.selected)
                ? Colors.white
                : Italia90.ink,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: Italia90.outline),
          ),
          shape: WidgetStatePropertyAll(shape),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Italia90.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Italia90.brickContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => Italia90.label.copyWith(
            fontSize: 12,
            letterSpacing: 0,
            color: states.contains(WidgetState.selected)
                ? Italia90.primary
                : Italia90.ink,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? Italia90.primary
                : Italia90.ink,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Italia90.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Italia90.panelRadius),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Italia90.subtle,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Italia90.surface,
        labelStyle: Italia90.body.copyWith(color: Italia90.muted),
        floatingLabelStyle: Italia90.body.copyWith(color: Italia90.primary),
        contentPadding: const EdgeInsets.all(16),
        border: border(Italia90.outline),
        enabledBorder: border(Italia90.outline),
        focusedBorder: border(Italia90.primary, 2),
        errorBorder: border(Italia90.error),
        focusedErrorBorder: border(Italia90.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Italia90.surface,
        selectedColor: Italia90.brickContainer,
        disabledColor: Italia90.subtle,
        checkmarkColor: Italia90.primary,
        labelStyle: Italia90.body,
        side: const BorderSide(color: Italia90.outline),
        shape: shape,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? Italia90.muted
              : states.contains(WidgetState.selected)
              ? Colors.white
              : Italia90.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? Italia90.subtle
              : states.contains(WidgetState.selected)
              ? Italia90.success
              : Italia90.surface,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Italia90.outline),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Italia90.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: Italia90.heading,
        contentTextStyle: Italia90.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Italia90.sheetRadius),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Italia90.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Italia90.sheetRadius),
          ),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Italia90.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: Italia90.body,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Italia90.ink,
        contentTextStyle: Italia90.body.copyWith(color: Colors.white),
        actionTextColor: Colors.white,
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Italia90.ink,
        iconColor: Italia90.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Italia90.primary,
      ),
    );
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: NttColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: NttColors.accent,
          onPrimary: NttColors.surfaceDark,
          secondary: NttColors.primary,
          onSecondary: NttColors.textPrimary,
          surface: NttColors.surfaceMid,
          onSurface: NttColors.textPrimary,
          surfaceContainerHighest: NttColors.surfaceHigh,
          error: NttColors.team2,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: NttColors.surfaceDark,
      canvasColor: NttColors.surfaceDark,
      fontFamily: null,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
        ),
        headlineMedium: TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
        titleLarge: TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        titleMedium: TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        bodyLarge: TextStyle(color: NttColors.textPrimary),
        bodyMedium: TextStyle(color: NttColors.textMuted),
        labelLarge: TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: NttColors.textPrimary),
        titleTextStyle: TextStyle(
          color: NttColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NttColors.surfaceMid,
        indicatorColor: NttColors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? NttColors.accent : NttColors.textMuted,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.6,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? NttColors.accent : NttColors.textMuted,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: NttColors.surfaceMid,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 24,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NttColors.accent,
          foregroundColor: NttColors.surfaceDark,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NttColors.accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NttColors.accent,
        foregroundColor: NttColors.surfaceDark,
        elevation: 4,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NttColors.surfaceHigh,
        labelStyle: const TextStyle(color: NttColors.textMuted),
        floatingLabelStyle: const TextStyle(color: NttColors.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NttColors.accent, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: NttColors.surfaceHigh,
        selectedColor: NttColors.accent,
        labelStyle: const TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: NttColors.surfaceDark,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NttColors.surfaceMid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(
          color: NttColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
        contentTextStyle: const TextStyle(color: NttColors.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NttColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: NttColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: NttColors.accent,
        textColor: NttColors.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? NttColors.accent
              : NttColors.textFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? NttColors.accent.withValues(alpha: 0.4)
              : NttColors.surfaceHigh,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NttColors.accent,
      ),
    );
  }
}

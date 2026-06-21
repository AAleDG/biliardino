import 'package:flutter/material.dart';

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
  static const Color textMuted = Color(0xFFB0BCC9);
  static const Color textFaint = Color(0xFF7A8699);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
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
        indicatorColor: NttColors.accent.withOpacity(0.18),
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
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: NttColors.surfaceMid,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: NttColors.accent,
        textColor: NttColors.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return NttColors.accent;
          return NttColors.textFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NttColors.accent.withOpacity(0.4);
          }
          return NttColors.surfaceHigh;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NttColors.accent,
      ),
    );
  }
}

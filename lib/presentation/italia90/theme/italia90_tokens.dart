import 'package:flutter/material.dart';

/// Typed implementation of the approved DESIGN.md baseline.
abstract final class Italia90 {
  static const primary = Color(0xFFA83A2D);

  /// Petrol team accent from the approved concept 4 direction.
  static const petrol = Color(0xFF17656B);
  static const teamOne = petrol;

  /// Neutral identity color for players outside an explicit team or rank.
  static const avatarNeutral = primary;
  static const green = Color(0xFF00834D);

  /// Muted amaranto accent used instead of the saturated fire-red accent.
  static const red = Color(0xFFB94A3A);
  static const surface = Color(0xFFFFFCF5);
  static const panel = Colors.white;
  static const ink = Colors.black;
  static const muted = Color(0xFF555A60);
  static const subtle = Color(0xFFECEEEA);
  static const outline = Color(0xFF737873);
  static const success = Color(0xFF006F46);
  static const error = Color(0xFFB42318);

  /// Amaranto replaces the previous yellow team accent.
  static const teamTwo = primary;
  static const petrolContainer = Color(0xFFDDEBEA);

  /// Kept as a source-compatible alias for older consumers.
  @Deprecated('Use petrolContainer instead.')
  static const blueContainer = petrolContainer;
  static const brickContainer = Color(0xFFF3DAD5);
  static const teamTwoContainer = brickContainer;
  static const scrim = Color(0x66000000);

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const page = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const touch = 48.0;
  static const controlRadius = 12.0;
  static const panelRadius = 10.0;
  static const sheetRadius = 16.0;
  static const rosterShadow = [
    BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 5)),
    BoxShadow(color: Color(0x0C000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const display = TextStyle(
    fontFamily: 'Anton',
    fontWeight: FontWeight.w400,
    fontSize: 32,
    height: 1.12,
    color: ink,
  );
  static const pageTitle = display;
  static const heading = TextStyle(
    fontFamily: 'Anton',
    fontWeight: FontWeight.w400,
    fontSize: 24,
    height: 1.16,
    color: ink,
  );
  static const title = TextStyle(
    fontFamily: 'Italia Barlow',
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.2,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: 'Italia Barlow',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.4,
    color: ink,
  );
  static const label = TextStyle(
    fontFamily: 'Italia Barlow',
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.2,
    letterSpacing: 0.3,
  );
  static const caption = TextStyle(
    fontFamily: 'Italia Barlow',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: muted,
  );
  static const score = TextStyle(
    fontFamily: 'Anton',
    fontWeight: FontWeight.w400,
    fontSize: 112,
    height: 1,
    letterSpacing: -2,
    color: Colors.white,
  );
}

enum ItaliaTeam {
  one,
  two;

  Color get color => this == one ? Italia90.teamOne : Italia90.teamTwo;
  Color get container =>
      this == one ? Italia90.petrolContainer : Italia90.teamTwoContainer;
  Color get onColor => Colors.white;
  Color get onNeutralSurface => color;
  int get number => this == one ? 1 : 2;
  String get label => 'Squadra $number';
}

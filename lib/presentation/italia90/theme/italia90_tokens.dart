import 'package:flutter/material.dart';

/// Typed implementation of the approved DESIGN.md baseline.
abstract final class Italia90 {
  static const primary = Color(0xFFA83A2D);
  static const teamOne = Color(0xFF0047D8);
  static const homeAvatarBlue = Color(0xFF307BB4);
  static const green = Color(0xFF00834D);
  static const red = Color(0xFFE31331);
  static const surface = Color(0xFFFFFCF5);
  static const panel = Colors.white;
  static const ink = Colors.black;
  static const muted = Color(0xFF555A60);
  static const subtle = Color(0xFFECEEEA);
  static const outline = Color(0xFF737873);
  static const success = Color(0xFF006F46);
  static const error = Color(0xFFB42318);
  static const teamTwo = Color(0xFFF2C94C);
  static const blueContainer = Color(0xFFDCE8FF);
  static const brickContainer = Color(0xFFF3DAD5);
  static const teamTwoContainer = Color(0xFFFFF3CC);
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
      this == one ? Italia90.blueContainer : Italia90.teamTwoContainer;
  Color get onColor => this == one ? Colors.white : Italia90.ink;
  Color get onNeutralSurface => this == one ? color : Italia90.ink;
  int get number => this == one ? 1 : 2;
  String get label => 'Squadra $number';
}

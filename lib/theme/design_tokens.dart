import 'package:flutter/material.dart';

/// Runtime counterparts of the approved root DESIGN.md tokens.
abstract final class AppColors {
  static const primary = Color(0xFF0057B8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryPressed = Color(0xFF00428D);
  static const background = Color(0xFFF8F5EB);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111111);
  static const textSecondary = Color(0xFF5C5C55);
  static const outline = Color(0xFF85857C);
  static const divider = Color(0xFFDDD9CE);
  static const success = Color(0xFF087F3E);
  static const successPressed = Color(0xFF066631);
  static const successContainer = Color(0xFFE7F2E9);
  static const warningContainer = Color(0xFFFFF0B8);
  static const yellow = Color(0xFFFFC700);
  static const error = Color(0xFFC62828);
  static const errorContainer = Color(0xFFFBE9E7);
  static const teamOne = Color(0xFF0057B8);
  static const teamOneContainer = Color(0xFFE8F0FA);
  static const teamTwo = Color(0xFFFF7900);
  static const teamTwoContainer = Color(0xFFFFF0E1);
  static const disabledContainer = Color(0xFFE5E2D9);
  static const disabledContent = Color(0xFF5C5C55);

  static Color onTeam(Color team) => team == teamTwo ? ink : onPrimary;
  static Color teamContainer(Color team) =>
      team == teamTwo ? teamTwoContainer : teamOneContainer;
}

abstract final class AppSpace {
  static const hairline = 1.0;
  static const micro = 4.0;
  static const small = 8.0;
  static const medium = 12.0;
  static const page = 16.0;
  static const section = 24.0;
  static const large = 32.0;
  static const touch = 48.0;
  static const action = 56.0;
}

abstract final class AppRadius {
  static const small = 8.0;
  static const control = 12.0;
  static const panel = 16.0;
  static const sheet = 24.0;
}

abstract final class AppType {
  static const displayFamily = 'Barlow Condensed';
  static const bodyFamily = 'Barlow';
  static const score = TextStyle(
    fontFamily: displayFamily,
    fontSize: 112,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -1,
  );
  static const event = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: 0,
  );
  static const screen = TextStyle(
    fontFamily: displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0,
  );
  static const section = TextStyle(
    fontFamily: displayFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 0,
  );
  static const player = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );
  static const bodyStrong = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );
  static const action = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: .2,
  );
  static const utility = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0,
  );
  static const caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
  );
  static const navigation = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: 0,
  );
}

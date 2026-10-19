import 'package:flutter/material.dart';

import 'italia90_tokens.dart';

/// Compatibility names for the shared screen structure.
///
/// Values deliberately resolve to the approved Italia ’90 token set; feature
/// screens can share the reference branch's layout vocabulary without
/// importing its palette or typography.
abstract final class AppColors {
  static const primary = Italia90.primary;
  static const onPrimary = Colors.white;
  static const primaryPressed = Color(0xFF7B2A21);
  static const homeAction = Italia90.green;
  static const homeActionPressed = successPressed;
  static const background = Italia90.surface;
  static const surface = Italia90.panel;
  static const ink = Italia90.ink;
  static const textSecondary = Italia90.muted;
  static const outline = Italia90.outline;
  static const divider = Italia90.subtle;
  static const success = Italia90.success;
  static const successPressed = Color(0xFF005238);
  static const successContainer = Color(0xFFE1F1E9);
  static const warningContainer = Italia90.teamTwoContainer;
  static const yellow = Italia90.teamTwo;
  static const error = Italia90.error;
  static const errorContainer = Color(0xFFFBE9E7);
  static const teamOne = Italia90.teamOne;
  static const teamOneContainer = Italia90.petrolContainer;
  static const teamTwo = Italia90.teamTwo;
  static const teamTwoContainer = Italia90.teamTwoContainer;
  static const disabledContainer = Italia90.subtle;
  static const disabledContent = Italia90.muted;

  static Color onTeam(Color team) => onPrimary;

  static Color teamContainer(Color team) =>
      team == teamTwo ? teamTwoContainer : teamOneContainer;
}

abstract final class AppSpace {
  static const hairline = 1.0;
  static const micro = Italia90.xs;
  static const small = Italia90.sm;
  static const medium = Italia90.md;
  static const page = Italia90.page;
  static const section = Italia90.xl;
  static const large = Italia90.xxl;
  static const touch = Italia90.touch;
  static const action = 56.0;
}

abstract final class AppRadius {
  static const small = 8.0;
  static const control = Italia90.controlRadius;
  static const panel = Italia90.panelRadius;
  static const sheet = Italia90.sheetRadius;
}

abstract final class AppType {
  static const displayFamily = 'Anton';
  static const bodyFamily = 'Italia Barlow';
  static const score = Italia90.score;
  static const event = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    fontWeight: FontWeight.w400,
    height: 1,
  );
  static const screen = Italia90.display;
  static const section = Italia90.heading;
  static const player = Italia90.title;
  static const body = Italia90.body;
  static const bodyStrong = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const action = Italia90.label;
  static const homeAction = TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    height: 1,
    letterSpacing: .2,
  );
  static const utility = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const caption = Italia90.caption;
  static const navigation = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
}

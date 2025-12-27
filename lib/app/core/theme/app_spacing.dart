import 'package:flutter/material.dart';

/// App spacing constants for consistent layout
class AppSpacing {
  AppSpacing._();

  // Base spacing unit
  static const double unit = 4.0;

  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Screen padding
  static const double screenPaddingH = 20.0;
  static const double screenPaddingV = 16.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingH,
    vertical: screenPaddingV,
  );

  // Card padding
  static const double cardPadding = 16.0;
  static const EdgeInsets cardInsets = EdgeInsets.all(16.0);

  // List spacing
  static const double listItemSpacing = 12.0;
  static const double listSectionSpacing = 24.0;

  // Button sizing
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightLarge = 56.0;

  // Icon sizing
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Avatar sizing
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;

  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999.0;

  // Border radius shortcuts
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // Bottom sheet
  static const double bottomSheetRadius = 24.0;

  // Bottom navigation
  static const double bottomNavHeight = 72.0;

  // App bar
  static const double appBarHeight = 56.0;

  // Chip
  static const double chipHeight = 36.0;
  static const double chipPaddingH = 14.0;
}


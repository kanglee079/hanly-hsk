import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App typography - clean, readable text styles
/// UPDATED: Increased font sizes for accessibility compliance (App Store requirements)
/// Minimum sizes: labels 13pt, body 16pt, titles 17pt+
class AppTypography {
  AppTypography._();

  // Font family
  static const String fontFamily = 'SF Pro Display';
  static const String fontFamilyMono = 'SF Mono';

  // Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Display styles - large headers
  static TextStyle displayLarge = const TextStyle(
    fontSize: 36,
    fontWeight: bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle displayMedium = const TextStyle(
    fontSize: 32,
    fontWeight: bold,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySmall = const TextStyle(
    fontSize: 28,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  // Headline styles
  static TextStyle headlineLarge = const TextStyle(
    fontSize: 26,
    fontWeight: semiBold,
    height: 1.3,
    letterSpacing: -0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = const TextStyle(
    fontSize: 24,
    fontWeight: semiBold,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSmall = const TextStyle(
    fontSize: 21,
    fontWeight: semiBold,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Title styles
  static TextStyle titleLarge = const TextStyle(
    fontSize: 20,
    fontWeight: semiBold,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle titleMedium = const TextStyle(
    fontSize: 18,
    fontWeight: medium,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle titleSmall = const TextStyle(
    fontSize: 17,
    fontWeight: medium,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body styles
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 18,
    fontWeight: regular,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 15,
    fontWeight: regular,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Label styles
  static TextStyle labelLarge = const TextStyle(
    fontSize: 16,
    fontWeight: medium,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = const TextStyle(
    fontSize: 14,
    fontWeight: medium,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static TextStyle labelSmall = const TextStyle(
    fontSize: 13,
    fontWeight: medium,
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.textSecondary,
  );

  // Special styles - Hanzi characters
  static TextStyle hanziLarge = const TextStyle(
    fontSize: 72,
    fontWeight: regular,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle hanziMedium = const TextStyle(
    fontSize: 48,
    fontWeight: regular,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle hanziSmall = const TextStyle(
    fontSize: 32,
    fontWeight: regular,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle pinyin = const TextStyle(
    fontSize: 18,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle pinyinSmall = const TextStyle(
    fontSize: 15,
    fontWeight: regular,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static TextStyle button = const TextStyle(
    fontSize: 18,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textOnPrimary,
  );

  static TextStyle buttonSmall = const TextStyle(
    fontSize: 16,
    fontWeight: semiBold,
    height: 1.2,
    color: AppColors.textOnPrimary,
  );

  static TextStyle chip = const TextStyle(
    fontSize: 15,
    fontWeight: medium,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Helper for creating text themes
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );

  // Dark theme text theme
  static TextTheme get textThemeDark => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.textPrimaryDark),
        displayMedium: displayMedium.copyWith(color: AppColors.textPrimaryDark),
        displaySmall: displaySmall.copyWith(color: AppColors.textPrimaryDark),
        headlineLarge:
            headlineLarge.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium:
            headlineMedium.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: titleLarge.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: titleMedium.copyWith(color: AppColors.textPrimaryDark),
        titleSmall: titleSmall.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: labelLarge.copyWith(color: AppColors.textPrimaryDark),
        labelMedium: labelMedium.copyWith(color: AppColors.textPrimaryDark),
        labelSmall: labelSmall.copyWith(color: AppColors.textSecondaryDark),
      );
}

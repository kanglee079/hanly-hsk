import 'package:flutter/material.dart';

/// App color palette - calm, premium design with vivid blue accent
class AppColors {
  AppColors._();

  // Primary - Vivid blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // Secondary - Warm accent
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFD97706);

  // Success
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  // Neutral - Light theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F9); // Slightly darker for better contrast with cards
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8EEF4); // Slightly darker
  static const Color surfaceElevated = Color(0xFFFFFFFF); // For elevated cards
  static const Color border = Color(0xFFCBD5E1); // Darker border for better visibility
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFF94A3B8); // Strong border for focus

  // Text colors - Light theme
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF0F172A);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);
  static const Color borderLightDark = Color(0xFF475569);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Semantic colors
  static const Color favorite = Color(0xFFEF4444);
  static const Color streak = Color(0xFFF59E0B);
  static const Color progress = Color(0xFF10B981);

  // HSK Level colors
  static const Color hsk1 = Color(0xFF10B981);
  static const Color hsk2 = Color(0xFF22D3EE);
  static const Color hsk3 = Color(0xFF3B82F6);
  static const Color hsk4 = Color(0xFF8B5CF6);
  static const Color hsk5 = Color(0xFFF59E0B);
  static const Color hsk6 = Color(0xFFEF4444);

  /// Get HSK level color
  static Color getHskColor(int level) {
    switch (level) {
      case 1:
        return hsk1;
      case 2:
        return hsk2;
      case 3:
        return hsk3;
      case 4:
        return hsk4;
      case 5:
        return hsk5;
      case 6:
        return hsk6;
      default:
        return primary;
    }
  }

  // Rating colors
  static const Color ratingAgain = Color(0xFFEF4444);
  static const Color ratingHard = Color(0xFFF59E0B);
  static const Color ratingGood = Color(0xFF10B981);
  static const Color ratingEasy = Color(0xFF3B82F6);

  // Shimmer/Skeleton
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);

  // Disabled
  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledDark = Color(0xFF475569);
}


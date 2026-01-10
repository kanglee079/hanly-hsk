import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

/// HMIcon - Custom SVG icon widget
/// Provides easy-to-use interface for rendering SVG icons with color and size
class HMIcon extends StatelessWidget {
  /// Path to SVG asset
  final String assetPath;

  /// Icon size (both width and height)
  final double size;

  /// Icon color - if null, uses original SVG colors
  final Color? color;

  /// Semantic label for accessibility
  final String? semanticLabel;

  const HMIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  /// Factory for small icons (16px)
  factory HMIcon.small(String assetPath, {Color? color}) {
    return HMIcon(assetPath, size: 16, color: color);
  }

  /// Factory for medium icons (24px) - default
  factory HMIcon.medium(String assetPath, {Color? color}) {
    return HMIcon(assetPath, size: 24, color: color);
  }

  /// Factory for large icons (32px)
  factory HMIcon.large(String assetPath, {Color? color}) {
    return HMIcon(assetPath, size: 32, color: color);
  }

  /// Factory for extra large icons (48px)
  factory HMIcon.xl(String assetPath, {Color? color}) {
    return HMIcon(assetPath, size: 48, color: color);
  }

  @override
  Widget build(BuildContext context) {
    // Check if the asset is PNG (app_icon)
    if (assetPath.endsWith('.png')) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    // SVG icon
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      semanticsLabel: semanticLabel,
    );
  }
}

/// HMNavIcon - Special icon for bottom navigation
/// Uses original SVG colors (no colorFilter) for gradient support
class HMNavIcon extends StatelessWidget {
  final String assetPath;
  final String? inactiveAssetPath;
  final bool isActive;
  final double size;

  const HMNavIcon({
    super.key,
    required this.assetPath,
    this.inactiveAssetPath,
    this.isActive = false,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // If has inactive variant (like streak flame), use it
    if (!isActive && inactiveAssetPath != null) {
      return SvgPicture.asset(
        inactiveAssetPath!,
        width: size,
        height: size,
      );
    }
    
    // For active state, use original colors (gradients etc)
    if (isActive) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
      );
    }
    
    // For inactive state without variant, apply gray filter
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        BlendMode.srcIn,
      ),
    );
  }
}

/// Helper extension to use HMIcon in place of Icon
extension IconReplacement on Icon {
  /// Convert to HMIcon if SVG path is provided
  Widget toHMIcon(String? svgPath) {
    if (svgPath == null) return this;
    return HMIcon(
      svgPath,
      size: size ?? 24,
      color: color,
    );
  }
}

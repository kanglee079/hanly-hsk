import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../theme/app_colors.dart';

/// Custom cache manager for HanLy images
/// - Max cache size: 100 files
/// - Cache duration: 30 days
class HanLyCacheManager {
  static const key = 'hanly_image_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
}

/// Optimized cached network image widget
/// Features:
/// - Uses custom cache manager
/// - Shows loading placeholder
/// - Shows error placeholder
/// - Optimizes memory usage
class HMCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const HMCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(bgColor, isDark);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: HanLyCacheManager.instance,
        width: width,
        height: height,
        fit: fit,
        // Memory cache settings
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        // Loading placeholder
        placeholder: (context, url) => placeholder ?? _buildLoadingPlaceholder(bgColor),
        // Error placeholder
        errorWidget: (context, url, error) => 
            errorWidget ?? _buildErrorPlaceholder(bgColor, isDark),
        // Fade animation
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Widget _buildPlaceholder(Color bgColor, bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        size: 24,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(Color bgColor, bool isDark) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Icon(
        Icons.broken_image_outlined,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        size: 24,
      ),
    );
  }
}

/// Vocab image with optimized caching
/// Use this for displaying vocab images
class HMVocabImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final BorderRadius? borderRadius;

  const HMVocabImage({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return HMCachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      fit: BoxFit.cover,
    );
  }
}


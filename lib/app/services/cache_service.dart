import 'package:get/get.dart';
import '../core/widgets/hm_cached_image.dart';
import '../core/utils/logger.dart';
import 'audio_service.dart';

/// Service to manage all app caching
/// Provides centralized cache management for images and audio
class CacheService extends GetxService {
  /// Get total cache size (images + audio)
  Future<Map<String, int>> getCacheSizes() async {
    int audioSize = 0;
    
    try {
      final audioService = Get.find<AudioService>();
      audioSize = await audioService.getCacheSize();
    } catch (e) {
      Logger.e('CacheService', 'Error getting audio cache size: $e');
    }
    
    // Note: flutter_cache_manager doesn't expose cache size easily
    // We'll estimate based on file count
    
    return {
      'audio': audioSize,
    };
  }

  /// Get formatted total cache size
  Future<String> getTotalCacheSizeFormatted() async {
    final sizes = await getCacheSizes();
    final total = sizes.values.fold<int>(0, (a, b) => a + b);
    
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    return '${(total / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    Logger.d('CacheService', '🗑️ Clearing all caches...');
    
    try {
      // Clear image cache
      await HanLyCacheManager.clearCache();
      Logger.d('CacheService', '✅ Image cache cleared');
    } catch (e) {
      Logger.e('CacheService', 'Error clearing image cache: $e');
    }
    
    try {
      // Clear audio cache
      final audioService = Get.find<AudioService>();
      await audioService.clearCache();
      Logger.d('CacheService', '✅ Audio cache cleared');
    } catch (e) {
      Logger.e('CacheService', 'Error clearing audio cache: $e');
    }
    
    Logger.d('CacheService', '🗑️ All caches cleared');
  }

  /// Clear image cache only
  Future<void> clearImageCache() async {
    try {
      await HanLyCacheManager.clearCache();
      Logger.d('CacheService', '✅ Image cache cleared');
    } catch (e) {
      Logger.e('CacheService', 'Error clearing image cache: $e');
    }
  }

  /// Clear audio cache only
  Future<void> clearAudioCache() async {
    try {
      final audioService = Get.find<AudioService>();
      await audioService.clearCache();
    } catch (e) {
      Logger.e('CacheService', 'Error clearing audio cache: $e');
    }
  }
}


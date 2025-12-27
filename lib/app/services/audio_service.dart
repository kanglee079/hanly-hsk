import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../core/utils/logger.dart';
import '../core/widgets/hm_toast.dart';

/// Audio service with local caching to minimize bandwidth
/// Files are cached locally after first download
class AudioService extends GetxService {
  AudioPlayer? _player;
  final Dio _dio = Dio();
  
  // Cache directory
  Directory? _cacheDir;
  
  // Track cached files
  final Map<String, String> _cachedPaths = {};

  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;
  final Rx<String?> currentUrl = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    _initService();
  }

  Future<void> _initService() async {
    try {
      // Initialize audio player
      _player = AudioPlayer();
      _setupPlayerListeners();
      
      // Setup cache directory
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/audio_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      Logger.d('AudioService', 'Initialized with cache at: ${_cacheDir!.path}');
    } catch (e) {
      Logger.e('AudioService', 'Failed to initialize: $e');
    }
  }

  void _setupPlayerListeners() {
    _player?.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isLoading.value = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        currentUrl.value = null;
      }
    }, onError: (e) {
      Logger.e('AudioService', 'Player state error: $e');
    });
  }

  /// Generate cache key from URL
  String _getCacheKey(String url) {
    // Use base64 encoding of URL for filename
    final bytes = utf8.encode(url);
    final encoded = base64Url.encode(bytes);
    // Truncate if too long and add extension
    final key = encoded.length > 100 ? encoded.substring(0, 100) : encoded;
    return '$key.mp3';
  }

  /// Get cached file path if exists
  Future<String?> _getCachedFile(String url) async {
    if (_cacheDir == null) return null;
    
    // Check memory cache first
    if (_cachedPaths.containsKey(url)) {
      final path = _cachedPaths[url]!;
      if (await File(path).exists()) {
        return path;
      }
    }
    
    // Check disk cache
    final cacheKey = _getCacheKey(url);
    final cachePath = '${_cacheDir!.path}/$cacheKey';
    final cacheFile = File(cachePath);
    
    if (await cacheFile.exists()) {
      _cachedPaths[url] = cachePath;
      Logger.d('AudioService', '✅ Cache HIT: $cacheKey');
      return cachePath;
    }
    
    Logger.d('AudioService', '❌ Cache MISS: $cacheKey');
    return null;
  }

  /// Download and cache audio file
  Future<String?> _downloadAndCache(String url) async {
    if (_cacheDir == null) return null;
    
    final cacheKey = _getCacheKey(url);
    final cachePath = '${_cacheDir!.path}/$cacheKey';
    
    try {
      isDownloading.value = true;
      Logger.d('AudioService', '📥 Downloading: $url');
      
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'audio/mpeg, audio/*',
            'User-Agent': 'HanLy/1.0',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // Save to cache
        final file = File(cachePath);
        await file.writeAsBytes(response.data!);
        
        _cachedPaths[url] = cachePath;
        Logger.d('AudioService', '💾 Cached: $cacheKey (${response.data!.length} bytes)');
        
        return cachePath;
      } else {
        Logger.e('AudioService', 'Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.e('AudioService', 'Download error: $e');
      return null;
    } finally {
      isDownloading.value = false;
    }
  }

  /// Play audio from URL with caching
  Future<void> play(String url, {double speed = 1.0}) async {
    if (_player == null) {
      Logger.e('AudioService', 'Player not initialized');
      HMToast.error('Audio player chưa sẵn sàng');
      return;
    }

    if (url.isEmpty) {
      Logger.w('AudioService', 'Empty audio URL');
      HMToast.info('Audio không khả dụng');
      return;
    }

    Logger.d('AudioService', '========== PLAYING AUDIO ==========');
    Logger.d('AudioService', 'URL: $url');

    try {
      // Stop if playing same url
      if (currentUrl.value == url && isPlaying.value) {
        await stop();
        return;
      }

      currentUrl.value = url;
      isLoading.value = true;

      // Stop current playback
      try { await _player!.stop(); } catch (_) {}

      // Check cache first, download if not cached
      String? localPath = await _getCachedFile(url);
      localPath ??= await _downloadAndCache(url);

      if (localPath != null) {
        // Play from local file
        Logger.d('AudioService', '▶️ Playing from cache: $localPath');
        await _player!.setFilePath(localPath);
      } else {
        // Fallback to streaming (will incur bandwidth)
        Logger.w('AudioService', '⚠️ Streaming (not cached): $url');
        await _player!.setAudioSource(
          AudioSource.uri(Uri.parse(url)),
        );
      }

      await _player!.setSpeed(speed);
      await _player!.play();
      Logger.d('AudioService', '✅ Audio playing!');
      
    } on PlayerException catch (e) {
      Logger.e('AudioService', 'PlayerException: ${e.code} - ${e.message}');
      _handlePlayError(e.message ?? 'Lỗi player');
      _resetState();
    } catch (e) {
      Logger.e('AudioService', 'Play error: $e');
      _handlePlayError(e.toString());
      _resetState();
    }
  }

  void _handlePlayError(String error) {
    if (error.contains('not found') || error.contains('404')) {
      HMToast.error('File audio không tồn tại');
    } else if (error.contains('network') || error.contains('connection')) {
      HMToast.error('Lỗi kết nối mạng');
    } else {
      HMToast.error('Không thể phát audio');
    }
  }

  void _resetState() {
    isPlaying.value = false;
    isLoading.value = false;
    isDownloading.value = false;
    currentUrl.value = null;
  }

  /// Play at normal speed (1.0x)
  Future<void> playNormal(String url) => play(url, speed: 1.0);

  /// Play at slow speed (0.75x)
  Future<void> playSlow(String url) => play(url, speed: 0.75);

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      Logger.e('AudioService', 'Stop error: $e');
    }
    _resetState();
  }

  /// Pause playback
  Future<void> pause() async {
    try { await _player?.pause(); } catch (_) {}
  }

  /// Resume playback
  Future<void> resume() async {
    try { await _player?.play(); } catch (_) {}
  }

  /// Pre-cache audio files for a list of vocab
  Future<void> preCacheAudio(List<String> urls) async {
    Logger.d('AudioService', '📦 Pre-caching ${urls.length} audio files...');
    
    for (final url in urls) {
      if (url.isEmpty) continue;
      
      final cached = await _getCachedFile(url);
      if (cached == null) {
        await _downloadAndCache(url);
        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    Logger.d('AudioService', '✅ Pre-cache complete');
  }

  /// Clear all cached audio files
  Future<void> clearCache() async {
    if (_cacheDir == null) return;
    
    try {
      if (await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
      }
      _cachedPaths.clear();
      Logger.d('AudioService', '🗑️ Audio cache cleared');
      HMToast.success('Đã xóa cache audio');
    } catch (e) {
      Logger.e('AudioService', 'Clear cache error: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;
    
    int totalSize = 0;
    try {
      if (await _cacheDir!.exists()) {
        await for (final entity in _cacheDir!.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      Logger.e('AudioService', 'Get cache size error: $e');
    }
    return totalSize;
  }

  /// Get cache size as formatted string
  Future<String> getCacheSizeFormatted() async {
    final size = await getCacheSize();
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }
}

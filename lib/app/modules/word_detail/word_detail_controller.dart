import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/vocab_repo.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../services/audio_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../routes/app_routes.dart';

/// Word detail controller - loads from API if needed
class WordDetailController extends GetxController {
  final VocabRepo _vocabRepo = Get.find<VocabRepo>();
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  
  // TTS for example sentences (nullable to avoid late init errors)
  FlutterTts? _tts;

  final Rx<VocabModel?> vocab = Rx<VocabModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxBool isSpeaking = false.obs;
  final Rx<String?> speakingText = Rx<String?>(null); // Track which text is speaking
  
  // Image carousel
  final RxInt currentImageIndex = 0.obs;

  // Accordion states
  final RxBool meaningExpanded = true.obs;
  final RxBool hanziDnaExpanded = false.obs;
  final RxBool contextExpanded = false.obs;
  final RxBool metadataExpanded = false.obs;
  final RxBool examplesExpanded = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initTts();
    _parseArgumentsAndLoad();
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('zh-CN');
      await _tts?.setSpeechRate(0.35); // Slower speed for learning
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);
      
      _tts?.setStartHandler(() {
        isSpeaking.value = true;
      });
      
      _tts?.setCompletionHandler(() {
        isSpeaking.value = false;
        speakingText.value = null;
      });
      
      _tts?.setCancelHandler(() {
        isSpeaking.value = false;
        speakingText.value = null;
      });
      
      _tts?.setErrorHandler((msg) {
        isSpeaking.value = false;
        speakingText.value = null;
        Logger.e('WordDetailController', 'TTS error: $msg');
      });
      
      Logger.d('WordDetailController', 'TTS initialized successfully');
    } catch (e) {
      // TTS not available (plugin not installed or hot reload issue)
      Logger.w('WordDetailController', 'TTS initialization failed: $e');
      _tts = null;
    }
  }

  void _parseArgumentsAndLoad() {
    final arguments = Get.arguments;

    // Handle case when arguments is a String (vocabId directly)
    if (arguments is String) {
      _loadVocabDetails(arguments);
      return;
    }

    // Handle case when arguments is a Map
    if (arguments is Map<String, dynamic>) {
      if (arguments['vocab'] != null) {
        // Use passed vocab but also reload for full details
        vocab.value = arguments['vocab'] as VocabModel;
        final vocabId = vocab.value?.id ?? arguments['vocabId'];
        if (vocabId != null) {
          _loadVocabDetails(vocabId.toString());
        }
      } else if (arguments['vocabId'] != null) {
        _loadVocabDetails(arguments['vocabId'].toString());
      }
    }
  }

  Future<void> _loadVocabDetails(String id) async {
    isLoading.value = true;
    hasError.value = false;
    
    try {
      final vocabDetail = await _vocabRepo.getVocabById(id);
      vocab.value = vocabDetail;
    } catch (e) {
      Logger.e('WordDetailController', 'loadVocabDetails error', e);
      hasError.value = vocab.value == null; // Only show error if no vocab was passed
    } finally {
      isLoading.value = false;
    }
  }

  void playAudio({bool slow = false}) {
    final v = vocab.value;
    if (v == null) {
      Logger.w('WordDetailController', 'No vocab for audio');
      return;
    }

    Logger.d('WordDetailController', '=== PLAY AUDIO REQUEST ===');
    Logger.d('WordDetailController', 'Vocab: ${v.hanzi} (${v.id})');
    Logger.d('WordDetailController', 'audioUrl: ${v.audioUrl}');
    Logger.d('WordDetailController', 'audioSlowUrl: ${v.audioSlowUrl}');
    Logger.d('WordDetailController', 'Slow mode: $slow');

    final url = slow ? v.audioSlowUrl : v.audioUrl;
    
    if (url != null && url.isNotEmpty) {
      Logger.d('WordDetailController', 'Playing URL: $url');
      if (slow) {
        _audioService.playSlow(url);
      } else {
        _audioService.playNormal(url);
      }
    } else {
      Logger.w('WordDetailController', 'No ${slow ? "slow" : "normal"} audio URL for vocab: ${v.hanzi}');
      HMToast.info('Audio ${slow ? "chậm" : ""} không khả dụng cho từ này');
    }
  }

  void stopAudio() {
    _audioService.stop();
  }

  /// Speak Chinese text using TTS (for example sentences)
  Future<void> speakText(String text) async {
    if (_tts == null) {
      HMToast.info('TTS chưa sẵn sàng. Vui lòng khởi động lại app.');
      return;
    }
    
    // If already speaking this text, stop it
    if (speakingText.value == text) {
      await _tts?.stop();
      isSpeaking.value = false;
      speakingText.value = null;
      return;
    }
    
    // If speaking different text, stop and start new
    if (isSpeaking.value) {
      await _tts?.stop();
    }
    
    try {
      speakingText.value = text;
      await _tts?.speak(text);
    } catch (e) {
      Logger.e('WordDetailController', 'speakText error', e);
      speakingText.value = null;
      HMToast.info('Tính năng TTS chưa sẵn sàng');
    }
  }
  
  /// Check if specific text is being spoken
  bool isTextSpeaking(String text) {
    return speakingText.value == text;
  }

  /// Stop TTS
  Future<void> stopSpeaking() async {
    await _tts?.stop();
    isSpeaking.value = false;
  }

  /// Search for a collocation word
  void searchCollocation(String collocation) {
    // Navigate to explore with search query
    Get.toNamed(Routes.shell, arguments: {'tab': 2, 'searchQuery': collocation});
  }

  /// Update image index
  void setImageIndex(int index) {
    currentImageIndex.value = index;
  }

  Future<void> toggleFavorite() async {
    final v = vocab.value;
    if (v == null) return;
    
    try {
      isLoading.value = true;
      
      if (v.isFavorite) {
        await _favoritesRepo.removeFavorite(v.id);
        vocab.value = v.copyWith(isFavorite: false);
        HMToast.success(ToastMessages.favoritesRemoveSuccess);
      } else {
        await _favoritesRepo.addFavorite(v.id);
        vocab.value = v.copyWith(isFavorite: true);
        HMToast.success(ToastMessages.favoritesAddSuccess);
      }
    } catch (e) {
      Logger.e('WordDetailController', 'toggleFavorite error', e);
      HMToast.error(ToastMessages.favoritesUpdateError);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleSection(String section) {
    switch (section) {
      case 'meaning':
        meaningExpanded.value = !meaningExpanded.value;
        break;
      case 'hanziDna':
        hanziDnaExpanded.value = !hanziDnaExpanded.value;
        break;
      case 'context':
        contextExpanded.value = !contextExpanded.value;
        break;
      case 'metadata':
        metadataExpanded.value = !metadataExpanded.value;
        break;
    }
  }

  Future<void> retry() async {
    final arguments = Get.arguments;
    String? vocabId;

    if (arguments is String) {
      vocabId = arguments;
    } else if (arguments is Map<String, dynamic>) {
      vocabId = arguments['vocabId']?.toString() ?? vocab.value?.id;
    } else {
      vocabId = vocab.value?.id;
    }

    if (vocabId != null) {
      await _loadVocabDetails(vocabId);
    }
  }

  @override
  void onClose() {
    _audioService.stop();
    _tts?.stop();
    super.onClose();
  }
}

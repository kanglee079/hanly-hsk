import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../data/models/vocab_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../services/audio_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../shell/shell_controller.dart';

/// Pronunciation practice controller with real speech recognition
class PronunciationController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  
  // Speech to text
  stt.SpeechToText? _speech;
  final RxBool isSpeechAvailable = false.obs;
  final RxList<stt.LocaleName> availableLocales = <stt.LocaleName>[].obs;

  // State
  final RxList<VocabModel> words = <VocabModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isRecording = false.obs;
  final RxBool isEvaluating = false.obs;
  final RxBool isSessionComplete = false.obs;
  final RxBool hasResult = false.obs;
  
  // Recording visual feedback
  final RxDouble soundLevel = 0.0.obs;
  final RxString recognizedText = ''.obs;
  final RxString lastError = ''.obs;

  // Current evaluation result
  final RxInt currentScore = 0.obs;
  final RxBool isPassed = false.obs;
  final RxString feedback = ''.obs;
  final RxString feedbackEmoji = ''.obs;

  // Session stats
  final RxInt totalAttempts = 0.obs;
  final RxInt passedCount = 0.obs;
  final RxDouble averageScore = 0.0.obs;
  final RxList<AttemptRecord> attempts = <AttemptRecord>[].obs;

  // Timer for practice
  final RxInt practiceSeconds = 0.obs;
  Timer? _timer;
  
  // Recording timeout
  Timer? _recordingTimer;
  static const int maxRecordingSeconds = 5;
  final RxInt recordingCountdown = maxRecordingSeconds.obs;

  VocabModel? get currentWord =>
      words.isNotEmpty && currentIndex.value < words.length
          ? words[currentIndex.value]
          : null;

  int get remainingWords => words.length - currentIndex.value;
  
  bool get isLastWord => currentIndex.value >= words.length - 1;

  @override
  void onInit() {
    super.onInit();
    _initSpeech();
    loadWords();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      isSpeechAvailable.value = await _speech!.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      
      if (isSpeechAvailable.value) {
        availableLocales.value = await _speech!.locales();
        Logger.d('PronunciationController', 'Speech available. Locales: ${availableLocales.length}');
        
        // Check for Chinese locale
        final hasChineseLocale = availableLocales.any((l) => 
          l.localeId.startsWith('zh') || l.localeId.contains('CN')
        );
        if (!hasChineseLocale) {
          Logger.w('PronunciationController', 'No Chinese locale available');
        }
      } else {
        Logger.w('PronunciationController', 'Speech recognition not available');
      }
    } catch (e) {
      Logger.e('PronunciationController', 'Speech init error', e);
      isSpeechAvailable.value = false;
    }
  }
  
  void _onSpeechStatus(String status) {
    Logger.d('PronunciationController', 'Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      if (isRecording.value && recognizedText.value.isEmpty) {
        // No speech detected
        _handleNoSpeechDetected();
      }
      isRecording.value = false;
    }
  }
  
  void _onSpeechError(dynamic error) {
    Logger.e('PronunciationController', 'Speech error: $error');
    lastError.value = error.toString();
    isRecording.value = false;
    _recordingTimer?.cancel();
    
    if (error.toString().contains('no-speech')) {
      _handleNoSpeechDetected();
    }
  }
  
  void _handleNoSpeechDetected() {
    recognizedText.value = '';
    feedback.value = 'Không nhận được giọng nói. Hãy thử lại!';
    feedbackEmoji.value = '🎤';
    hasResult.value = true;
    currentScore.value = 0;
    isPassed.value = false;
  }

  Future<void> loadWords() async {
    isLoading.value = true;

    try {
      // Get learned vocabs for pronunciation practice
      final response = await _learningRepo.getLearnedVocabs(
        limit: 10,
        state: 'all',
        shuffle: true,
      );

      words.value = response.vocabs;

      if (words.isEmpty) {
        HMToast.warning('Chưa có từ nào đã học. Hãy học từ mới trước!');
        Get.back();
        return;
      }

      _startTimer();
    } catch (e) {
      Logger.e('PronunciationController', 'loadWords error', e);
      HMToast.error('Không thể tải dữ liệu');
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isSessionComplete.value) {
        practiceSeconds.value++;
      }
    });
  }

  void playAudio({bool slow = false}) {
    final word = currentWord;
    if (word == null) return;

    HapticFeedback.lightImpact();
    
    final url = slow ? word.audioSlowUrl : word.audioUrl;
    if (url != null && url.isNotEmpty) {
      _audioService.play(url);
    } else if (word.audioUrl != null && word.audioUrl!.isNotEmpty) {
      // Fallback to normal audio with slow speed
      _audioService.play(word.audioUrl!, speed: slow ? 0.7 : 1.0);
    } else {
      HMToast.warning('Không có audio cho từ này');
    }
  }

  /// Start recording for pronunciation evaluation
  Future<void> startRecording() async {
    if (!isSpeechAvailable.value) {
      HMToast.error('Thiết bị không hỗ trợ nhận diện giọng nói');
      return;
    }
    
    if (_speech == null || isRecording.value) return;
    
    // Stop any playing audio
    await _audioService.stop();
    
    // Reset state
    recognizedText.value = '';
    hasResult.value = false;
    currentScore.value = 0;
    isPassed.value = false;
    feedback.value = '';
    lastError.value = '';
    recordingCountdown.value = maxRecordingSeconds;
    
    isRecording.value = true;
    HapticFeedback.mediumImpact();
    
    try {
      await _speech!.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: (level) {
          soundLevel.value = level;
        },
        localeId: 'zh_CN', // Mandarin Chinese
        listenFor: Duration(seconds: maxRecordingSeconds),
        pauseFor: const Duration(seconds: 2),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
      
      // Start countdown timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (recordingCountdown.value > 0) {
          recordingCountdown.value--;
        } else {
          timer.cancel();
          stopRecording();
        }
      });
      
    } catch (e) {
      Logger.e('PronunciationController', 'Listen error', e);
      isRecording.value = false;
      HMToast.error('Không thể bắt đầu ghi âm');
    }
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    recognizedText.value = result.recognizedWords;
    Logger.d('PronunciationController', 
      'Recognized: "${result.recognizedWords}" (final: ${result.finalResult})');
    
    if (result.finalResult) {
      isRecording.value = false;
      _recordingTimer?.cancel();
      _evaluatePronunciation(result.recognizedWords);
    }
  }

  void stopRecording() {
    _speech?.stop();
    _recordingTimer?.cancel();
    isRecording.value = false;
    
    // If we have partial results, evaluate them
    if (recognizedText.value.isNotEmpty && !hasResult.value) {
      _evaluatePronunciation(recognizedText.value);
    }
  }

  void _evaluatePronunciation(String spoken) {
    final word = currentWord;
    if (word == null) return;
    
    isEvaluating.value = true;
    
    // Normalize text for comparison
    final spokenNormalized = spoken.trim().toLowerCase();
    final hanziNormalized = word.hanzi.trim().toLowerCase();
    
    // Calculate similarity score
    int score = 0;
    
    if (spokenNormalized.isEmpty) {
      score = 0;
      feedback.value = 'Không nhận được giọng nói';
      feedbackEmoji.value = '🎤';
    } else if (spokenNormalized == hanziNormalized) {
      // Perfect match
      score = 100;
      feedback.value = 'Phát âm hoàn hảo!';
      feedbackEmoji.value = '🌟';
    } else if (spokenNormalized.contains(hanziNormalized) || 
               hanziNormalized.contains(spokenNormalized)) {
      // Partial match
      score = 85;
      feedback.value = 'Rất tốt! Gần đúng rồi!';
      feedbackEmoji.value = '👏';
    } else {
      // Calculate character-level similarity
      final similarity = _calculateSimilarity(spokenNormalized, hanziNormalized);
      score = (similarity * 100).round();
      
      if (score >= 70) {
        feedback.value = 'Khá tốt!';
        feedbackEmoji.value = '✅';
      } else if (score >= 50) {
        feedback.value = 'Cần luyện tập thêm';
        feedbackEmoji.value = '🔄';
      } else {
        feedback.value = 'Hãy nghe lại và thử lại!';
        feedbackEmoji.value = '💪';
      }
    }
    
    currentScore.value = score;
    isPassed.value = score >= 70;
    hasResult.value = true;
    
    // Record attempt
    attempts.add(AttemptRecord(
      vocabId: word.id,
      hanzi: word.hanzi,
      spoken: spoken,
      score: score,
      passed: isPassed.value,
    ));
    
    totalAttempts.value++;
    if (isPassed.value) {
      passedCount.value++;
      HapticFeedback.mediumImpact();
    }
    
    // Update average score
    final totalScore = attempts.fold<int>(0, (sum, a) => sum + a.score);
    averageScore.value = attempts.isNotEmpty ? totalScore / attempts.length : 0;
    
    isEvaluating.value = false;
    
    Logger.d('PronunciationController', 
      'Evaluation: spoken="$spoken", expected="${word.hanzi}", score=$score');
  }
  
  /// Calculate similarity between two strings (0-1)
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    
    // Simple character overlap calculation
    final aChars = a.split('');
    final bChars = b.split('');
    
    int matches = 0;
    for (final char in aChars) {
      if (bChars.contains(char)) {
        matches++;
      }
    }
    
    return matches / (aChars.length > bChars.length ? aChars.length : bChars.length);
  }

  void nextWord() {
    HapticFeedback.lightImpact();
    
    // Reset current state
    hasResult.value = false;
    recognizedText.value = '';
    currentScore.value = 0;
    isPassed.value = false;
    feedback.value = '';
    soundLevel.value = 0;

    if (currentIndex.value < words.length - 1) {
      currentIndex.value++;
    } else {
      _finishSession();
    }
  }

  void skipWord() {
    HapticFeedback.lightImpact();
    hasResult.value = false;
    recognizedText.value = '';
    
    if (currentIndex.value < words.length - 1) {
      currentIndex.value++;
    } else {
      _finishSession();
    }
  }
  
  /// Retry current word
  void retryWord() {
    HapticFeedback.lightImpact();
    hasResult.value = false;
    recognizedText.value = '';
    currentScore.value = 0;
    feedback.value = '';
    soundLevel.value = 0;
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    _recordingTimer?.cancel();
    _sessionSaved = true;
    isSessionComplete.value = true;

    if (attempts.isEmpty) return;

    try {
      // Calculate accuracy
      final accuracy = totalAttempts.value > 0 
          ? passedCount.value / totalAttempts.value 
          : 0.0;
      
      // Submit session to backend
      final result = SessionResultModel(
        seconds: practiceSeconds.value,
        newCount: 0,
        reviewCount: attempts.length,
        accuracy: accuracy,
      );
      
      await _learningRepo.finishSession(result);
      
      Logger.d('PronunciationController', 
        'Session submitted: ${passedCount.value}/${totalAttempts.value}');
      
      // Refresh shell data
      if (Get.isRegistered<ShellController>()) {
        Get.find<ShellController>().refreshAllData();
      }
    } catch (e) {
      Logger.e('PronunciationController', 'submitSession error', e);
    }
  }

  void restartSession() {
    HapticFeedback.mediumImpact();
    
    currentIndex.value = 0;
    totalAttempts.value = 0;
    passedCount.value = 0;
    averageScore.value = 0;
    attempts.clear();
    practiceSeconds.value = 0;
    hasResult.value = false;
    recognizedText.value = '';
    currentScore.value = 0;
    isSessionComplete.value = false;
    soundLevel.value = 0;

    words.shuffle();
    _startTimer();
  }

  /// Flag to prevent double-saving
  bool _sessionSaved = false;
  
  /// Minimum seconds before saving partial session
  static const int _minSecondsToSave = 10;

  /// Save partial session in background (fire-and-forget)
  void _savePartialSessionInBackground() {
    final seconds = practiceSeconds.value;
    
    // Only save if meaningful time spent
    if (seconds < _minSecondsToSave) {
      Logger.d('PronunciationController', '[SKIP_SAVE] seconds=$seconds < $_minSecondsToSave');
      return;
    }
    
    final accuracy = totalAttempts.value > 0 
        ? passedCount.value / totalAttempts.value 
        : 0.0;
    
    final result = SessionResultModel(
      seconds: seconds,
      newCount: 0,
      reviewCount: attempts.length,
      accuracy: accuracy,
    );
    
    Logger.d(
      'PronunciationController',
      '[PARTIAL_SAVE] seconds=$seconds, minutes=${result.minutes}, attempts=${attempts.length}',
    );
    
    // Fire and forget - don't block UI
    _learningRepo.finishSession(result).then((_) {
      if (Get.isRegistered<ShellController>()) {
        Get.find<ShellController>().refreshAllData();
      }
    }).catchError((e) {
      Logger.e('PronunciationController', 'Failed to save partial session', e);
    });
  }

  void goBack() {
    _timer?.cancel();
    _recordingTimer?.cancel();
    if (!_sessionSaved && !isSessionComplete.value && practiceSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    _speech?.stop();
    Get.back();
  }

  @override
  void onClose() {
    // Save partial session in background if not already saved
    if (!_sessionSaved && !isSessionComplete.value && practiceSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    
    _timer?.cancel();
    _recordingTimer?.cancel();
    _speech?.stop();
    _audioService.stop();
    super.onClose();
  }
}

/// Internal record of pronunciation attempt
class AttemptRecord {
  final String vocabId;
  final String hanzi;
  final String spoken;
  final int score;
  final bool passed;

  AttemptRecord({
    required this.vocabId,
    required this.hanzi,
    required this.spoken,
    required this.score,
    required this.passed,
  });
}

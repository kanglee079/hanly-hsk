import 'dart:async';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../data/models/vocab_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../data/repositories/pronunciation_repo.dart';
import '../../services/audio_service.dart';
import '../../services/realtime/realtime_sync_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../today/today_controller.dart';

export '../../data/models/today_model.dart' show ReviewRating;

/// Session step - 6 steps including pronunciation
enum SessionStep { guess, audio, hanziDna, context, pronunciation, quiz }

/// Session controller - uses real BE API
class SessionController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();
  late PronunciationRepo _pronunciationRepo;

  late SessionMode sessionMode;
  
  final RxList<VocabModel> queue = <VocabModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxInt currentStep = 0.obs; // 0-5 for 6 steps
  final RxBool isRevealed = false.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSessionComplete = false.obs;
  final RxBool hasNoData = false.obs;
  
  // Quiz state
  final RxList<String> quizOptions = <String>[].obs;
  final RxInt selectedAnswer = (-1).obs;
  final RxBool isAnswerCorrect = false.obs;
  final RxBool hasAnswered = false.obs;
  
  // Session timer
  DateTime? _sessionStart;
  final RxInt elapsedSeconds = 0.obs;
  Timer? _timer;
  
  // Stats
  int correctCount = 0;
  int totalQuizzes = 0;

  // Track time spent per vocab
  DateTime? _vocabStartTime;

  // Speech recognition
  stt.SpeechToText? _speech;
  final RxBool isSpeechAvailable = false.obs;
  final RxBool isListening = false.obs;
  final RxString recognizedText = ''.obs;
  final RxDouble speechConfidence = 0.0.obs;
  
  // Pronunciation evaluation
  final RxBool isPronunciationPassed = false.obs;
  final RxInt pronunciationScore = 0.obs;
  final RxString pronunciationFeedback = ''.obs;
  final RxBool hasPronunciationResult = false.obs;
  final RxBool isEvaluatingPronunciation = false.obs;
  
  // Track if user has listened to audio (required before manual pass)
  final RxBool hasListenedAudio = false.obs;

  VocabModel? get currentVocab =>
      queue.isNotEmpty && currentIndex.value < queue.length
          ? queue[currentIndex.value]
          : null;

  SessionStep get currentStepEnum => SessionStep.values[currentStep.value];

  double get progress {
    if (queue.isEmpty) return 0;
    final vocabProgress = currentIndex.value / queue.length;
    final stepProgress = (currentStep.value + 1) / 6 / queue.length; // 6 steps now
    return vocabProgress + stepProgress;
  }

  // Words passed from arguments (optional - for study modes API)
  List<VocabModel>? _preloadedWords;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    sessionMode = args?['mode'] as SessionMode? ?? SessionMode.newWords;
    
    // Check if words were passed directly (from study modes API)
    if (args?['words'] != null) {
      _preloadedWords = args!['words'] as List<VocabModel>;
    }
    
    // Initialize pronunciation repo
    try {
      _pronunciationRepo = Get.find<PronunciationRepo>();
    } catch (_) {
      // Pronunciation repo not available
    }
    
    _initSpeech();
    _loadQueue();
    _startTimer();
  }

  // Available Chinese locale
  String? _chineseLocaleId;
  
  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      isSpeechAvailable.value = await _speech!.initialize(
        onError: (error) {
          Logger.e('SessionController', 'Speech error: ${error.errorMsg}');
          isListening.value = false;
          
          // Show user-friendly error
          if (error.errorMsg.contains('error_listen_failed')) {
            HMToast.error('Không thể nhận dạng giọng nói. Hãy kiểm tra:\n'
                '• Quyền microphone đã được cấp\n'
                '• Thiết bị có kết nối internet');
          }
        },
        onStatus: (status) {
          Logger.d('SessionController', 'Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
      );
      Logger.d('SessionController', 'Speech available: ${isSpeechAvailable.value}');
      
      // Find Chinese locale
      if (isSpeechAvailable.value) {
        final locales = await _speech!.locales();
        Logger.d('SessionController', 'Available locales: ${locales.map((l) => l.localeId).toList()}');
        
        // Try to find Chinese locale in order of preference
        final zhLocales = ['zh_CN', 'zh-CN', 'zh_Hans_CN', 'zh_TW', 'zh-TW', 'zh_Hant_TW', 'cmn_Hans_CN'];
        for (final zhId in zhLocales) {
          final found = locales.any((l) => l.localeId == zhId || l.localeId.startsWith(zhId.split('_')[0]));
          if (found) {
            _chineseLocaleId = locales.firstWhere(
              (l) => l.localeId == zhId || l.localeId.startsWith(zhId.split('_')[0]),
            ).localeId;
            break;
          }
        }
        
        Logger.d('SessionController', 'Chinese locale found: $_chineseLocaleId');
        
        if (_chineseLocaleId == null) {
          Logger.w('SessionController', 'No Chinese locale available, will use default');
        }
      }
    } catch (e) {
      Logger.e('SessionController', 'Speech init error', e);
      isSpeechAvailable.value = false;
    }
  }

  void _startTimer() {
    _sessionStart = DateTime.now();
    _vocabStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value = DateTime.now().difference(_sessionStart!).inSeconds;
    });
  }

  Future<void> _loadQueue() async {
    isLoading.value = true;
    hasNoData.value = false;
    
    try {
      // Use preloaded words if available (from study modes API)
      if (_preloadedWords != null && _preloadedWords!.isNotEmpty) {
        queue.value = _preloadedWords!;
        _preloadedWords = null; // Clear after use
        _preCacheAudio();
        return;
      }
      
      final today = await _learningRepo.getToday();
      
      switch (sessionMode) {
        case SessionMode.newWords:
          // Check if user has reached daily limit
          if (today.remainingNewLimit <= 0) {
            hasNoData.value = true;
            HMToast.info(
              'Bạn đã học hết ${today.dailyNewLimit} từ mới hôm nay! 🎉\n'
              'Quay lại vào ngày mai hoặc tập trung ôn tập!',
            );
            return;
          }
          queue.value = today.newQueue.take(10).toList();
          break;
        case SessionMode.review:
          queue.value = today.reviewQueue.take(10).toList();
          break;
        case SessionMode.reviewToday:
          // Get words learned today from reviewQueue that were recently learned
          // These are words with state='learning' and learned today
          final learnedToday = today.reviewQueue
              .where((v) => v.state == 'learning' || v.reps == 1)
              .take(10)
              .toList();
          
          if (learnedToday.isEmpty) {
            // Fallback: use all review queue if no specific "learned today" filter
            queue.value = today.reviewQueue.take(10).toList();
          } else {
            queue.value = learnedToday;
          }
          break;
        case SessionMode.game30:
          final combined = [...today.newQueue, ...today.reviewQueue];
          combined.shuffle();
          queue.value = combined.take(5).toList();
          break;
      }
      
      if (queue.isEmpty) {
        hasNoData.value = true;
        if (sessionMode == SessionMode.newWords) {
          HMToast.info('Không có từ mới nào. Hãy kiểm tra lại cấp độ HSK!');
        } else if (sessionMode == SessionMode.review) {
          HMToast.info('Tuyệt vời! Không có từ nào cần ôn! 🎉');
        } else if (sessionMode == SessionMode.reviewToday) {
          HMToast.info('Chưa có từ nào được học hôm nay để ôn!');
        }
      } else {
        // Pre-cache audio files in background
        _preCacheAudio();
      }
    } catch (e) {
      Logger.e('SessionController', 'loadQueue error', e);
      hasNoData.value = true;
      HMToast.error('Không thể tải dữ liệu. Vui lòng thử lại.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pre-cache audio files for all vocabs in queue
  void _preCacheAudio() {
    final urls = <String>[];
    for (final vocab in queue) {
      if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty) {
        urls.add(vocab.audioUrl!);
      }
      if (vocab.audioSlowUrl != null && vocab.audioSlowUrl!.isNotEmpty) {
        urls.add(vocab.audioSlowUrl!);
      }
    }
    
    if (urls.isNotEmpty) {
      Logger.d('SessionController', 'Pre-caching ${urls.length} audio files');
      // Run in background, don't await
      _audioService.preCacheAudio(urls);
    }
  }

  void reveal() {
    isRevealed.value = true;
  }

  /// Check if current step needs reveal button (some steps auto-reveal)
  bool get needsRevealButton {
    // HanziDna and Context steps show content immediately, no need to reveal
    if (currentStepEnum == SessionStep.hanziDna || 
        currentStepEnum == SessionStep.context) {
      return false;
    }
    return !isRevealed.value;
  }

  void nextStep() {
    if (currentStep.value < 5) { // 6 steps: 0-5
      currentStep.value++;
      isRevealed.value = false;
      hasAnswered.value = false;
      selectedAnswer.value = -1;
      
      // Reset pronunciation state
      if (currentStepEnum == SessionStep.pronunciation) {
        _resetPronunciationState();
      }
      
      if (currentStepEnum == SessionStep.quiz) {
        _generateQuizOptions();
      }
      
      // Auto-reveal for steps that show content immediately
      if (currentStepEnum == SessionStep.hanziDna || 
          currentStepEnum == SessionStep.context) {
        isRevealed.value = true;
      }
    } else {
      // Move to next vocab
      // For NEW WORDS mode, auto-submit rating based on quiz result
      if (sessionMode == SessionMode.newWords) {
        _submitNewWordProgress();
      } else {
        _nextVocab();
      }
    }
  }

  /// Reset pronunciation state for new word
  void _resetPronunciationState() {
    recognizedText.value = '';
    speechConfidence.value = 0.0;
    isPronunciationPassed.value = false;
    pronunciationScore.value = 0;
    pronunciationFeedback.value = '';
    hasPronunciationResult.value = false;
    isEvaluatingPronunciation.value = false;
    hasListenedAudio.value = false;
  }
  
  /// Submit progress for new word (auto-rating based on quiz result)
  Future<void> _submitNewWordProgress() async {
    final vocab = currentVocab;
    if (vocab == null) {
      _nextVocab();
      return;
    }

    // Calculate time spent on this vocab
    final timeSpent = _vocabStartTime != null 
        ? DateTime.now().difference(_vocabStartTime!).inMilliseconds 
        : 5000;

    // Auto-rating: if quiz was correct → "good", if wrong → "hard"
    final rating = isAnswerCorrect.value ? ReviewRating.good : ReviewRating.hard;

    try {
      final response = await _learningRepo.submitReviewAnswer(
        vocabId: vocab.id,
        rating: rating,
        mode: 'learn',
        timeSpent: timeSpent,
      );
      
      Logger.d('SessionController', 
        'New word progress submitted: ${vocab.hanzi}, rating: ${rating.value}, interval: ${response.intervalDays} days');
      
    } catch (e) {
      Logger.e('SessionController', 'submitNewWordProgress error', e);
      // Don't block user flow on error
    }

    _nextVocab();
  }

  void _nextVocab() {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      currentStep.value = 0;
      isRevealed.value = false;
      hasAnswered.value = false;
      selectedAnswer.value = -1;
      _vocabStartTime = DateTime.now();
    } else {
      _finishSession();
    }
  }

  void _generateQuizOptions() {
    final vocab = currentVocab;
    if (vocab == null) return;

    final options = <String>[vocab.meaningVi];
    
    // Get distractors from other vocabs in queue
    final otherVocabs = queue.where((v) => v.id != vocab.id).toList();
    otherVocabs.shuffle();
    
    for (final v in otherVocabs) {
      if (options.length >= 4) break;
      if (!options.contains(v.meaningVi)) {
        options.add(v.meaningVi);
      }
    }

    // If not enough, add some generic distractors
    final genericDistractors = [
      'Tạm biệt',
      'Xin lỗi',
      'Không có gì',
      'Được',
      'Tốt lắm',
      'Rất tốt',
      'Một',
      'Hai',
      'Ba',
      'Bốn',
    ]..shuffle();

    while (options.length < 4 && genericDistractors.isNotEmpty) {
      final d = genericDistractors.removeAt(0);
      if (!options.contains(d)) {
        options.add(d);
      }
    }

    options.shuffle();
    quizOptions.value = options;
  }

  void selectAnswer(int index) {
    if (hasAnswered.value) return;
    
    selectedAnswer.value = index;
    hasAnswered.value = true;
    totalQuizzes++;
    
    final correct = quizOptions[index] == currentVocab?.meaningVi;
    isAnswerCorrect.value = correct;
    
    if (correct) {
      correctCount++;
    }
  }

  void playAudio({bool slow = false}) {
    final vocab = currentVocab;
    if (vocab == null) {
      Logger.w('SessionController', 'No current vocab for audio');
      return;
    }

    Logger.d('SessionController', '=== PLAY AUDIO REQUEST ===');
    Logger.d('SessionController', 'Vocab: ${vocab.hanzi} (${vocab.id})');
    Logger.d('SessionController', 'audioUrl: ${vocab.audioUrl}');
    Logger.d('SessionController', 'audioSlowUrl: ${vocab.audioSlowUrl}');
    Logger.d('SessionController', 'Slow mode: $slow');

    final url = slow ? vocab.audioSlowUrl : vocab.audioUrl;
    
    if (url != null && url.isNotEmpty) {
      Logger.d('SessionController', 'Playing URL: $url');
      if (slow) {
        _audioService.playSlow(url);
      } else {
        _audioService.playNormal(url);
      }
      // Mark as listened for pronunciation step
      hasListenedAudio.value = true;
    } else {
      Logger.w('SessionController', 'No ${slow ? "slow" : "normal"} audio URL for vocab: ${vocab.hanzi}');
      HMToast.info('Audio ${slow ? "chậm" : ""} không khả dụng cho từ này');
    }
  }

  /// Start listening for speech recognition
  Future<void> startListening() async {
    if (_speech == null) {
      HMToast.error('Nhận dạng giọng nói không khả dụng');
      return;
    }

    if (isListening.value) {
      await stopListening();
      return;
    }

    // Reset previous results
    recognizedText.value = '';
    speechConfidence.value = 0.0;
    hasPronunciationResult.value = false;

    try {
      // Re-check if speech is available (permission might have changed)
      final available = await _speech!.initialize(
        onError: (error) {
          Logger.e('SessionController', 'Speech error: ${error.errorMsg}');
          isListening.value = false;
        },
        onStatus: (status) {
          Logger.d('SessionController', 'Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
      );
      
      if (!available) {
        HMToast.error('Vui lòng cấp quyền microphone trong Cài đặt');
        return;
      }
      
      isListening.value = true;
      
      // Use detected Chinese locale or fallback
      final localeToUse = _chineseLocaleId ?? 'zh_CN';
      Logger.d('SessionController', 'Starting listen with locale: $localeToUse');
      
      await _speech!.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          speechConfidence.value = result.confidence;
          
          Logger.d('SessionController', 
            'Speech result: "${result.recognizedWords}" (confidence: ${result.confidence})');
          
          // Auto-evaluate when speech is final
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            isListening.value = false;
            _evaluatePronunciation(result.recognizedWords);
          }
        },
        localeId: localeToUse,
        listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
        pauseFor: const Duration(seconds: 3), // Pause after 3 seconds of silence
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation, // Try dictation mode for longer input
          cancelOnError: false, // Don't cancel, let it continue
          partialResults: true,
        ),
      );
    } catch (e) {
      Logger.e('SessionController', 'Listen error', e);
      isListening.value = false;
      HMToast.error('Không thể bắt đầu nhận dạng giọng nói.\n'
          'Hãy kiểm tra quyền microphone và kết nối internet.');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_speech != null && isListening.value) {
      await _speech!.stop();
      isListening.value = false;
    }
  }

  /// Evaluate pronunciation against expected word
  Future<void> _evaluatePronunciation(String spokenText) async {
    final vocab = currentVocab;
    if (vocab == null) return;

    isEvaluatingPronunciation.value = true;

    try {
      final evaluation = await _pronunciationRepo.evaluate(
        vocabId: vocab.id,
        spokenText: spokenText,
      );
      
      pronunciationScore.value = evaluation.score;
      isPronunciationPassed.value = evaluation.passed;
      pronunciationFeedback.value = evaluation.feedback;
      hasPronunciationResult.value = true;
      
      Logger.d('SessionController', 
        'Pronunciation result: score=${pronunciationScore.value}, passed=${isPronunciationPassed.value}');
      
    } catch (e) {
      Logger.e('SessionController', 'Evaluate pronunciation error', e);
      // Fallback: simple text comparison
      _fallbackEvaluation(spokenText);
    } finally {
      isEvaluatingPronunciation.value = false;
    }
  }

  /// Fallback evaluation when API fails
  void _fallbackEvaluation(String spokenText) {
    final vocab = currentVocab;
    if (vocab == null) return;

    // Simple matching - check if spoken text contains the word or pinyin
    final hanzi = vocab.hanzi.toLowerCase();
    final pinyin = vocab.pinyin.toLowerCase().replaceAll(' ', '');
    final spoken = spokenText.toLowerCase().replaceAll(' ', '');
    
    // Check for match
    bool isMatch = spoken.contains(hanzi) || 
                   hanzi.contains(spoken) ||
                   _comparePinyin(pinyin, spoken);
    
    if (isMatch) {
      pronunciationScore.value = 80;
      isPronunciationPassed.value = true;
      pronunciationFeedback.value = 'Tốt lắm! Phát âm đúng.';
    } else {
      pronunciationScore.value = 40;
      isPronunciationPassed.value = false;
      pronunciationFeedback.value = 'Hãy thử lại. Nghe kỹ audio và phát âm theo.';
    }
    hasPronunciationResult.value = true;
  }

  /// Compare pinyin with spoken text (basic)
  bool _comparePinyin(String pinyin, String spoken) {
    // Remove tones from pinyin for comparison
    final pinyinNoTones = pinyin
        .replaceAll(RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]'), '')
        .replaceAll(RegExp(r'[1-4]'), '');
    
    return pinyinNoTones.contains(spoken) || spoken.contains(pinyinNoTones);
  }

  /// Manual pass - user confirms they pronounced correctly
  /// Requires listening to audio first
  void manualPassPronunciation() {
    if (!hasListenedAudio.value) {
      HMToast.info('Hãy nghe audio mẫu trước khi xác nhận!');
      return;
    }
    pronunciationScore.value = 70;
    isPronunciationPassed.value = true;
    pronunciationFeedback.value = 'Đã xác nhận! Tiếp tục học.';
    hasPronunciationResult.value = true;
  }

  /// Manual fail - user wants to try again
  void retryPronunciation() {
    _resetPronunciationState();
  }
  
  /// Skip pronunciation step (allowed anytime)
  void skipPronunciation() {
    nextStep();
  }

  // Last rating response for showing feedback
  final Rx<ReviewAnswerResponse?> lastRatingResponse = Rx<ReviewAnswerResponse?>(null);
  final RxBool showingRatingFeedback = false.obs;

  Future<void> submitRating(ReviewRating rating) async {
    final vocab = currentVocab;
    if (vocab == null) return;

    // Calculate time spent on this vocab
    final timeSpent = _vocabStartTime != null 
        ? DateTime.now().difference(_vocabStartTime!).inMilliseconds 
        : 5000;

    try {
      final response = await _learningRepo.submitReviewAnswer(
        vocabId: vocab.id,
        rating: rating,
        mode: _getModeString(),
        timeSpent: timeSpent,
      );
      
      // Show feedback briefly
      lastRatingResponse.value = response;
      showingRatingFeedback.value = true;
      
      Logger.d('SessionController', 
        'Rating submitted: ${rating.value}, new interval: ${response.intervalDays} days, state: ${response.state}');
      
      // Show feedback for 1 second, then move to next vocab
      await Future.delayed(const Duration(milliseconds: 800));
      showingRatingFeedback.value = false;
      
    } catch (e) {
      Logger.e('SessionController', 'submitRating error', e);
      // Don't block user flow on error
    }

    _nextVocab();
  }

  String _getModeString() {
    switch (sessionMode) {
      case SessionMode.newWords:
        return 'learn';
      case SessionMode.review:
        return 'flashcard';
      case SessionMode.reviewToday:
        return 'review_today';
      case SessionMode.game30:
        return 'game';
    }
  }

  /// Flag to prevent double-saving
  bool _sessionSaved = false;

  Future<void> _finishSession() async {
    _timer?.cancel();
    _sessionSaved = true;
    isSessionComplete.value = true;

    final seconds = elapsedSeconds.value;
    final accuracy = totalQuizzes > 0 ? correctCount / totalQuizzes : 1.0;
    
    // Calculate counts based on mode
    final sessionNewCount = sessionMode == SessionMode.newWords ? queue.length : 0;
    final sessionReviewCount = (sessionMode == SessionMode.review || sessionMode == SessionMode.reviewToday) 
        ? queue.length 
        : 0;
    
    final result = SessionResultModel(
      seconds: seconds,
      newCount: sessionNewCount,
      reviewCount: sessionReviewCount,
      accuracy: accuracy,
    );
    
    Logger.d('SessionController', 
      '[FINISH] mode=$sessionMode, newCount=$sessionNewCount, '
      'reviewCount=$sessionReviewCount, seconds=$seconds, minutes=${result.minutes}');

    try {
      await _learningRepo.finishSession(result);
      
      // Refresh all relevant controllers
      await _refreshAllData();
      
    } catch (e) {
      Logger.e('SessionController', 'finishSession error', e);
      // Still try to refresh data even if finishSession failed
      await _refreshAllData();
    }
  }
  
  /// Refresh all data in all controllers after session completes
  Future<void> _refreshAllData() async {
    try {
      await _rt.syncNowAll(force: true);
    } catch (_) {}
  }

  /// Minimum seconds before saving partial session
  static const int _minSecondsToSave = 10;

  /// Save partial session in background (fire-and-forget)
  void _savePartialSessionInBackground() {
    final seconds = elapsedSeconds.value;
    
    // Only save if meaningful time spent
    if (seconds < _minSecondsToSave) {
      Logger.d('SessionController', '[SKIP_SAVE] seconds=$seconds < $_minSecondsToSave');
      return;
    }
    
    final accuracy = totalQuizzes > 0 ? correctCount / totalQuizzes : 0.0;
    final sessionNewCount = sessionMode == SessionMode.newWords ? currentIndex.value : 0;
    final sessionReviewCount = currentIndex.value;
    
    final result = SessionResultModel(
      seconds: seconds,
      newCount: sessionNewCount,
      reviewCount: sessionReviewCount,
      accuracy: accuracy,
    );
    
    Logger.d('SessionController', 
      '[PARTIAL_SAVE] mode=$sessionMode, seconds=$seconds, minutes=${result.minutes}');
    
    // Fire and forget - don't block UI
    _learningRepo.finishSession(result).then((_) {
      _refreshAllData();
    }).catchError((e) {
      Logger.e('SessionController', 'Failed to save partial session', e);
    });
  }

  void exitSession() {
    _timer?.cancel();
    if (!_sessionSaved && !isSessionComplete.value && elapsedSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    Get.back();
  }

  /// Continue learning with fresh words from BE
  Future<void> continueSession() async {
    isLoadingMore.value = true;
    
    try {
      // Fetch fresh data from BE (should exclude already learned words)
      final today = await _learningRepo.getToday();
      
      List<VocabModel> newWords = [];
      
      switch (sessionMode) {
        case SessionMode.newWords:
          // Check remaining limit first
          if (today.remainingNewLimit <= 0) {
            HMToast.info(
              'Bạn đã học hết ${today.dailyNewLimit} từ mới hôm nay! 🎉\n'
              'Quay lại vào ngày mai hoặc tập trung ôn tập!',
            );
            Get.back();
            return;
          }
          newWords = today.newQueue.take(10).toList();
          break;
        case SessionMode.review:
          newWords = today.reviewQueue.take(10).toList();
          break;
        case SessionMode.reviewToday:
          final learnedToday = today.reviewQueue
              .where((v) => v.state == 'learning' || v.reps == 1)
              .take(10)
              .toList();
          newWords = learnedToday.isEmpty 
              ? today.reviewQueue.take(10).toList() 
              : learnedToday;
          break;
        case SessionMode.game30:
          final combined = [...today.newQueue, ...today.reviewQueue];
          combined.shuffle();
          newWords = combined.take(5).toList();
          break;
      }
      
      if (newWords.isEmpty) {
        if (sessionMode == SessionMode.newWords) {
          HMToast.info(
            'Bạn đã học hết ${today.newLearnedToday}/${today.dailyNewLimit} từ mới hôm nay! 🎉\n'
            'Quay lại vào ngày mai hoặc tập trung ôn tập!',
          );
        } else {
          HMToast.info('Không có từ nào cần ôn! 🎉');
        }
        Get.back();
        return;
      }
      
      // Reset session state
      queue.value = newWords;
      currentIndex.value = 0;
      currentStep.value = 0;
      isRevealed.value = false;
      isSessionComplete.value = false;
      hasAnswered.value = false;
      selectedAnswer.value = -1;
      
      // Reset stats for new session
      correctCount = 0;
      totalQuizzes = 0;
      
      // Restart timer
      _sessionStart = DateTime.now();
      _vocabStartTime = DateTime.now();
      elapsedSeconds.value = 0;
      
      // Pre-cache audio
      _preCacheAudio();
      
      Logger.d('SessionController', 'Continued session with ${newWords.length} new words');
      
    } catch (e) {
      Logger.e('SessionController', 'continueSession error', e);
      HMToast.error('Không thể tải thêm từ. Vui lòng thử lại.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  @override
  void onClose() {
    // Save partial session in background if not already saved
    if (!_sessionSaved && !isSessionComplete.value && elapsedSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    
    _timer?.cancel();
    _audioService.stop();
    _speech?.stop();
    _speech?.cancel();
    super.onClose();
  }
}

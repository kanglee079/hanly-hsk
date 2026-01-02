import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/models/vocab_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../services/audio_service.dart';
import '../../services/exercise_generator.dart';
import '../../services/realtime/today_store.dart';
import '../../services/storage_service.dart';
import '../../services/realtime/realtime_sync_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../shell/shell_controller.dart';

export '../../data/models/exercise_model.dart';

/// Practice mode enum
enum PracticeMode {
  learnNew, // Full learning flow for new words
  reviewSRS, // Quick SRS review (due words from past days)
  reviewToday, // Reinforce words learned TODAY
  listening, // Audio-based exercises
  matching, // Matching game
  game30s, // Speed game
  comprehensive, // Mix of all types
}

/// Practice session state
enum PracticeState {
  loading,
  learning, // Showing learning content (hanzi DNA, etc)
  exercise, // Doing exercise/quiz
  feedback, // Showing result of exercise
  pronunciation, // Pronunciation step
  rating, // SRS rating (again/hard/good/easy)
  wrongAnswerReview, // Show list of wrong answers before complete
  complete, // Session finished
}

/// Controller for practice/learning sessions
class PracticeController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  final ExerciseGenerator _exerciseGenerator = ExerciseGenerator();
  final StorageService _storage = Get.find<StorageService>();
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();

  // Local date key for caching learn-new completion (YYYY-MM-DD)
  final String _todayKey = _formatDateKey(DateTime.now());

  // LearnNew: keep local completed set as a safety net (prevents repeats on "Học tiếp")
  final Set<String> _learnNewCompletedVocabIds = <String>{};
  final Map<String, int> _learnNewCorrectByVocab = <String, int>{};
  final Map<String, int> _learnNewTotalByVocab = <String, int>{};
  final Map<String, int> _learnNewTimeSpentMsByVocab = <String, int>{};

  /// Track count at session START to calculate delta (words learned in THIS session only)
  int _sessionStartLearnedCount = 0;

  /// Track vocab IDs learned specifically in THIS session
  final Set<String> _thisSessionLearnedVocabIds = <String>{};

  // Session configuration
  late PracticeMode mode;
  late SessionConfig config;

  // Vocabulary
  final RxList<VocabModel> vocabs = <VocabModel>[].obs;
  final RxInt currentVocabIndex = 0.obs;

  // Exercises
  final RxList<Exercise> exercises = <Exercise>[].obs;
  final RxInt currentExerciseIndex = 0.obs;

  // State
  final Rx<PracticeState> state = PracticeState.loading.obs;
  final RxBool isLoading = true.obs;

  // Current exercise state
  final RxInt selectedAnswer = (-1).obs;
  final RxBool hasAnswered = false.obs;
  final RxBool isCorrect = false.obs;
  final RxBool showCorrectAnswer = false.obs;

  // For matching game
  final RxList<int> matchedLeft = <int>[].obs;
  final RxList<int> matchedRight = <int>[].obs;
  final RxInt selectedLeft = (-1).obs;
  final RxInt selectedRight = (-1).obs;
  final RxBool showWrongMatch = false.obs; // For wrong match animation
  final RxInt wrongLeft = (-1).obs;
  final RxInt wrongRight = (-1).obs;
  // Track wrong attempts for review screen
  final RxList<Map<String, dynamic>> wrongMatchAttempts =
      <Map<String, dynamic>>[].obs;

  // Timer
  final RxInt elapsedSeconds = 0.obs;
  final RxInt remainingSeconds = 0.obs;
  Timer? _timer;
  DateTime? _exerciseStart;

  // Stats
  final RxInt correctCount = 0.obs;
  final RxInt totalExercises = 0.obs;
  final RxInt xpEarned = 0.obs;
  final RxInt streak = 0.obs; // Consecutive correct answers

  // Learning content visibility
  final RxBool showHanziDna = false.obs;
  final RxBool showContext = false.obs;
  final RxBool showMnemonic = false.obs;

  // Pronunciation
  stt.SpeechToText? _speech;
  final RxBool isListening = false.obs;
  final RxBool hasPronunciationResult = false.obs;
  final RxInt pronunciationScore = 0.obs;
  final RxBool isPronunciationPassed = false.obs;

  // TTS (for example sentences)
  FlutterTts? _tts;
  final RxBool isSpeaking = false.obs;
  final Rx<String?> speakingText = Rx<String?>(null);

  // Audio state
  final RxBool isPlayingAudio = false.obs;
  final RxBool hasPlayedAudio = false.obs;

  // Feedback snapshot (prevents "đúng -> sai" flicker when advancing)
  final RxBool lastAnswerCorrect = false.obs;
  final RxString lastCorrectAnswerDisplay = ''.obs;
  final RxInt lastXpAwarded = 0.obs;

  Exercise? get currentExercise =>
      exercises.isNotEmpty && currentExerciseIndex.value < exercises.length
      ? exercises[currentExerciseIndex.value]
      : null;

  /// Get the VocabModel for the current exercise
  /// ALWAYS derives from currentExercise.vocabId to ensure audio/display match
  VocabModel? get currentVocab {
    // First try to get vocab from current exercise's vocabId
    final exercise = currentExercise;
    if (exercise != null) {
      final vocab = getVocabById(exercise.vocabId);
      if (vocab != null) return vocab;
    }

    // Fallback to index-based lookup (for learning state before exercises start)
    if (vocabs.isNotEmpty && currentVocabIndex.value < vocabs.length) {
      return vocabs[currentVocabIndex.value];
    }

    return null;
  }

  /// Alias for clarity - same as currentVocab
  VocabModel? get vocabForCurrentExercise => currentVocab;

  /// Find vocab by ID from the loaded vocabs list
  VocabModel? getVocabById(String vocabId) {
    try {
      return vocabs.firstWhere((v) => v.id == vocabId);
    } catch (_) {
      Logger.w('PracticeController', 'Vocab not found: $vocabId');
      return null;
    }
  }

  double get progress {
    if (exercises.isEmpty) return 0;
    return (currentExerciseIndex.value + 1) / exercises.length;
  }

  int get accuracy {
    if (totalExercises.value == 0) return 100;
    return ((correctCount.value / totalExercises.value) * 100).round();
  }

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    _initLearnNewLocalProgress();
    _initSpeech();
    _initTts();
    _loadSession();
  }

  void _parseArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    mode = _parsePracticeMode(args?['mode']) ?? PracticeMode.learnNew;

    // Get config based on mode
    switch (mode) {
      case PracticeMode.learnNew:
        config = SessionConfig.learnNew;
        break;
      case PracticeMode.reviewSRS:
        config = SessionConfig.reviewSRS;
        break;
      case PracticeMode.reviewToday:
        // Củng cố từ vừa học hôm nay - dùng config giống SRS nhưng load từ khác
        config = SessionConfig.reviewSRS;
        break;
      case PracticeMode.listening:
        config = SessionConfig.listeningPractice;
        break;
      case PracticeMode.matching:
        config = SessionConfig.matchingGame;
        break;
      case PracticeMode.game30s:
        config = SessionConfig.game30s;
        break;
      case PracticeMode.comprehensive:
        config = SessionConfig(
          id: 'comprehensive',
          name: 'Ôn tập tổng hợp',
          description: 'Kết hợp tất cả loại bài tập',
          exerciseTypes: [
            ExerciseType.hanziToMeaning,
            ExerciseType.meaningToHanzi,
            ExerciseType.audioToHanzi,
            ExerciseType.hanziToPinyin,
          ],
          vocabCount: 15,
          exercisesPerVocab: 2,
        );
        break;
    }

    // Check if vocabs were passed directly
    if (args?['vocabs'] != null) {
      vocabs.value = args!['vocabs'] as List<VocabModel>;
    }
  }

  /// Parse PracticeMode from various input types (String or PracticeMode)
  PracticeMode? _parsePracticeMode(dynamic value) {
    if (value == null) return null;

    // Already a PracticeMode
    if (value is PracticeMode) return value;

    // String - parse it
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'learnnew':
        case 'learn_new':
          return PracticeMode.learnNew;
        case 'reviewsrs':
        case 'review_srs':
        case 'review':
          return PracticeMode.reviewSRS;
        case 'listening':
          return PracticeMode.listening;
        case 'matching':
          return PracticeMode.matching;
        case 'game30s':
        case 'game_30s':
          return PracticeMode.game30s;
        case 'comprehensive':
          return PracticeMode.comprehensive;
        default:
          Logger.w('PracticeController', 'Unknown practice mode: $value');
          return PracticeMode.learnNew;
      }
    }

    return null;
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      await _speech!.initialize();
    } catch (e) {
      Logger.e('PracticeController', 'Speech init error', e);
    }
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('zh-CN');
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
        Logger.e('PracticeController', 'TTS error: $msg');
      });
    } catch (e) {
      Logger.w('PracticeController', 'TTS init failed: $e');
      _tts = null;
    }
  }

  // Track if no data available
  final RxBool hasNoData = false.obs;
  final RxString noDataMessage = ''.obs;

  Future<void> _loadSession() async {
    isLoading.value = true;
    state.value = PracticeState.loading;
    hasNoData.value = false;

    try {
      // Load vocabs if not provided
      if (vocabs.isEmpty) {
        final today = await _learningRepo.getToday();

        switch (mode) {
          case PracticeMode.learnNew:
            // 🚨 CHECK 1: API says new queue is LOCKED
            if (today.isNewQueueLocked) {
              hasNoData.value = true;
              if (today.isBlockedByReviewOverload) {
                final info = today.reviewOverloadInfo;
                noDataMessage.value =
                    '⚠️ ${info?.message ?? "Có ${today.reviewQueue.length} từ cần ôn tập!"}\n\n'
                    'Hãy ôn tập để tiếp tục học từ mới.';
              } else if (today.isBlockedByMastery) {
                final req = today.unlockRequirement;
                noDataMessage.value =
                    '🎯 ${req?.message ?? "Cần master từ đã học!"}\n\n'
                    'Hãy ôn tập để master ${req?.wordsToMaster ?? 0} từ còn lại.';
              } else {
                noDataMessage.value =
                    '⚠️ Chưa thể học từ mới.\n\n${today.lockMessage}';
              }
              isLoading.value = false;
              return;
            }

            // CHECK 2: Check daily limit - dùng cả BE và local cache
            final localLearnedCount = _learnNewCompletedVocabIds.length;
            final beLearnedCount = today.newLearnedToday;
            final actualLearned = localLearnedCount > beLearnedCount
                ? localLearnedCount
                : beLearnedCount;
            final actualRemaining = today.dailyNewLimit - actualLearned;

            if (actualRemaining <= 0) {
              hasNoData.value = true;
              noDataMessage.value =
                  'Bạn đã học đủ ${today.dailyNewLimit} từ mới hôm nay! 🎉\n\nNâng cấp Premium để học không giới hạn!';
              isLoading.value = false;
              return;
            }
            // Filter out words already completed today (local cache)
            final available = today.newQueue
                .where((v) => !_learnNewCompletedVocabIds.contains(v.id))
                .toList();
            // Chỉ lấy số từ còn lại trong quota
            final toTake = actualRemaining < config.vocabCount
                ? actualRemaining
                : config.vocabCount;
            vocabs.value = available.take(toTake).toList();
            break;
          case PracticeMode.reviewSRS:
            vocabs.value = today.reviewQueue.take(config.vocabCount).toList();
            break;
          case PracticeMode.reviewToday:
            // Củng cố từ vừa học hôm nay
            // Chế độ này CHỈ ôn lại từ đã học trong phiên học mới,
            // KHÔNG phải học thêm từ mới

            // 1. Thử lấy full vocab từ local storage (ưu tiên vì có đủ thông tin)
            final storedVocabsJson = _storage.getLearnNewVocabs(_todayKey);
            if (storedVocabsJson.isNotEmpty) {
              final storedVocabs = storedVocabsJson
                  .map((json) => VocabModel.fromJson(json))
                  .toList();
              vocabs.value = storedVocabs.take(config.vocabCount).toList();
              Logger.d(
                'PracticeController',
                '🧠 ReviewToday: loaded ${vocabs.length} vocabs from local storage',
              );
              break;
            }

            // 2. Nếu local storage trống (sau logout/login lại),
            // thông báo cần học từ mới trước
            // KHÔNG lấy từ BE vì không có đủ thông tin để ôn tập
            hasNoData.value = true;
            noDataMessage.value =
                'Bạn đã hoàn thành mục tiêu hôm nay! 🎉\n\nHãy quay lại ngày mai để học tiếp.';
            isLoading.value = false;
            return;
          case PracticeMode.listening:
          case PracticeMode.matching:
          case PracticeMode.comprehensive:
            final combined = [...today.reviewQueue, ...today.newQueue];
            combined.shuffle();
            vocabs.value = combined.take(config.vocabCount).toList();
            break;
          case PracticeMode.game30s:
            // Game 30s CHỈ dùng từ đã học (reviewQueue) - không dùng từ mới
            // Vì game này để test kiến thức đã có, không phải học mới
            final learnedVocabs = [...today.reviewQueue];
            if (learnedVocabs.isEmpty) {
              hasNoData.value = true;
              noDataMessage.value =
                  'Bạn cần học từ mới trước!\n\nGame 30s chỉ dùng từ bạn đã học.';
              isLoading.value = false;
              return;
            }
            learnedVocabs.shuffle();
            vocabs.value = learnedVocabs.take(20).toList();
            break;
        }
      }

      if (vocabs.isEmpty) {
        hasNoData.value = true;
        noDataMessage.value = _getEmptyMessage();
        isLoading.value = false;
        return;
      }

      // For learnNew mode: preserve vocab order from API (no shuffle)
      // For other modes: shuffle for variety
      final shouldPreserveOrder = mode == PracticeMode.learnNew;

      // Generate exercises
      if (mode == PracticeMode.matching) {
        // Special handling for matching game
        exercises.add(_exerciseGenerator.generateMatchingExercise(vocabs));
      } else {
        exercises.value = _exerciseGenerator.generateExercises(
          vocabs: vocabs,
          config: config,
          allVocabs: vocabs,
          preserveOrder: shouldPreserveOrder,
        );
      }

      // Check if exercises were generated
      if (exercises.isEmpty) {
        hasNoData.value = true;
        noDataMessage.value = 'Không thể tạo bài tập. Vui lòng thử lại.';
        isLoading.value = false;
        return;
      }

      // Debug: Log exercise order to verify
      Logger.d(
        'PracticeController',
        '📚 Generated ${exercises.length} exercises (preserveOrder: $shouldPreserveOrder):',
      );
      for (int i = 0; i < exercises.length && i < 5; i++) {
        final ex = exercises[i];
        final vocab = getVocabById(ex.vocabId);
        final audioPreview =
            ex.questionAudioUrl != null && ex.questionAudioUrl!.length > 30
            ? '${ex.questionAudioUrl!.substring(0, 30)}...'
            : ex.questionAudioUrl ?? 'null';
        Logger.d(
          'PracticeController',
          '  [$i] ${ex.type.name}: ${vocab?.hanzi ?? ex.vocabId} (audio: $audioPreview)',
        );
      }

      // Pre-cache audio
      _preCacheAudio();

      // Start timer
      _startTimer();

      // Start session
      if (config.showLearningContent && mode == PracticeMode.learnNew) {
        state.value = PracticeState.learning;
      } else {
        state.value = PracticeState.exercise;
      }
    } catch (e) {
      Logger.e('PracticeController', 'Load session error', e);
      hasNoData.value = true;
      noDataMessage.value = 'Không thể tải dữ liệu. Vui lòng thử lại.';
    } finally {
      isLoading.value = false;
    }
  }

  String _getEmptyMessage() {
    switch (mode) {
      case PracticeMode.learnNew:
        return 'Không có từ mới để học.\nHãy kiểm tra cấp độ HSK trong cài đặt!';
      case PracticeMode.reviewSRS:
        return 'Tuyệt vời! Không có từ nào cần ôn tập! 🎉';
      case PracticeMode.reviewToday:
        return 'Chưa có từ nào được học hôm nay!\nHãy học từ mới trước nhé.';
      case PracticeMode.listening:
        return 'Không có từ vựng để luyện nghe.';
      case PracticeMode.matching:
        return 'Không có từ vựng để chơi ghép từ.';
      case PracticeMode.game30s:
        return 'Không có từ vựng để chơi.';
      case PracticeMode.comprehensive:
        return 'Không có từ vựng để ôn tập tổng hợp.';
    }
  }

  void _preCacheAudio() {
    final urls = <String>[];
    for (final vocab in vocabs) {
      if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty) {
        urls.add(vocab.audioUrl!);
      }
    }
    if (urls.isNotEmpty) {
      _audioService.preCacheAudio(urls);
    }
  }

  void _startTimer() {
    _exerciseStart = DateTime.now();
    elapsedSeconds.value = 0;

    if (config.timeLimit > 0) {
      remainingSeconds.value = config.timeLimit;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsedSeconds.value++;
        remainingSeconds.value--;

        if (remainingSeconds.value <= 0) {
          _finishSession();
        }
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsedSeconds.value++;
      });
    }
  }

  // ========== LEARNING FLOW ==========

  /// Show learning content for current vocab
  void showLearningContent() {
    showHanziDna.value = true;
    showContext.value = true;
    showMnemonic.value = true;
  }

  /// Continue to exercises after learning
  void continueToExercise() {
    state.value = PracticeState.exercise;
    _exerciseStart = DateTime.now();
  }

  /// Proceed from wrong answer review to complete screen
  void continueToComplete() {
    state.value = PracticeState.complete;
  }

  // ========== EXERCISE HANDLING ==========

  /// Select answer for MCQ
  void selectAnswer(int index) {
    if (hasAnswered.value) return;

    selectedAnswer.value = index;
    hasAnswered.value = true;
    _exerciseStart ??= DateTime.now();

    final exercise = currentExercise;
    if (exercise == null) return;

    isCorrect.value = exercise.checkAnswer(index);
    totalExercises.value++;

    // Snapshot for feedback UI
    lastAnswerCorrect.value = isCorrect.value;
    lastCorrectAnswerDisplay.value = exercise.correctAnswerDisplay;

    if (isCorrect.value) {
      correctCount.value++;
      streak.value++;
      xpEarned.value += exercise.xpReward * config.xpMultiplier;
      lastXpAwarded.value = exercise.xpReward * config.xpMultiplier;
      // Haptic feedback for correct answer
      HapticFeedback.mediumImpact();
    } else {
      streak.value = 0;
      showCorrectAnswer.value = true;
      lastXpAwarded.value = 0;
      // Haptic feedback for incorrect answer
      HapticFeedback.heavyImpact();
    }

    // LearnNew: track per-vocab performance to auto-submit progress at end of word
    if (mode == PracticeMode.learnNew) {
      final vocabId = exercise.vocabId;
      _learnNewTotalByVocab[vocabId] =
          (_learnNewTotalByVocab[vocabId] ?? 0) + 1;
      if (isCorrect.value) {
        _learnNewCorrectByVocab[vocabId] =
            (_learnNewCorrectByVocab[vocabId] ?? 0) + 1;
      }
      final spent = _exerciseStart != null
          ? DateTime.now().difference(_exerciseStart!).inMilliseconds
          : 3000;
      _learnNewTimeSpentMsByVocab[vocabId] =
          (_learnNewTimeSpentMsByVocab[vocabId] ?? 0) + spent;
    }

    // For Game 30s, auto-advance after short delay
    if (mode == PracticeMode.game30s) {
      Future.delayed(const Duration(milliseconds: 300), () {
        nextExercise();
      });
    }
    // For other modes: stay in exercise state for inline feedback
    // The exercise widget will show the continue button
  }

  /// Handle matching game selection
  void selectMatchingItem({required bool isLeft, required int index}) {
    if (matchedLeft.contains(index) && isLeft) return;
    if (matchedRight.contains(index) && !isLeft) return;

    if (isLeft) {
      selectedLeft.value = index;
    } else {
      selectedRight.value = index;
    }

    // Check if both selected
    if (selectedLeft.value >= 0 && selectedRight.value >= 0) {
      _checkMatchingPair();
    }
  }

  void _checkMatchingPair() {
    final exercise = currentExercise;
    if (exercise == null || exercise.matchingItems == null) return;

    final leftIdx = selectedLeft.value;
    final rightIdx = selectedRight.value;

    // Find if this is a correct match
    final isMatch = exercise.matchingItems!.any(
      (item) => item.leftIndex == leftIdx && item.rightIndex == rightIdx,
    );

    if (isMatch) {
      // Correct match - add to matched lists
      matchedLeft.add(leftIdx);
      matchedRight.add(rightIdx);
      correctCount.value++;
      xpEarned.value += 5;
      streak.value++;
      HapticFeedback.mediumImpact();

      // Reset selection immediately for correct match
      selectedLeft.value = -1;
      selectedRight.value = -1;
    } else {
      // Wrong match - show visual feedback and track for review
      streak.value = 0;
      wrongLeft.value = leftIdx;
      wrongRight.value = rightIdx;
      showWrongMatch.value = true;
      HapticFeedback.heavyImpact();

      // Track wrong attempt with actual text for review
      final leftItem = exercise.matchingItems!.firstWhere(
        (i) => i.leftIndex == leftIdx,
      );
      final rightItem = exercise.matchingItems!.firstWhere(
        (i) => i.rightIndex == rightIdx,
      );
      final correctRightItem = exercise.matchingItems!.firstWhere(
        (i) => i.leftIndex == leftIdx,
      );

      wrongMatchAttempts.add({
        'selectedHanzi': leftItem.leftText,
        'selectedMeaning': rightItem.rightText,
        'correctMeaning': correctRightItem.rightText,
        'correctHanzi': correctRightItem.leftText,
      });

      // Reset after animation delay
      Future.delayed(const Duration(milliseconds: 600), () {
        showWrongMatch.value = false;
        wrongLeft.value = -1;
        wrongRight.value = -1;
        selectedLeft.value = -1;
        selectedRight.value = -1;
      });
    }

    totalExercises.value++;

    // Check if all matched
    if (matchedLeft.length >= (exercise.matchingItems?.length ?? 0)) {
      // Stop timer when matching is complete
      _timer?.cancel();

      // Small delay before showing next state
      Future.delayed(const Duration(milliseconds: 400), () {
        // If there are wrong attempts, show review first
        if (wrongMatchAttempts.isNotEmpty) {
          state.value = PracticeState.wrongAnswerReview;
        } else {
          state.value = PracticeState.complete;
        }
      });
    }
  }

  /// Move to next exercise
  Future<void> nextExercise() async {
    // If this mode uses SRS rating, show rating step AFTER feedback (do not advance yet)
    if (config.useSRSRating && state.value == PracticeState.feedback) {
      state.value = PracticeState.rating;
      return;
    }

    // Stop any playing audio before transitioning
    await stopAudio();

    final prevExercise = currentExercise;

    // Reset state
    selectedAnswer.value = -1;
    hasAnswered.value = false;
    isCorrect.value = false;
    showCorrectAnswer.value = false;
    hasPlayedAudio.value = false;
    isPlayingAudio.value = false;
    _exerciseStart = DateTime.now();

    final nextIndex = currentExerciseIndex.value + 1;
    if (nextIndex < exercises.length) {
      final nextEx = exercises[nextIndex];

      // LearnNew: structured pipeline per vocab
      // After finishing all exercises of vocab A, show learning content for vocab B
      if (mode == PracticeMode.learnNew &&
          config.showLearningContent &&
          prevExercise != null &&
          nextEx.vocabId != prevExercise.vocabId) {
        await _completeLearnNewWord(prevExercise.vocabId);
        currentExerciseIndex.value = nextIndex;
        state.value = PracticeState.learning;
        return;
      }

      currentExerciseIndex.value = nextIndex;

      // Optional pronunciation step between vocab groups (for configs that enable it)
      if (config.showPronunciation &&
          currentExerciseIndex.value > 0 &&
          currentExerciseIndex.value % config.exercisesPerVocab == 0) {
        state.value = PracticeState.pronunciation;
      } else {
        state.value = PracticeState.exercise;
      }
      return;
    }

    // End of session: complete last learnNew word (if any) then finish
    if (mode == PracticeMode.learnNew && prevExercise != null) {
      await _completeLearnNewWord(prevExercise.vocabId);
    }
    await _finishSession();
  }

  /// Skip current exercise
  void skipExercise() {
    totalExercises.value++;
    streak.value = 0;
    nextExercise();
  }

  // ========== AUDIO ==========

  /// Unique ID to track current playback request and cancel stale ones
  int _audioRequestId = 0;

  /// Play audio for the CURRENT EXERCISE (not currentVocab which may differ!)
  ///
  /// Key fix: Uses exercise's embedded audio URLs, not currentVocab's
  /// Fallback logic for slow audio:
  /// 1. Use exercise.questionSlowAudioUrl if available
  /// 2. Otherwise use exercise.questionAudioUrl at 0.75x speed
  Future<void> playAudio({bool slow = false}) async {
    final exercise = currentExercise;
    final requestId = ++_audioRequestId;

    // Determine correct audio URL
    String? url;
    double speed = 1.0;

    if (exercise != null) {
      // Use exercise's embedded audio URLs (correct vocab's audio)
      if (slow) {
        if (exercise.questionSlowAudioUrl != null &&
            exercise.questionSlowAudioUrl!.isNotEmpty) {
          // Use native slow audio
          url = exercise.questionSlowAudioUrl;
          speed = 1.0;
        } else if (exercise.questionAudioUrl != null &&
            exercise.questionAudioUrl!.isNotEmpty) {
          // Fallback: use normal audio at slow speed
          url = exercise.questionAudioUrl;
          speed = 0.75;
        }
      } else {
        url = exercise.questionAudioUrl;
        speed = 1.0;
      }

      Logger.d(
        'PracticeController',
        '🔊 Audio request: vocabId=${exercise.vocabId}, slow=$slow, url=$url',
      );
    } else {
      // Fallback to currentVocab (for learning content state)
      final vocab = currentVocab;
      if (vocab != null) {
        if (slow) {
          if (vocab.audioSlowUrl != null && vocab.audioSlowUrl!.isNotEmpty) {
            url = vocab.audioSlowUrl;
            speed = 1.0;
          } else if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty) {
            url = vocab.audioUrl;
            speed = 0.75;
          }
        } else {
          url = vocab.audioUrl;
          speed = 1.0;
        }
        Logger.d(
          'PracticeController',
          '🔊 Audio (vocab fallback): vocabId=${vocab.id}, slow=$slow, url=$url',
        );
      }
    }

    if (url == null || url.isEmpty) {
      Logger.w('PracticeController', '⚠️ No audio URL available');
      HMToast.info(ToastMessages.practiceAudioUnavailable);
      return;
    }

    // Stop any current playback first
    await _audioService.stop();

    // Check if this request is still valid (user hasn't moved to next exercise)
    if (requestId != _audioRequestId) {
      Logger.d('PracticeController', '⏹️ Audio request cancelled (stale)');
      return;
    }

    isPlayingAudio.value = true;
    hasPlayedAudio.value = true;

    // Play with appropriate speed
    await _audioService.play(url, speed: speed);

    // Listen to audio completion
    _listenToAudioCompletion(requestId);
  }

  /// Listen for audio completion and reset state
  void _listenToAudioCompletion(int requestId) {
    // Check periodically if audio stopped
    Future.delayed(const Duration(milliseconds: 500), () {
      if (requestId != _audioRequestId) return; // Stale request

      if (!_audioService.isPlaying.value && !_audioService.isLoading.value) {
        isPlayingAudio.value = false;
      } else {
        _listenToAudioCompletion(requestId); // Keep checking
      }
    });
  }

  /// Play normal speed audio
  void playNormalAudio() => playAudio(slow: false);

  /// Play slow speed audio
  void playSlowAudio() => playAudio(slow: true);

  /// Stop current audio playback
  Future<void> stopAudio() async {
    _audioRequestId++; // Invalidate any pending playback
    await _audioService.stop();
    isPlayingAudio.value = false;

    // Stop TTS if speaking
    try {
      await _tts?.stop();
    } catch (_) {}
    isSpeaking.value = false;
    speakingText.value = null;
  }

  /// Play example sentence audio (prefer audioUrl; fallback to TTS)
  Future<void> playExampleSentence({
    required String text,
    String? audioUrl,
    bool slow = false,
  }) async {
    if (text.isEmpty) return;

    // Stop any other audio first (prevents overlap/mismatch)
    await stopAudio();

    // Prefer recorded audio if available
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _audioService.play(audioUrl, speed: slow ? 0.75 : 1.0);
      return;
    }

    // Fallback to TTS
    if (_tts == null) {
      HMToast.info(ToastMessages.practiceExampleAudioUpdating);
      return;
    }

    // Toggle: if speaking same text, stop
    if (speakingText.value == text && isSpeaking.value) {
      await _tts?.stop();
      isSpeaking.value = false;
      speakingText.value = null;
      return;
    }

    // Stop current speech if any
    if (isSpeaking.value) {
      await _tts?.stop();
    }

    try {
      speakingText.value = text;
      // Slightly slower for learning
      await _tts?.setSpeechRate(slow ? 0.30 : 0.42);
      await _tts?.speak(text);
    } catch (e) {
      Logger.e('PracticeController', 'playExampleSentence error', e);
      speakingText.value = null;
      HMToast.info(ToastMessages.practiceTtsNotReady);
    }
  }

  // ========== PRONUNCIATION ==========

  Future<void> startListening() async {
    if (_speech == null || isListening.value) return;

    isListening.value = true;
    hasPronunciationResult.value = false;

    try {
      await _speech!.listen(
        onResult: (result) {
          if (result.finalResult) {
            _evaluatePronunciation(result.recognizedWords);
          }
        },
        localeId: 'zh_CN',
        listenFor: const Duration(seconds: 5),
      );
    } catch (e) {
      Logger.e('PracticeController', 'Listen error', e);
      isListening.value = false;
    }
  }

  void _evaluatePronunciation(String spoken) {
    isListening.value = false;
    final vocab = currentVocab;
    if (vocab == null) return;

    // Simple evaluation
    final match = spoken.contains(vocab.hanzi) || vocab.hanzi.contains(spoken);

    pronunciationScore.value = match ? 80 : 40;
    isPronunciationPassed.value = match;
    hasPronunciationResult.value = true;

    if (match) {
      xpEarned.value += 10;
    }
  }

  void skipPronunciation() {
    hasPronunciationResult.value = false;
    state.value = config.useSRSRating
        ? PracticeState.rating
        : PracticeState.exercise;
    nextExercise();
  }

  void continuePronunciation() {
    state.value = config.useSRSRating
        ? PracticeState.rating
        : PracticeState.exercise;
    nextExercise();
  }

  // ========== SRS RATING ==========

  Future<void> submitRating(ReviewRating rating) async {
    final vocab = currentVocab;
    if (vocab == null) {
      await nextExercise();
      return;
    }

    try {
      await _learningRepo.submitReviewAnswer(
        vocabId: vocab.id,
        rating: rating,
        mode: 'flashcard',
        timeSpent: _exerciseStart != null
            ? DateTime.now().difference(_exerciseStart!).inMilliseconds
            : 3000,
      );
    } catch (e) {
      Logger.e('PracticeController', 'Submit rating error', e);
    }

    await nextExercise();
  }

  // ========== SESSION MANAGEMENT ==========

  Future<void> _finishSession() async {
    _timer?.cancel();
    state.value = PracticeState.complete;

    // 🔧 FIX: Only count words learned IN THIS SESSION, not cumulative total
    // Before fix: used _learnNewCompletedVocabIds.length (cumulative today)
    // After fix: use _thisSessionLearnedVocabIds.length (only this session)
    final sessionNewCount = mode == PracticeMode.learnNew
        ? _thisSessionLearnedVocabIds
              .length // Only THIS session's new words
        : 0;
    final sessionReviewCount =
        (mode == PracticeMode.reviewSRS || mode == PracticeMode.reviewToday)
        ? vocabs.length
        : 0;

    final minutes = (elapsedSeconds.value / 60).ceil();

    Logger.d(
      'PracticeController',
      '[FINISH] mode=$mode, '
          'thisSessionNew=${_thisSessionLearnedVocabIds.length}, '
          'totalToday=${_learnNewCompletedVocabIds.length}, '
          'newCount=$sessionNewCount, '
          'reviewCount=$sessionReviewCount, '
          'minutes=$minutes',
    );

    try {
      // 1. Send data to BE
      await _learningRepo.finishSession(
        SessionResultModel(
          minutes: minutes,
          newCount: sessionNewCount,
          reviewCount: sessionReviewCount,
          accuracy: totalExercises.value > 0
              ? correctCount.value / totalExercises.value
              : 1.0,
        ),
      );

      // 2. ⏳ WAIT for BE to commit transaction (Critical for sync)
      await Future.delayed(const Duration(milliseconds: 300));

      // 3. Force sync fresh data from BE
      await _rt.syncNowKeys(const [
        'today',
        'todayForecast',
        'learnedToday',
        'studyModes',
      ], force: true);

      // 4. Broadcast event to update UI immediately
      if (Get.isRegistered<TodayStore>()) {
        Get.find<TodayStore>().onLearnedUpdate.value++;
      }
    } catch (e) {
      Logger.e('PracticeController', 'Finish session error', e);
      // Even on error, try to sync to get latest state
      unawaited(
        _rt.syncNowKeys(const [
          'today',
          'todayForecast',
          'learnedToday',
          'studyModes',
        ], force: true),
      );
    }
  }

  void exitSession() {
    _timer?.cancel();
    stopAudio(); // stop audio + TTS
    Get.back();
  }

  /// Continue with more exercises
  Future<void> continueSession() async {
    isLoading.value = true;

    try {
      final today = await _learningRepo.getToday();

      List<VocabModel> newVocabs = [];
      switch (mode) {
        case PracticeMode.learnNew:
          // 🚨 CHECK 1: API says new queue is LOCKED
          if (today.isNewQueueLocked) {
            if (today.isBlockedByReviewOverload) {
              final count = today.reviewQueue.length;
              HMToast.warning(ToastMessages.reviewOverload(count));
            } else if (today.isBlockedByMastery) {
              final wordsToMaster = today.unlockRequirement?.wordsToMaster ?? 0;
              HMToast.warning(ToastMessages.masteryRequired(wordsToMaster));
            } else {
              HMToast.warning(ToastMessages.newWordsLocked);
            }
            return;
          }

          // CHECK 2: Check daily limit - dùng cả BE và local cache
          final localLearnedCount = _learnNewCompletedVocabIds.length;
          final beLearnedCount = today.newLearnedToday;
          final actualLearned = localLearnedCount > beLearnedCount
              ? localLearnedCount
              : beLearnedCount;
          final actualRemaining = today.dailyNewLimit - actualLearned;

          if (actualRemaining <= 0) {
            HMToast.info(ToastMessages.practiceNoNewWordsToday);
            return;
          }
          final available = today.newQueue
              .where((v) => !_learnNewCompletedVocabIds.contains(v.id))
              .toList();
          final toTake = actualRemaining < config.vocabCount
              ? actualRemaining
              : config.vocabCount;
          newVocabs = available.take(toTake).toList();
          break;
        case PracticeMode.reviewSRS:
          newVocabs = today.reviewQueue.take(config.vocabCount).toList();
          break;
        case PracticeMode.reviewToday:
          // Củng cố: lấy từ đã học hôm nay từ local cache
          final learnedIds = _learnNewCompletedVocabIds.toList();
          final allVocabs = [...today.newQueue, ...today.reviewQueue];
          newVocabs = allVocabs
              .where((v) => learnedIds.contains(v.id))
              .take(config.vocabCount)
              .toList();
          break;
        default:
          final combined = [...today.reviewQueue, ...today.newQueue];
          combined.shuffle();
          newVocabs = combined.take(config.vocabCount).toList();
      }

      if (newVocabs.isEmpty) {
        HMToast.info(
          mode == PracticeMode.learnNew
              ? ToastMessages.practiceNoNewWordsAvailable
              : 'Không còn từ vựng để học!',
        );
        return;
      }

      // Reset session
      vocabs.value = newVocabs;
      currentVocabIndex.value = 0;
      currentExerciseIndex.value = 0;
      correctCount.value = 0;
      totalExercises.value = 0;
      streak.value = 0;
      matchedLeft.clear();
      matchedRight.clear();
      wrongMatchAttempts.clear();

      // Reset learnNew stats for this batch (keep completed set)
      _learnNewCorrectByVocab.clear();
      _learnNewTotalByVocab.clear();
      _learnNewTimeSpentMsByVocab.clear();

      // Generate new exercises
      if (mode == PracticeMode.matching) {
        exercises.value = [_exerciseGenerator.generateMatchingExercise(vocabs)];
      } else {
        final shouldPreserveOrder = mode == PracticeMode.learnNew;
        exercises.value = _exerciseGenerator.generateExercises(
          vocabs: vocabs,
          config: config,
          allVocabs: vocabs,
          preserveOrder: shouldPreserveOrder,
        );
      }

      _preCacheAudio();

      // Restart timer (it was cancelled on complete)
      _timer?.cancel();
      _startTimer();

      state.value = config.showLearningContent
          ? PracticeState.learning
          : PracticeState.exercise;
    } catch (e) {
      Logger.e('PracticeController', 'Continue session error', e);
      HMToast.error(ToastMessages.practiceLoadMoreError);
    } finally {
      isLoading.value = false;
    }
  }

  void _initLearnNewLocalProgress() {
    // Load cho cả learnNew VÀ reviewToday (củng cố)
    if (mode != PracticeMode.learnNew && mode != PracticeMode.reviewToday)
      return;
    try {
      final cached = _storage.getLearnNewCompletedVocabIds(_todayKey);
      _learnNewCompletedVocabIds.addAll(cached);

      // 🔧 FIX: Record the count at session START to calculate delta later
      _sessionStartLearnedCount = _learnNewCompletedVocabIds.length;
      _thisSessionLearnedVocabIds.clear(); // Reset for this session

      Logger.d(
        'PracticeController',
        '🧠 LearnNew local completed today: ${_learnNewCompletedVocabIds.length} vocabs '
            '(session starts with: $_sessionStartLearnedCount)',
      );
    } catch (e) {
      Logger.e(
        'PracticeController',
        'Failed to load LearnNew local progress',
        e,
      );
    }
  }

  Future<void> _completeLearnNewWord(String vocabId) async {
    if (vocabId.isEmpty) return;
    if (_learnNewCompletedVocabIds.contains(vocabId)) return;

    _learnNewCompletedVocabIds.add(vocabId);
    _thisSessionLearnedVocabIds.add(
      vocabId,
    ); // 🔧 FIX: Track this session's words
    _storage.addLearnNewCompletedVocabId(_todayKey, vocabId);

    // Lưu full vocab data để dùng cho củng cố (reviewToday)
    final vocab = vocabs.firstWhereOrNull((v) => v.id == vocabId);
    if (vocab != null) {
      _storage.addLearnNewVocab(_todayKey, vocab.toJson());
    }

    // Auto-submit SRS update (so BE removes it from /today.newQueue)
    final total = _learnNewTotalByVocab[vocabId] ?? 0;
    final correct = _learnNewCorrectByVocab[vocabId] ?? 0;
    final ratio = total > 0 ? (correct / total) : 1.0;
    final rating = _mapRatioToRating(ratio);
    final timeSpent = _learnNewTimeSpentMsByVocab[vocabId] ?? 3000;

    try {
      await _learningRepo.submitReviewAnswer(
        vocabId: vocabId,
        rating: rating,
        mode: 'learn_new',
        timeSpent: timeSpent,
      );
      Logger.d(
        'PracticeController',
        '✅ LearnNew progress submitted: vocabId=$vocabId rating=${rating.value} ratio=${ratio.toStringAsFixed(2)}',
      );
    } catch (e) {
      Logger.e(
        'PracticeController',
        '❌ LearnNew submit progress error (vocabId=$vocabId)',
        e,
      );
      // Do not block user flow; local cache prevents repeats.
    }
  }

  ReviewRating _mapRatioToRating(double ratio) {
    if (ratio >= 0.95) return ReviewRating.easy;
    if (ratio >= 0.70) return ReviewRating.good;
    if (ratio >= 0.40) return ReviewRating.hard;
    return ReviewRating.again;
  }

  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _timer?.cancel();
    _audioService.stop();
    _speech?.stop();

    // Notify ShellController to refresh data when Practice closes
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().refreshAllData();
    }

    super.onClose();
  }
}

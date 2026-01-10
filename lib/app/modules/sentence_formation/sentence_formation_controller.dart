import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/models/vocab_model.dart' show VocabModel, ExampleModel;
import '../../data/models/exercise_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../services/audio_service.dart';
import '../../services/realtime/today_store.dart';

/// State for sentence formation practice
enum SentenceState {
  loading,
  playing,      // Show exercise
  feedback,     // Show result after answer
  complete,     // Session finished
}

/// Controller for Sentence Formation Practice
/// Flow: Show Vietnamese → User arranges Chinese words → Check → Feedback → Next
class SentenceFormationController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  final TodayStore _todayStore = Get.find<TodayStore>();

  /// Minimum number of exercises per session
  static const int minExercises = 5;
  /// Target number of exercises per session
  static const int targetExercises = 10;

  // TTS for speaking sentences
  FlutterTts? _tts;
  final isSpeaking = false.obs;

  // State
  final state = SentenceState.loading.obs;
  final isLoading = true.obs;
  final vocabs = <VocabModel>[].obs;
  final exercises = <Exercise>[].obs;
  final currentIndex = 0.obs;

  // Current exercise state - managed by widget, but we track results
  final hasAnswered = false.obs;
  final isCorrect = false.obs;

  // Stats
  final correctCount = 0.obs;
  final totalAnswered = 0.obs;
  final streak = 0.obs;

  // Timer
  Timer? _timer;
  final elapsedSeconds = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initTts();
    _loadExercises();
    _startTimer();
  }

  @override
  void onClose() {
    // Save partial session in background if not already saved
    if (!_sessionSaved && state.value != SentenceState.complete && elapsedSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    
    _timer?.cancel();
    _tts?.stop();
    super.onClose();
  }

  void _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('zh-CN');
      await _tts?.setSpeechRate(0.42);
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);

      _tts?.setCompletionHandler(() {
        isSpeaking.value = false;
      });
    } catch (e) {
      Logger.e('SentenceFormationController', 'TTS init error', e);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  Future<void> _loadExercises() async {
    try {
      isLoading.value = true;
      state.value = SentenceState.loading;

      // Get more learned vocabs to ensure we have enough with examples
      final response = await _learningRepo.getLearnedVocabs(
        limit: targetExercises * 3, // Get extra to filter for vocabs with examples
        state: 'all',
        shuffle: true,
      );

      // Filter vocabs that have examples (needed for sentence formation)
      final validVocabs = response.vocabs.toList().where((v) => v.examples.isNotEmpty).toList();

      if (validVocabs.length < minExercises) {
        HMToast.warning('Cần học thêm từ có ví dụ để luyện ghép câu!');
        vocabs.value = [];
        return;
      }

      // Take up to targetExercises vocabs
      vocabs.assignAll(validVocabs.take(targetExercises).toList());

      // Generate sentence order exercises
      _generateExercises();

      if (exercises.length < minExercises) {
        HMToast.warning('Không đủ bài tập! Hãy học thêm từ vựng.');
        return;
      }

      state.value = SentenceState.playing;
      Logger.d('SentenceFormationController', 'Generated ${exercises.length} sentence exercises');
    } catch (e) {
      Logger.e('SentenceFormationController', 'Failed to load exercises', e);
      HMToast.error('Không thể tải bài tập');
    } finally {
      isLoading.value = false;
    }
  }

  void _generateExercises() {
    exercises.clear();

    for (final vocab in vocabs) {
      final exercise = _createSentenceExercise(vocab);
      if (exercise != null) {
        exercises.add(exercise);
      }
    }

    exercises.shuffle();
  }

  Exercise? _createSentenceExercise(VocabModel vocab) {
    if (vocab.examples.isEmpty) return null;

    // Find best example that contains the vocab's hanzi
    ExampleModel? bestExample;
    for (final example in vocab.examples) {
      if (example.hanzi.contains(vocab.hanzi)) {
        bestExample = example;
        break;
      }
    }
    bestExample ??= vocab.examples.first;

    final sentence = bestExample.hanzi;

    // Smart tokenization for Chinese sentence
    List<String> words = _tokenizeSentence(sentence, vocab.hanzi);

    if (words.length < 3) return null;

    return Exercise(
      id: 'sf_${vocab.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: ExerciseType.sentenceOrder,
      vocabId: vocab.id,
      questionHanzi: vocab.hanzi,
      questionPinyin: vocab.pinyin,
      questionMeaning: bestExample.meaningViCapitalized,
      questionAudioUrl: bestExample.audioUrl ?? vocab.audioUrl,
      sentenceWords: words, // Words in CORRECT order
      correctSentence: words.join(''),
    );
  }

  /// Smart tokenization that preserves the target word as a unit
  List<String> _tokenizeSentence(String sentence, String targetWord) {
    // Remove punctuation
    final cleaned = sentence.replaceAll(RegExp(r'[。，！？、；：""''（）【】,.!?]'), '');

    // If target word exists, split around it
    if (cleaned.contains(targetWord)) {
      final parts = <String>[];
      final index = cleaned.indexOf(targetWord);

      // Before target
      if (index > 0) {
        final before = cleaned.substring(0, index);
        parts.addAll(_splitIntoWords(before));
      }

      // Target word itself
      parts.add(targetWord);

      // After target
      if (index + targetWord.length < cleaned.length) {
        final after = cleaned.substring(index + targetWord.length);
        parts.addAll(_splitIntoWords(after));
      }

      return parts.where((p) => p.isNotEmpty).toList();
    }

    // Fallback: split into 2-char words
    return _splitIntoWords(cleaned);
  }

  List<String> _splitIntoWords(String text) {
    final chars = text.split('').where((c) => c.trim().isNotEmpty).toList();
    final words = <String>[];

    int i = 0;
    while (i < chars.length) {
      if (i + 1 < chars.length) {
        // Create 2-char word
        words.add(chars[i] + chars[i + 1]);
        i += 2;
      } else {
        words.add(chars[i]);
        i += 1;
      }
    }

    return words;
  }

  // ========== GETTERS ==========

  Exercise? get currentExercise {
    if (exercises.isEmpty || currentIndex.value >= exercises.length) return null;
    return exercises[currentIndex.value];
  }

  VocabModel? get currentVocab {
    final exercise = currentExercise;
    if (exercise == null) return null;
    return vocabs.firstWhereOrNull((v) => v.id == exercise.vocabId);
  }

  int get remainingCount => exercises.length - currentIndex.value;

  double get accuracy {
    if (totalAnswered.value == 0) return 0;
    return correctCount.value / totalAnswered.value;
  }

  String get formattedTime {
    final mins = elapsedSeconds.value ~/ 60;
    final secs = elapsedSeconds.value % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ========== ACTIONS ==========

  /// Called when user completes arranging words correctly
  void onCorrectAnswer() {
    if (hasAnswered.value) return;

    hasAnswered.value = true;
    isCorrect.value = true;
    totalAnswered.value++;
    correctCount.value++;
    streak.value++;

    HapticFeedback.mediumImpact();
    state.value = SentenceState.feedback;

    // Auto-play correct sentence
    _playCurrentSentence();
  }

  /// Called when user arranges words incorrectly
  void onIncorrectAnswer() {
    if (hasAnswered.value) return;

    hasAnswered.value = true;
    isCorrect.value = false;
    totalAnswered.value++;
    streak.value = 0;

    HapticFeedback.heavyImpact();
    state.value = SentenceState.feedback;
  }

  /// Move to next exercise
  void nextExercise() {
    if (currentIndex.value >= exercises.length - 1) {
      // Session complete
      _finishSession();
      return;
    }

    // Reset state for next exercise
    hasAnswered.value = false;
    isCorrect.value = false;
    currentIndex.value++;
    state.value = SentenceState.playing;
  }

  /// Skip current exercise
  void skipExercise() {
    totalAnswered.value++;
    streak.value = 0;
    nextExercise();
  }

  /// Play audio for current sentence
  Future<void> playAudio({bool slow = false}) async {
    final exercise = currentExercise;
    if (exercise == null) return;

    // Try audio URL first
    final audioUrl = exercise.questionAudioUrl;
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _audioService.play(audioUrl, speed: slow ? 0.75 : 1.0);
      return;
    }

    // Fallback to TTS
    await _playTts(exercise.sentenceWords?.join('') ?? '', slow: slow);
  }

  Future<void> _playCurrentSentence() async {
    final exercise = currentExercise;
    if (exercise == null) return;

    final sentence = exercise.sentenceWords?.join('') ?? '';
    if (sentence.isEmpty) return;

    await _playTts(sentence, slow: false);
  }

  Future<void> _playTts(String text, {bool slow = false}) async {
    if (_tts == null || text.isEmpty) return;

    if (isSpeaking.value) {
      await _tts?.stop();
      isSpeaking.value = false;
      return;
    }

    try {
      isSpeaking.value = true;
      await _tts?.setSpeechRate(slow ? 0.30 : 0.42);
      await _tts?.speak(text);
    } catch (e) {
      Logger.e('SentenceFormationController', 'TTS error', e);
      isSpeaking.value = false;
    }
  }

  /// Flag to prevent double-saving when session completes or exits
  bool _sessionSaved = false;
  
  /// Minimum seconds before saving partial session
  static const int _minSecondsToSave = 10;

  /// Finish the session
  Future<void> _finishSession() async {
    _timer?.cancel();
    _sessionSaved = true;
    state.value = SentenceState.complete;

    // Save session result
    try {
      final result = SessionResultModel(
        seconds: elapsedSeconds.value,
        newCount: 0,
        reviewCount: totalAnswered.value,
        accuracy: accuracy,
      );

      await _learningRepo.finishSession(result);
      await _todayStore.syncNow(force: true);

      Logger.d('SentenceFormationController', 'Session completed: ${totalAnswered.value} exercises, ${(accuracy * 100).round()}% accuracy');
    } catch (e) {
      Logger.e('SentenceFormationController', 'Failed to save session', e);
    }
  }

  /// Save partial session in background (fire-and-forget)
  void _savePartialSessionInBackground() {
    final seconds = elapsedSeconds.value;
    
    // Only save if meaningful time spent
    if (seconds < _minSecondsToSave) {
      Logger.d('SentenceFormationController', '[SKIP_SAVE] seconds=$seconds < $_minSecondsToSave');
      return;
    }
    
    final result = SessionResultModel(
      seconds: seconds,
      newCount: 0,
      reviewCount: totalAnswered.value,
      accuracy: accuracy,
    );
    
    Logger.d(
      'SentenceFormationController',
      '[PARTIAL_SAVE] seconds=$seconds, minutes=${result.minutes}, answered=${totalAnswered.value}',
    );
    
    // Fire and forget - don't block UI
    _learningRepo.finishSession(result).then((_) {
      _todayStore.syncNow(force: true);
    }).catchError((e) {
      Logger.e('SentenceFormationController', 'Failed to save partial session', e);
    });
  }

  /// Exit and go back (non-blocking)
  void exitSession() {
    _timer?.cancel();
    if (!_sessionSaved && elapsedSeconds.value >= _minSecondsToSave) {
      _sessionSaved = true;
      _savePartialSessionInBackground();
    }
    Get.back();
  }

  /// Restart practice
  void restart() {
    currentIndex.value = 0;
    correctCount.value = 0;
    totalAnswered.value = 0;
    streak.value = 0;
    elapsedSeconds.value = 0;
    hasAnswered.value = false;
    isCorrect.value = false;

    _loadExercises();
    _startTimer();
  }
}

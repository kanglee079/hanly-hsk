import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../data/repositories/game_repo.dart';
import '../../services/audio_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';

/// 30s Game Controller - Fast-paced quiz game
class Game30Controller extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final GameRepo _gameRepo = Get.find<GameRepo>();
  final AudioService _audioService = Get.find<AudioService>();

  // Game state
  final RxList<VocabModel> queue = <VocabModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isPaused = false.obs;

  // Timer
  final RxInt remainingSeconds = 30.obs;
  Timer? _timer;

  // Score
  final RxInt score = 0.obs;
  final RxInt streak = 0.obs;
  final RxInt maxStreak = 0.obs;
  final RxInt correctCount = 0.obs;
  final RxInt wrongCount = 0.obs;
  
  // Game limit info from API response
  Map<String, dynamic>? _gameLimitData;

  // Quiz state
  final RxList<String> quizOptions = <String>[].obs;
  final RxInt selectedAnswer = (-1).obs;
  final RxBool hasAnswered = false.obs;
  final RxBool isAnswerCorrect = false.obs;

  VocabModel? get currentVocab =>
      queue.isNotEmpty && currentIndex.value < queue.length
          ? queue[currentIndex.value]
          : null;

  /// Total questions answered (correct + wrong)
  RxInt get totalAnswered => RxInt(correctCount.value + wrongCount.value);

  double get streakMultiplier {
    if (streak.value >= 10) return 3.0;
    if (streak.value >= 5) return 2.0;
    if (streak.value >= 3) return 1.5;
    return 1.0;
  }

  @override
  void onInit() {
    super.onInit();
    _loadQueue();
  }

  // Minimum words required - should match Game30HomeController.minRequiredWords
  static const int _minRequiredWords = 50;

  Future<void> _loadQueue() async {
    isLoading.value = true;

    try {
      // Dùng API mới để lấy TẤT CẢ từ đã học (không chỉ reviewQueue)
      final response = await _learningRepo.getLearnedVocabs(
        limit: 100,
        shuffle: true,
      );
      
      final learnedWords = response.vocabs;
      
      // Check minimum requirement
      if (learnedWords.length < _minRequiredWords) {
        HMToast.warning('Cần học tối thiểu $_minRequiredWords từ để chơi.\nBạn mới học ${learnedWords.length} từ.');
        Get.back(result: {'score': 0});
        return;
      }
      
      // Take up to 50 for variety (BE already shuffled)
      queue.value = learnedWords.take(50).toList();

      _generateQuizOptions();
      _startTimer();
    } catch (e) {
      Logger.e('Game30Controller', 'loadQueue error', e);
      HMToast.error('Không thể tải dữ liệu');
      Get.back(result: {'score': 0});
    } finally {
      isLoading.value = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPaused.value) return;

      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        _endGame();
      }
    });
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

    // If not enough, add generic distractors
    final genericDistractors = [
      'Tạm biệt',
      'Xin lỗi',
      'Cảm ơn',
      'Xin chào',
      'Không có',
      'Được rồi',
      'Tốt lắm',
      'Có thể',
      'Không thể',
      'Muốn',
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

    final correct = quizOptions[index] == currentVocab?.meaningVi;
    isAnswerCorrect.value = correct;

    if (correct) {
      correctCount.value++;
      streak.value++;
      if (streak.value > maxStreak.value) {
        maxStreak.value = streak.value;
      }

      // Calculate score with multiplier
      final points = (10 * streakMultiplier).round();
      score.value += points;

      // Add bonus time for correct answers
      remainingSeconds.value = min(30, remainingSeconds.value + 2);
    } else {
      wrongCount.value++;
      streak.value = 0;
    }

    // Auto advance after short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (currentIndex.value < queue.length - 1) {
      currentIndex.value++;
      selectedAnswer.value = -1;
      hasAnswered.value = false;
      isAnswerCorrect.value = false;
      _generateQuizOptions();
    } else {
      // Shuffle and restart
      queue.shuffle();
      currentIndex.value = 0;
      selectedAnswer.value = -1;
      hasAnswered.value = false;
      isAnswerCorrect.value = false;
      _generateQuizOptions();
    }
  }

  void togglePause() {
    isPaused.value = !isPaused.value;
  }

  void playAudio() {
    final vocab = currentVocab;
    if (vocab?.audioUrl != null && vocab!.audioUrl!.isNotEmpty) {
      _audioService.playNormal(vocab.audioUrl!);
    }
  }

  void _endGame() {
    _timer?.cancel();
    isGameOver.value = true;
    _submitGameResult();
  }

  /// Submit game result to backend
  Future<void> _submitGameResult() async {
    final totalAnsweredValue = correctCount.value + wrongCount.value;
    if (totalAnsweredValue == 0) {
      Logger.w('Game30Controller', 'No answers, skip submit');
      return;
    }

    Logger.d('Game30Controller', 
      '[SUBMIT] Calling API: score=${score.value}, '
      'correct=${correctCount.value}, total=$totalAnsweredValue');

    try {
      final response = await _gameRepo.submitGame(
        gameType: 'speed30s',
        score: score.value,
        correctCount: correctCount.value,
        totalCount: totalAnsweredValue,
        timeSpent: 30000, // 30 seconds in milliseconds
      );

      Logger.d('Game30Controller', 
        '[SUBMIT] SUCCESS: sessionId=${response.session.id}, '
        'savedScore=${response.session.score}, '
        'rank=${response.rank?.rank}');

      // Store game limit data for returning to home screen
      if (response.gameLimit != null) {
        _gameLimitData = {
          'gamePlaysToday': response.gameLimit!.gamePlaysToday,
          'dailyGameLimit': response.gameLimit!.dailyGameLimit,
          'remainingPlays': response.gameLimit!.remainingPlays,
          'canPlayGame': response.gameLimit!.canPlayGame,
          'isPremium': response.gameLimit!.isPremium,
        };
        Logger.d('Game30Controller', 
          '[SUBMIT] gameLimit: plays=${response.gameLimit!.gamePlaysToday}/${response.gameLimit!.dailyGameLimit}');
      }

      // Check if new high score
      if (response.isNewHighScore) {
        HMToast.success('🎉 Kỷ lục mới: ${response.session.score} điểm!');
      }

      if (response.newAchievements != null && response.newAchievements!.isNotEmpty) {
        for (final achievement in response.newAchievements!) {
          HMToast.info('🏆 Mở khóa: $achievement');
        }
      }
    } catch (e, stack) {
      Logger.e('Game30Controller', '[SUBMIT] FAILED: $e');
      Logger.e('Game30Controller', '[SUBMIT] Stack: $stack');
      // Show error so user knows something went wrong
      HMToast.error('Lỗi lưu kết quả. Vui lòng thử lại.');
    }
  }

  void restartGame() {
    isGameOver.value = false;
    remainingSeconds.value = 30;
    score.value = 0;
    streak.value = 0;
    maxStreak.value = 0;
    correctCount.value = 0;
    wrongCount.value = 0;
    currentIndex.value = 0;
    selectedAnswer.value = -1;
    hasAnswered.value = false;
    isAnswerCorrect.value = false;

    queue.shuffle();
    _generateQuizOptions();
    _startTimer();
  }

  void exitGame() {
    _timer?.cancel();
    // Return score and game limit to home screen
    Get.back(result: {
      'score': score.value,
      if (_gameLimitData != null) 'gameLimit': _gameLimitData,
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}


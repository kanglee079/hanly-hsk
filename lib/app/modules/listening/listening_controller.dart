import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../services/audio_service.dart';

/// Listening Practice Controller
/// Focus on audio comprehension with multiple choice answers
class ListeningController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();

  static const int totalQuestions = 10;

  // State
  final isLoading = true.obs;
  final vocabs = <VocabModel>[].obs;
  final currentIndex = 0.obs;
  final hasFinished = false.obs;
  final hasPlayedAudio = false.obs;
  final isPlayingAudio = false.obs;
  final selectedAnswer = Rxn<int>();
  final hasAnswered = false.obs;
  final isCorrect = false.obs;

  // Stats
  final correctCount = 0.obs;
  final totalAnswered = 0.obs;

  // Answer options for current question
  final answerOptions = <VocabModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadVocabs();
  }

  Future<void> _loadVocabs() async {
    try {
      isLoading.value = true;

      // Get learned vocabs for listening practice
      final response = await _learningRepo.getLearnedVocabs(
        limit: totalQuestions + 20, // Extra for answer options
        state: 'all',
        shuffle: true,
      );

      if (response.vocabs.length < 4) {
        HMToast.warning('Cần học thêm ít nhất 4 từ để luyện nghe!');
        vocabs.value = [];
      } else {
        vocabs.value = response.vocabs.take(totalQuestions).toList();
        _generateAnswerOptions();
      }

      Logger.d('ListeningController', 'Loaded ${vocabs.length} vocabs for listening');
    } catch (e) {
      Logger.e('ListeningController', 'Failed to load vocabs', e);
      HMToast.error('Không thể tải từ vựng');
    } finally {
      isLoading.value = false;
    }
  }

  void _generateAnswerOptions() {
    if (vocabs.isEmpty || currentIndex.value >= vocabs.length) return;

    final correctVocab = vocabs[currentIndex.value];
    final otherVocabs = vocabs.where((v) => v.id != correctVocab.id).toList();
    otherVocabs.shuffle();

    // Take 3 wrong answers + 1 correct
    final options = <VocabModel>[correctVocab];
    options.addAll(otherVocabs.take(3));
    options.shuffle();

    answerOptions.value = options;
  }

  VocabModel? get currentVocab {
    if (vocabs.isEmpty || currentIndex.value >= vocabs.length) return null;
    return vocabs[currentIndex.value];
  }

  int get correctAnswerIndex {
    final vocab = currentVocab;
    if (vocab == null) return -1;
    return answerOptions.indexWhere((v) => v.id == vocab.id);
  }

  double get accuracy {
    if (totalAnswered.value == 0) return 0;
    return correctCount.value / totalAnswered.value;
  }

  void playAudio() async {
    final vocab = currentVocab;
    if (vocab == null || vocab.audioUrl == null) return;

    isPlayingAudio.value = true;
    hasPlayedAudio.value = true;

    try {
      await _audioService.play(vocab.audioUrl!);
    } finally {
      // Give some time for audio to play
      await Future.delayed(const Duration(milliseconds: 800));
      isPlayingAudio.value = false;
    }
  }

  void selectAnswer(int index) {
    if (hasAnswered.value) return;
    if (!hasPlayedAudio.value) {
      HMToast.info('Hãy nghe audio trước khi chọn đáp án!');
      return;
    }

    selectedAnswer.value = index;
    hasAnswered.value = true;
    totalAnswered.value++;

    final correct = index == correctAnswerIndex;
    isCorrect.value = correct;

    if (correct) {
      correctCount.value++;
    }
  }

  void nextQuestion() {
    if (currentIndex.value < vocabs.length - 1) {
      currentIndex.value++;
      _resetQuestionState();
      _generateAnswerOptions();
    } else {
      hasFinished.value = true;
    }
  }

  void _resetQuestionState() {
    hasPlayedAudio.value = false;
    selectedAnswer.value = null;
    hasAnswered.value = false;
    isCorrect.value = false;
  }

  void restart() {
    currentIndex.value = 0;
    hasFinished.value = false;
    correctCount.value = 0;
    totalAnswered.value = 0;
    _resetQuestionState();
    _loadVocabs();
  }

  void goBack() {
    Get.back();
  }
}


import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../services/audio_service.dart';
import '../../services/realtime/today_store.dart';

/// Flashcard Controller - manages SRS vocabulary flashcard session
/// Uses Option 1: SRS Priority Algorithm
/// - Priority 1: Words due for review today (reviewQueue) → 4-5 words
/// - Priority 2: Recently learned words (state=learning) → 3-4 words  
/// - Priority 3: Words with low interval (struggling) → 1-2 words
class FlashcardController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  final TodayStore _todayStore = Get.find<TodayStore>();

  static const int totalCards = 10; // Tổng số thẻ mỗi lần học

  // State
  final isLoading = true.obs;
  final vocabs = <VocabModel>[].obs;
  final currentIndex = 0.obs;
  final isFlipped = false.obs;
  final hasFinished = false.obs;
  
  // Stats for display
  final dueCount = 0.obs;      // Số từ đến hạn ôn
  final learningCount = 0.obs; // Số từ đang học
  final reviewCount = 0.obs;   // Số từ cần củng cố

  @override
  void onInit() {
    super.onInit();
    _loadVocabs();
  }

  /// Load vocabs using SRS Priority Algorithm (Option 1)
  /// 1. Due for review (reviewQueue) → 4-5 từ
  /// 2. Recently learning → 3-4 từ
  /// 3. Low interval/struggling → 1-2 từ
  Future<void> _loadVocabs() async {
    try {
      isLoading.value = true;
      
      final List<VocabModel> finalList = [];
      final Set<String> addedIds = {}; // Avoid duplicates

      // === PRIORITY 1: Words due for review today ===
      final todayData = _todayStore.today.data.value;
      if (todayData != null && todayData.reviewQueue.isNotEmpty) {
        final dueWords = todayData.reviewQueue.take(5).toList();
        for (final word in dueWords) {
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
          }
        }
        dueCount.value = dueWords.length;
        Logger.d('FlashcardController', 'Added ${dueWords.length} due words from reviewQueue');
      }

      // === PRIORITY 2: Recently learning words ===
      if (finalList.length < totalCards) {
        final remaining = totalCards - finalList.length;
        final learningResponse = await _learningRepo.getLearnedVocabs(
          limit: remaining + 5, // Get extra to filter duplicates
          state: 'learning',
          shuffle: false, // Keep recent order
        );
        
        int learningAdded = 0;
        for (final word in learningResponse.vocabs) {
          if (finalList.length >= totalCards) break;
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
            learningAdded++;
          }
        }
        learningCount.value = learningAdded;
        Logger.d('FlashcardController', 'Added $learningAdded learning words');
      }

      // === PRIORITY 3: Review/struggling words (low interval) ===
      if (finalList.length < totalCards) {
        final remaining = totalCards - finalList.length;
        final reviewResponse = await _learningRepo.getLearnedVocabs(
          limit: remaining + 5,
          state: 'review',
          shuffle: true, // Random from review pool
        );
        
        int reviewAdded = 0;
        for (final word in reviewResponse.vocabs) {
          if (finalList.length >= totalCards) break;
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
            reviewAdded++;
          }
        }
        reviewCount.value = reviewAdded;
        Logger.d('FlashcardController', 'Added $reviewAdded review words');
      }

      // === FALLBACK: Get any learned vocabs if still not enough ===
      if (finalList.length < totalCards) {
        final remaining = totalCards - finalList.length;
        final allResponse = await _learningRepo.getLearnedVocabs(
          limit: remaining + 10,
          state: 'all',
          shuffle: true,
        );
        
        for (final word in allResponse.vocabs) {
          if (finalList.length >= totalCards) break;
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
          }
        }
        Logger.d('FlashcardController', 'Filled with ${finalList.length} total words');
      }

      vocabs.value = finalList;

      if (vocabs.isEmpty) {
        HMToast.warning('Chưa có từ nào đã học. Hãy học thêm từ mới!');
      }

      Logger.d('FlashcardController', 
        'Loaded ${vocabs.length} vocabs: due=${dueCount.value}, learning=${learningCount.value}, review=${reviewCount.value}');
    } catch (e) {
      Logger.e('FlashcardController', 'Failed to load vocabs', e);
      HMToast.error('Không thể tải từ vựng');
    } finally {
      isLoading.value = false;
    }
  }

  VocabModel? get currentVocab {
    if (vocabs.isEmpty || currentIndex.value >= vocabs.length) return null;
    return vocabs[currentIndex.value];
  }

  void flipCard() {
    isFlipped.toggle();
  }

  void nextCard() {
    if (currentIndex.value < vocabs.length - 1) {
      currentIndex.value++;
      isFlipped.value = false;
    } else {
      hasFinished.value = true;
    }
  }

  void previousCard() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      isFlipped.value = false;
    }
  }

  void playAudio({bool slow = false}) {
    final vocab = currentVocab;
    if (vocab == null) return;

    final url = slow ? vocab.audioSlowUrl : vocab.audioUrl;
    if (url != null && url.isNotEmpty) {
      _audioService.play(url);
      Logger.d('FlashcardController', 'Playing ${slow ? "slow" : "normal"} audio: $url');
    } else {
      HMToast.warning(slow ? 'Không có audio chậm' : 'Không có audio');
      Logger.w('FlashcardController', 'No ${slow ? "slow" : "normal"} audio URL for ${vocab.hanzi}');
    }
  }

  void restart() {
    currentIndex.value = 0;
    isFlipped.value = false;
    hasFinished.value = false;
    _loadVocabs(); // Reload with new random words
  }

  void goBack() {
    Get.back();
  }
}


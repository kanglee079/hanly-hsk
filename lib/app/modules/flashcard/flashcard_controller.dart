import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../services/audio_service.dart';
import '../../services/realtime/today_store.dart';

/// Flashcard Controller - Smart Adaptive Mix Algorithm
/// 
/// Tự động điều chỉnh tỷ lệ từ mới/ôn tập dựa trên tiến độ người dùng:
/// 
/// | Giai đoạn       | Từ đã học | Từ mới | Ôn tập | Mục đích              |
/// |-----------------|-----------|--------|--------|----------------------|
/// | Người mới       | < 10      | 60%    | 40%    | Xây dựng vốn từ nhanh |
/// | Đang phát triển | 10-50     | 40%    | 60%    | Cân bằng học + củng cố|
/// | Đã ổn định      | > 50      | 25%    | 75%    | Ghi nhớ lâu dài       |
/// 
/// Priority trong mỗi loại:
/// - Ôn tập: reviewQueue (due today) > learning state > review pool
/// - Từ mới: newQueue (today's targets)
class FlashcardController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final AudioService _audioService = Get.find<AudioService>();
  final TodayStore _todayStore = Get.find<TodayStore>();
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();

  static const int totalCards = 10; // Tổng số thẻ mỗi lần học

  // State
  final isLoading = true.obs;
  final vocabs = <VocabModel>[].obs;
  final currentIndex = 0.obs;
  final isFlipped = false.obs;
  final hasFinished = false.obs;
  
  // Stats for display
  final newWordsCount = 0.obs;    // Số từ mới trong deck
  final reviewWordsCount = 0.obs; // Số từ ôn tập trong deck
  final totalLearnedCount = 0.obs; // Tổng số từ đã học của user
  
  // User stage (for UI display)
  final userStage = 'new'.obs; // 'new' | 'growing' | 'established'

  @override
  void onInit() {
    super.onInit();
    _loadVocabs();
  }

  /// Determine user's learning stage and optimal mix ratio
  _MixRatio _calculateMixRatio(int totalLearned) {
    if (totalLearned < 10) {
      // Stage 1: Người mới - ưu tiên học từ mới
      userStage.value = 'new';
      return _MixRatio(
        newRatio: 0.6,    // 60% từ mới (6 cards)
        reviewRatio: 0.4, // 40% ôn tập (4 cards)
      );
    } else if (totalLearned < 50) {
      // Stage 2: Đang phát triển - cân bằng
      userStage.value = 'growing';
      return _MixRatio(
        newRatio: 0.4,    // 40% từ mới (4 cards)
        reviewRatio: 0.6, // 60% ôn tập (6 cards)
      );
    } else {
      // Stage 3: Đã ổn định - tập trung ôn tập
      userStage.value = 'established';
      return _MixRatio(
        newRatio: 0.25,   // 25% từ mới (2-3 cards)
        reviewRatio: 0.75, // 75% ôn tập (7-8 cards)
      );
    }
  }

  /// Load vocabs using Smart Adaptive Mix Algorithm
  Future<void> _loadVocabs() async {
    try {
      isLoading.value = true;
      
      final todayData = _todayStore.today.value;
      final totalLearned = todayData?.totalLearned ?? 0;
      totalLearnedCount.value = totalLearned;
      
      // Calculate optimal mix based on user's stage
      final mixRatio = _calculateMixRatio(totalLearned);
      final targetNew = (totalCards * mixRatio.newRatio).round();
      final targetReview = totalCards - targetNew;
      
      Logger.d('FlashcardController', 
        'User stage: ${userStage.value}, totalLearned: $totalLearned, '
        'target: $targetNew new + $targetReview review');

      final List<VocabModel> finalList = [];
      final Set<String> addedIds = {}; // Avoid duplicates
      int newAdded = 0;
      int reviewAdded = 0;

      // === STEP 1: Add REVIEW words first (priority: due today) ===
      if (todayData != null && todayData.reviewQueue.isNotEmpty) {
        for (final word in todayData.reviewQueue) {
          if (reviewAdded >= targetReview) break;
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
            reviewAdded++;
          }
        }
        Logger.d('FlashcardController', 'Added $reviewAdded due words from reviewQueue');
      }

      // === STEP 2: Add more review words if needed (learning state) ===
      if (reviewAdded < targetReview) {
        final remaining = targetReview - reviewAdded;
        try {
          final learningResponse = await _learningRepo.getLearnedVocabs(
            limit: remaining + 5,
            state: 'learning',
            shuffle: true,
          );
          
          for (final word in learningResponse.vocabs) {
            if (reviewAdded >= targetReview) break;
            if (!addedIds.contains(word.id)) {
              finalList.add(word);
              addedIds.add(word.id);
              reviewAdded++;
            }
          }
          Logger.d('FlashcardController', 'Added $reviewAdded total review words (including learning)');
        } catch (e) {
          Logger.w('FlashcardController', 'Failed to get learning vocabs: $e');
        }
      }

      // === STEP 3: Add more review words from review pool if still needed ===
      if (reviewAdded < targetReview) {
        final remaining = targetReview - reviewAdded;
        try {
          final reviewResponse = await _learningRepo.getLearnedVocabs(
            limit: remaining + 5,
            state: 'review',
            shuffle: true,
          );
          
          for (final word in reviewResponse.vocabs) {
            if (reviewAdded >= targetReview) break;
            if (!addedIds.contains(word.id)) {
              finalList.add(word);
              addedIds.add(word.id);
              reviewAdded++;
            }
          }
        } catch (e) {
          Logger.w('FlashcardController', 'Failed to get review vocabs: $e');
        }
      }

      // === STEP 4: Add NEW words from newQueue ===
      if (todayData != null && todayData.newQueue.isNotEmpty) {
        for (final word in todayData.newQueue) {
          if (newAdded >= targetNew) break;
          if (!addedIds.contains(word.id)) {
            finalList.add(word);
            addedIds.add(word.id);
            newAdded++;
          }
        }
        Logger.d('FlashcardController', 'Added $newAdded new words from newQueue');
      }

      // === STEP 5: If still not enough, fill with whatever is available ===
      if (finalList.length < totalCards) {
        // Try to get more new words if newQueue was not enough
        final remaining = totalCards - finalList.length;
        
        // First try: Get any mastered words for variety
        try {
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
              reviewAdded++;
            }
          }
        } catch (e) {
          Logger.w('FlashcardController', 'Failed to get fallback vocabs: $e');
        }
      }

      // === STEP 6: Shuffle to mix new and review words naturally ===
      finalList.shuffle();

      // === STEP 7: Sync favorite status from backend ===
      await _syncFavoriteStatus(finalList);

      // Update stats
      newWordsCount.value = newAdded;
      reviewWordsCount.value = reviewAdded;
      vocabs.value = finalList;

      if (vocabs.isEmpty) {
        // Provide clear, helpful message based on situation
        if (todayData?.newQueue.isEmpty == true && totalLearned == 0) {
          HMToast.info(ToastMessages.flashcardNoNewWords);
        } else {
          HMToast.info(ToastMessages.flashcardNoVocabsAvailable);
        }
      }

      Logger.d('FlashcardController', 
        'Final deck: ${vocabs.length} cards (${newWordsCount.value} new + ${reviewWordsCount.value} review)');
    } catch (e) {
      Logger.e('FlashcardController', 'Failed to load vocabs', e);
      HMToast.error(ToastMessages.flashcardLoadError);
    } finally {
      isLoading.value = false;
    }
  }

  VocabModel? get currentVocab {
    if (vocabs.isEmpty || currentIndex.value >= vocabs.length) return null;
    return vocabs[currentIndex.value];
  }

  /// Check if current vocab is a new word (not yet learned)
  bool get isCurrentWordNew {
    final vocab = currentVocab;
    if (vocab == null) return false;
    
    final todayData = _todayStore.today.value;
    if (todayData == null) return false;
    
    return todayData.newQueue.any((w) => w.id == vocab.id);
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
      HMToast.warning(slow ? ToastMessages.flashcardNoSlowAudio : ToastMessages.flashcardNoAudio);
      Logger.w('FlashcardController', 'No ${slow ? "slow" : "normal"} audio URL for ${vocab.hanzi}');
    }
  }

  void restart() {
    currentIndex.value = 0;
    isFlipped.value = false;
    hasFinished.value = false;
    _loadVocabs(); // Reload with new mix
  }

  void goBack() {
    Get.back();
  }

  /// Sync favorite status from backend
  Future<void> _syncFavoriteStatus(List<VocabModel> vocabsList) async {
    try {
      // Load favorites list from backend
      final favoritesList = await _favoritesRepo.getFavorites();
      final favoriteIds = favoritesList.map((v) => v.id).toSet();
      
      // Update isFavorite for each vocab
      for (int i = 0; i < vocabsList.length; i++) {
        if (favoriteIds.contains(vocabsList[i].id)) {
          vocabsList[i] = vocabsList[i].copyWith(isFavorite: true);
        }
      }
      
      Logger.d('FlashcardController', 'Synced favorite status for ${vocabsList.length} vocabs');
    } catch (e) {
      Logger.w('FlashcardController', 'Failed to sync favorite status: $e');
      // Don't block if favorites sync fails
    }
  }

  /// Toggle favorite for current vocab
  Future<void> toggleFavorite() async {
    final vocab = currentVocab;
    if (vocab == null) return;

    try {
      final wasFavorite = vocab.isFavorite;
      
      if (wasFavorite) {
        await _favoritesRepo.removeFavorite(vocab.id);
      } else {
        await _favoritesRepo.addFavorite(vocab.id);
      }

      // Update vocab in list
      final index = vocabs.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        vocabs[index] = vocab.copyWith(isFavorite: !wasFavorite);
      }

      HMToast.success(
        wasFavorite 
          ? ToastMessages.favoritesRemoveSuccess 
          : ToastMessages.favoritesAddSuccess
      );
    } catch (e) {
      Logger.e('FlashcardController', 'toggleFavorite error', e);
      HMToast.error(ToastMessages.favoritesUpdateError);
    }
  }
  
  /// Get display text for user stage
  String get stageDisplayText {
    switch (userStage.value) {
      case 'new':
        return 'Người mới • Ưu tiên học từ mới';
      case 'growing':
        return 'Đang phát triển • Cân bằng học & ôn';
      case 'established':
        return 'Vốn từ ổn định • Tập trung ôn tập';
      default:
        return '';
    }
  }
}

/// Mix ratio configuration
class _MixRatio {
  final double newRatio;
  final double reviewRatio;
  
  const _MixRatio({
    required this.newRatio,
    required this.reviewRatio,
  });
}

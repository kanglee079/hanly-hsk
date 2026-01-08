import 'package:get/get.dart';
import '../../data/models/study_modes_model.dart';
import '../../data/repositories/learning_repo.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../core/widgets/hm_streak_bottom_sheet.dart';
import '../today/today_controller.dart';
import '../practice/practice_controller.dart';
import '../../services/realtime/study_modes_store.dart';
import '../../services/realtime/today_store.dart';

/// Learning mode enum - maps to API mode IDs
enum LearnMode {
  srsVocabulary, // srs_vocabulary
  listening,     // listening
  writing,       // writing
  matching,      // matching
  comprehensive, // comprehensive
  review,        // quick review
  game30,
  pronunciation,
  sentenceFormation, // sentence_formation - Đặt câu
}

extension LearnModeExtension on LearnMode {
  String get apiId {
    switch (this) {
      case LearnMode.srsVocabulary:
        return 'srs_vocabulary';
      case LearnMode.listening:
        return 'listening';
      case LearnMode.writing:
        return 'writing';
      case LearnMode.matching:
        return 'matching';
      case LearnMode.comprehensive:
        return 'comprehensive';
      case LearnMode.review:
        return 'review';
      case LearnMode.game30:
        return 'game30';
      case LearnMode.pronunciation:
        return 'pronunciation';
      case LearnMode.sentenceFormation:
        return 'sentence_formation';
    }
  }

  static LearnMode fromApiId(String id) {
    switch (id) {
      case 'srs_vocabulary':
        return LearnMode.srsVocabulary;
      case 'listening':
        return LearnMode.listening;
      case 'writing':
      case 'pronunciation':
        return LearnMode.pronunciation;
      case 'matching':
        return LearnMode.matching;
      case 'comprehensive':
        return LearnMode.comprehensive;
      case 'sentence_formation':
        return LearnMode.sentenceFormation;
      default:
        return LearnMode.srsVocabulary;
    }
  }
}

/// Learn controller - manages study modes screen
class LearnController extends GetxController {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final StudyModesStore _studyModesStore = Get.find<StudyModesStore>();
  final TodayStore _todayStore = Get.find<TodayStore>();

  // Observable data
  late final Rxn<StudyModesResponse> studyModesData = _studyModesStore.studyModes.data;
  late final RxBool isLoading = _studyModesStore.studyModes.isBootstrapping;
  final isLoadingWords = false.obs;
  final errorMessage = ''.obs; // friendly message for UI

  @override
  void onInit() {
    super.onInit();
    // Mirror store error into a friendly message.
    ever<String>(_studyModesStore.studyModes.lastError, (err) {
      errorMessage.value = err.isEmpty ? '' : 'Không thể tải dữ liệu. Vui lòng thử lại.';
      _maybeApplyFallback();
    });

    // If study-modes endpoint is missing/unavailable, synthesize minimal data from /today.
    ever(_todayStore.today.data, (_) => _maybeApplyFallback());

    // Nudge an initial sync (service also polls, but this makes first render snappier).
    _studyModesStore.syncNow();
  }

  /// Force-sync (legacy callers).
  Future<void> loadStudyModes() async {
    await _studyModesStore.syncNow(force: true);
  }

  void _maybeApplyFallback() {
    if (studyModesData.value != null) return;
    if (_studyModesStore.studyModes.lastError.value.isEmpty) return;

    final today = _todayStore.today.data.value;
    if (today == null) return;

    _studyModesStore.studyModes.setData(
      StudyModesResponse(
        date: DateTime.now().toIso8601String().split('T')[0],
        streak: today.streak,
        isPremium: false,
        quickReview: QuickReviewModel(
          available: today.reviewCount > 0,
          wordCount: today.reviewCount,
          estimatedMinutes: (today.reviewCount * 0.3).ceil(),
        ),
        studyModes: _createFallbackModes(today.reviewCount, today.newCount),
        todayProgress: TodayProgressModel(
          completedMinutes: today.completedMinutes,
          goalMinutes: today.dailyGoalMinutes,
          newLearned: today.newLearned,
          reviewed: today.reviewed,
          accuracy: today.todayAccuracy,
        ),
      ),
    );
  }

  /// Create fallback modes when API fails
  List<StudyModeModel> _createFallbackModes(int reviewCount, int newCount) {
    return [
      StudyModeModel(
        id: 'sentence_formation',
        name: 'Đặt câu',
        nameEn: 'Sentence Formation',
        description: 'Sắp xếp từ tạo câu đúng',
        icon: '📝',
        estimatedMinutes: 5,
        wordCount: 10,
        isPremium: false,
        isAvailable: true,
      ),
      StudyModeModel(
        id: 'listening',
        name: 'Luyện Nghe',
        nameEn: 'Nghe & chọn đáp án',
        description: 'Luyện nghe hiểu từ vựng',
        icon: '🎧',
        estimatedMinutes: 5,
        wordCount: 10,
        isPremium: false,
        isAvailable: true,
      ),
      StudyModeModel(
        id: 'pronunciation',
        name: 'Phát âm',
        nameEn: 'Luyện nói',
        description: 'Luyện phát âm chuẩn',
        icon: '🎤',
        estimatedMinutes: 5,
        wordCount: 10,
        isPremium: false,
        isAvailable: true,
      ),
      StudyModeModel(
        id: 'matching',
        name: 'Ghép Từ',
        nameEn: 'Ngữ cảnh',
        description: 'Ghép từ với nghĩa đúng',
        icon: '🧩',
        estimatedMinutes: 8,
        wordCount: 12,
        isPremium: false,
        isAvailable: true,
      ),
      StudyModeModel(
        id: 'comprehensive',
        name: 'Ôn tập tổng hợp',
        nameEn: 'Comprehensive Review',
        description: 'Kết hợp tất cả chế độ học',
        icon: '⭐',
        estimatedMinutes: 15,
        wordCount: 25,
        isPremium: true,
        isAvailable: false,
        unavailableReason: 'Cần Premium để sử dụng',
      ),
    ];
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    await _studyModesStore.syncNow(force: true);
  }

  /// Get streak count
  int get streak => studyModesData.value?.streak ?? _getStreakFromToday();

  int _getStreakFromToday() {
    try {
      return _todayStore.today.data.value?.streak ?? 0;
    } catch (_) {
      return 0;
    }
  }
  
  /// Get streak rank from TodayController
  String get streakRank {
    try {
      return _todayStore.today.data.value?.streakRank ?? '';
    } catch (_) {
      return '';
    }
  }
  
  /// Check if user has studied today
  bool get hasStudiedToday {
    try {
      final streakStatus = _todayStore.today.data.value?.streakStatus;
      if (streakStatus != null) return streakStatus.hasStudiedToday;
      return (_todayStore.today.data.value?.completedMinutes ?? 0) > 0;
    } catch (_) {
      return true;
    }
  }
  
  /// Show streak details bottom sheet
  void showStreakDetails() {
    try {
      Get.find<TodayController>().showStreakDetails();
    } catch (_) {
      // Fallback if TodayController not available
      HMStreakBottomSheet.show(
        streak: streak,
        hasStudiedToday: hasStudiedToday,
        onStartLearning: () => startMode(LearnMode.srsVocabulary),
      );
    }
  }

  /// Get quick review data
  QuickReviewModel? get quickReview => studyModesData.value?.quickReview;
  
  /// Get count of words due for review (for Flashcard display)
  int get dueReviewCount {
    try {
      final reviewQueue = _todayStore.today.data.value?.reviewQueue;
      return reviewQueue?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get study modes (4 main modes for grid)
  List<StudyModeModel> get mainStudyModes {
    final modes = studyModesData.value?.studyModes ?? [];
    // Return first 4 modes (excluding comprehensive)
    final result = modes.where((m) => m.id != 'comprehensive').take(4).toList();
    
    // 🔧 FIX: Ensure flashcard (srs_vocabulary) is always available
    return result.map((mode) {
      if (mode.id == 'srs_vocabulary') {
        return mode.copyWith(
          isPremium: false,
          isAvailable: true,
        );
      }
      return mode;
    }).toList();
  }

  /// Get comprehensive mode
  StudyModeModel? get comprehensiveMode {
    return studyModesData.value?.getModeById('comprehensive');
  }

  /// Get mode by ID
  StudyModeModel? getModeById(String id) {
    return studyModesData.value?.getModeById(id);
  }

  /// Start study mode - NOW USES NEW PRACTICE FLOW
  void startMode(LearnMode mode) async {
    // Handle special modes
    if (mode == LearnMode.game30) {
      // Navigate to Game30 Home with leaderboard
      Get.toNamed(Routes.game30Home);
      return;
    }

    if (mode == LearnMode.pronunciation) {
      Get.toNamed(Routes.pronunciation);
      return;
    }

    // Check if mode is available
    final modeData = getModeById(mode.apiId);
    // 🔧 FIX: Never block flashcard (srs_vocabulary) - it's always free
    if (mode != LearnMode.srsVocabulary && modeData != null && !modeData.isAvailable) {
      _showPremiumDialog(modeData.unavailableReason ?? ToastMessages.premiumFeatureLocked);
      return;
    }

    // Navigate to new Practice flow based on mode
    switch (mode) {
      case LearnMode.srsVocabulary:
        // Flashcard review - beautiful flip animation
        Get.toNamed(Routes.flashcard);
        break;
      case LearnMode.review:
        // Quick SRS review
        Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.reviewSRS});
        break;
      case LearnMode.listening:
        // Dedicated listening practice screen
        Get.toNamed(Routes.listening);
        break;
      case LearnMode.writing:
        _startWritingMode();
        break;
      case LearnMode.matching:
        // Matching game
        Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.matching});
        break;
      case LearnMode.comprehensive:
        // Mixed exercises
        Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.comprehensive});
        break;
      case LearnMode.sentenceFormation:
        // Sentence formation - Đặt câu
        Get.toNamed(Routes.sentenceFormation);
        break;
      default:
        Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.learnNew});
    }
  }

  /// Start by mode ID (from API)
  void startModeById(String modeId) {
    final mode = LearnModeExtension.fromApiId(modeId);
    startMode(mode);
  }

  void _startPracticeSession(PracticeMode mode) {
    Get.toNamed(Routes.practice, arguments: {'mode': mode});
  }

  void _startWritingMode() async {
    try {
      isLoadingWords.value = true;
      final words = await _learningRepo.getStudyModeWords('writing', limit: 10);
      
      if (words.isEmpty) {
        HMToast.info('Không có từ vựng để luyện viết');
        return;
      }

      Get.toNamed(
        Routes.practice,
        arguments: {
          'mode': PracticeMode.learnNew,
          'vocabs': words,
        },
      );
    } catch (e) {
      Logger.e('LearnController', 'Failed to load writing words', e);
      _startPracticeSession(PracticeMode.learnNew);
    } finally {
      isLoadingWords.value = false;
    }
  }

  void _showPremiumDialog(String message) {
    HMToast.info(message, title: 'Premium');
    // Optional: Navigate to premium screen
    // Get.toNamed(Routes.premium);
  }

  /// Start quick review
  void startQuickReview() {
    final qr = quickReview;
    if (qr != null && qr.available) {
      Get.toNamed(Routes.practice, arguments: {'mode': PracticeMode.reviewSRS});
    } else {
      HMToast.info(ToastMessages.practiceNoVocabsToReview);
    }
  }

  /// Navigate to leaderboard
  void goToLeaderboard() {
    Get.toNamed(Routes.leaderboard);
  }

  /// Navigate to stats
  void goToStats() {
    Get.toNamed(Routes.stats);
  }
}

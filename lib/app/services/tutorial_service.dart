import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import 'storage_service.dart';

/// Tutorial definitions for each screen
class TutorialDefinitions {
  // Today Screen Tutorial - 7 comprehensive steps
  static const String todayTutorialId = 'today_screen_v1';
  static const List<TutorialStepDef> todaySteps = [
    TutorialStepDef(
      id: 'today_next_action',
      title: 'Hành động tiếp theo',
      description:
          'Đây là thẻ gợi ý hành động bạn nên làm tiếp. Nhấn vào để bắt đầu học ngay!',
      emoji: '🎯',
    ),
    TutorialStepDef(
      id: 'today_progress_ring',
      title: 'Tiến độ hôm nay',
      description:
          'Vòng tròn hiển thị số từ đã học và thời gian đã học trong ngày.',
      emoji: '📊',
    ),
    TutorialStepDef(
      id: 'today_streak',
      title: 'Chuỗi ngày học',
      description:
          'Duy trì streak để nhận phần thưởng và điểm xếp hạng cao hơn!',
      emoji: '🔥',
    ),
    TutorialStepDef(
      id: 'today_quick_actions',
      title: 'Ôn tập & Luyện tập',
      description:
          'Chọn Ôn tập SRS để ôn từ cũ, hoặc Game 30s để kiếm XP nhanh!',
      emoji: '⚡',
    ),
    TutorialStepDef(
      id: 'today_learned',
      title: 'Củng cố từ vừa học',
      description: 'Nhấn "Ôn tập" để củng cố ngay các từ bạn vừa học hôm nay.',
      emoji: '✨',
    ),
    TutorialStepDef(
      id: 'today_due',
      title: 'Cần ôn hôm nay',
      description:
          'Danh sách từ đến hạn ôn theo thuật toán SRS. Nhấn "Xem tất cả" để bắt đầu!',
      emoji: '📝',
    ),
    TutorialStepDef(
      id: 'today_forecast',
      title: 'Dự báo ôn tập',
      description:
          'Xem trước số từ cần ôn trong 7 ngày tới để lên kế hoạch học tập.',
      emoji: '📅',
    ),
  ];

  // Explore Screen Tutorial - 5 comprehensive steps
  static const String exploreTutorialId = 'explore_screen_v1';
  static const List<TutorialStepDef> exploreSteps = [
    TutorialStepDef(
      id: 'explore_search',
      title: 'Tìm kiếm từ vựng',
      description:
          'Gõ bất kỳ từ tiếng Trung, pinyin hoặc tiếng Việt để tra cứu.',
      emoji: '🔍',
    ),
    TutorialStepDef(
      id: 'explore_hsk_levels',
      title: 'Cấp độ HSK',
      description:
          'Học theo từng cấp HSK từ 1 đến 6, phù hợp với trình độ của bạn.',
      emoji: '🎓',
    ),
    TutorialStepDef(
      id: 'explore_daily_pick',
      title: 'Từ vựng hôm nay',
      description: 'Mỗi ngày app sẽ gợi ý từ mới phù hợp với cấp độ của bạn!',
      emoji: '🌟',
    ),
    TutorialStepDef(
      id: 'explore_collections',
      title: 'Bộ sưu tập',
      description: 'Khám phá các bài học được sắp xếp theo chủ đề và cấp độ.',
      emoji: '📚',
    ),
    TutorialStepDef(
      id: 'explore_recent',
      title: 'Gần đây',
      description: 'Xem lại các từ bạn đã tra cứu hoặc học gần đây.',
      emoji: '🕐',
    ),
  ];

  // Me Screen Tutorial - 5 comprehensive steps
  static const String meTutorialId = 'me_screen_v1';
  static const List<TutorialStepDef> meSteps = [
    TutorialStepDef(
      id: 'me_profile',
      title: 'Hồ sơ của bạn',
      description: 'Xem và chỉnh sửa thông tin cá nhân, mục tiêu học tập.',
      emoji: '👤',
    ),
    TutorialStepDef(
      id: 'me_daily_goal',
      title: 'Mục tiêu hàng ngày',
      description: 'Đặt và theo dõi mục tiêu học tập của bạn.',
      emoji: '🎯',
    ),
    TutorialStepDef(
      id: 'me_stats',
      title: 'Thống kê học tập',
      description: 'Theo dõi tiến trình, số từ đã thuộc và nhiều chỉ số khác.',
      emoji: '📈',
    ),
    TutorialStepDef(
      id: 'me_favorites',
      title: 'Từ yêu thích',
      description: 'Xem và ôn tập các từ bạn đã lưu vào danh sách yêu thích.',
      emoji: '❤️',
    ),
    TutorialStepDef(
      id: 'me_settings',
      title: 'Cài đặt',
      description: 'Tùy chỉnh giao diện, âm thanh và các cài đặt khác.',
      emoji: '⚙️',
    ),
  ];

  // HSK Exam Screen Tutorial - 5 comprehensive steps
  static const String hskExamTutorialId = 'hsk_exam_screen_v1';
  static const List<TutorialStepDef> hskExamSteps = [
    TutorialStepDef(
      id: 'hsk_stats',
      title: 'Thống kê thi HSK',
      description: 'Xem số đề đã làm, điểm trung bình và tỉ lệ đậu.',
      emoji: '📊',
    ),
    TutorialStepDef(
      id: 'hsk_level_select',
      title: 'Chọn cấp độ',
      description: 'Chọn cấp HSK bạn muốn thi thử từ HSK1 đến HSK6.',
      emoji: '🎯',
    ),
    TutorialStepDef(
      id: 'hsk_practice',
      title: 'Làm bài thi thử',
      description: 'Đề thi mô phỏng thật với các dạng câu hỏi chuẩn HSK.',
      emoji: '📝',
    ),
    TutorialStepDef(
      id: 'hsk_skill_practice',
      title: 'Luyện kỹ năng',
      description: 'Luyện từng kỹ năng riêng: Nghe, Đọc, Viết.',
      emoji: '🎧',
    ),
    TutorialStepDef(
      id: 'hsk_history',
      title: 'Lịch sử thi',
      description: 'Xem lại các bài thi đã làm và phân tích điểm mạnh/yếu.',
      emoji: '📋',
    ),
  ];

  // Learn Screen Tutorial
  static const String learnTutorialId = 'learn_screen_v1';
  static const List<TutorialStepDef> learnSteps = [
    TutorialStepDef(
      id: 'learn_quick_review',
      title: 'Ôn tập nhanh',
      description: 'Xem nhanh các từ cần ôn hôm nay và bắt đầu ôn ngay!',
      emoji: '⚡',
    ),
    TutorialStepDef(
      id: 'learn_study_modes',
      title: 'Chế độ học',
      description:
          'Chọn chế độ học phù hợp: Flashcard, Trắc nghiệm, Viết, Nghe.',
      emoji: '📚',
    ),
    TutorialStepDef(
      id: 'learn_comprehensive',
      title: 'Ôn tập tổng hợp',
      description: 'Kết hợp tất cả các chế độ để ôn tập toàn diện.',
      emoji: '🌟',
    ),
  ];

  /// Map tab index to tutorial ID
  static String? getTutorialIdForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return todayTutorialId;
      case 1:
        return learnTutorialId;
      case 2:
        return hskExamTutorialId;
      case 3:
        return exploreTutorialId;
      case 4:
        return meTutorialId;
      default:
        return null;
    }
  }
}

/// Single tutorial step definition
class TutorialStepDef {
  final String id;
  final String title;
  final String description;
  final String? emoji;

  const TutorialStepDef({
    required this.id,
    required this.title,
    required this.description,
    this.emoji,
  });
}

/// Service to manage tutorial state and progress with ShowcaseView
///
/// This service uses a CENTRALIZED approach:
/// - Only ONE ShowCaseWidget exists (in HMTutorialOverlay)
/// - Context is stored and reused for all tutorials
/// - Tutorials are triggered per-tab on first visit
/// - Mutex lock prevents concurrent tutorials
class TutorialService extends GetxService {
  late final StorageService _storage;

  // Completed tutorials (persisted)
  final RxSet<String> completedTutorials = <String>{}.obs;

  // Current tutorial state
  final RxBool isShowingTutorial = false.obs;
  final RxString currentTutorialId = ''.obs;

  // Key registry for Showcase widgets
  final Map<String, GlobalKey> _keyRegistry = {};

  // ShowCaseWidget context (set by HMTutorialOverlay)
  BuildContext? _showcaseContext;

  // Track which tabs had their tutorials triggered (session only)
  final Set<int> _triggeredTabs = {};

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _loadCompletedTutorials();
  }

  void _loadCompletedTutorials() {
    final completed = _storage.getCompletedTutorials();
    completedTutorials.addAll(completed);
    debugPrint('📚 Loaded ${completedTutorials.length} completed tutorials');
  }

  // ===== CONTEXT MANAGEMENT =====

  /// Set the ShowCaseWidget context (called by HMTutorialOverlay)
  void setShowcaseContext(BuildContext context) {
    _showcaseContext = context;
  }

  /// Check if context is available
  bool get hasContext => _showcaseContext != null;

  // ===== KEY MANAGEMENT =====

  /// Register a GlobalKey for a showcase target
  GlobalKey registerKey(String keyId) {
    if (!_keyRegistry.containsKey(keyId)) {
      _keyRegistry[keyId] = GlobalKey();
    }
    return _keyRegistry[keyId]!;
  }

  /// Get a registered key
  GlobalKey? getKey(String keyId) => _keyRegistry[keyId];

  /// Get all keys for a tutorial
  List<GlobalKey> getKeysForTutorial(String tutorialId) {
    final steps = _getStepsForTutorial(tutorialId);
    return steps
        .map((step) => _keyRegistry[step.id])
        .whereType<GlobalKey>()
        .toList();
  }

  List<TutorialStepDef> _getStepsForTutorial(String tutorialId) {
    switch (tutorialId) {
      case TutorialDefinitions.todayTutorialId:
        return TutorialDefinitions.todaySteps;
      case TutorialDefinitions.learnTutorialId:
        return TutorialDefinitions.learnSteps;
      case TutorialDefinitions.exploreTutorialId:
        return TutorialDefinitions.exploreSteps;
      case TutorialDefinitions.meTutorialId:
        return TutorialDefinitions.meSteps;
      case TutorialDefinitions.hskExamTutorialId:
        return TutorialDefinitions.hskExamSteps;
      default:
        return [];
    }
  }

  // ===== TAB-BASED TUTORIAL CONTROL =====

  /// Try to start tutorial for a specific tab
  /// Called by ShellController when tab changes
  void tryStartTutorialForTab(int tabIndex) {
    // Already triggered this session?
    if (_triggeredTabs.contains(tabIndex)) return;

    // Get tutorial ID for this tab
    final tutorialId = TutorialDefinitions.getTutorialIdForTab(tabIndex);
    if (tutorialId == null) return;

    // Already completed?
    if (!shouldShowTutorial(tutorialId)) {
      _triggeredTabs.add(tabIndex);
      return;
    }

    // Already showing another tutorial?
    if (isShowingTutorial.value) return;

    // No context available?
    if (_showcaseContext == null) {
      debugPrint('⚠️ No showcase context available');
      return;
    }

    // Mark as triggered
    _triggeredTabs.add(tabIndex);

    // Get keys for this tutorial
    final keys = getKeysForTutorial(tutorialId);
    if (keys.isEmpty) {
      debugPrint('⚠️ No keys registered for tutorial: $tutorialId');
      return;
    }

    // Check if all keys have their widgets mounted
    final validKeys = keys.where((k) => k.currentContext != null).toList();
    if (validKeys.isEmpty) {
      debugPrint('⚠️ Keys not mounted yet for: $tutorialId');
      // Try again after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _startShowcaseWithKeys(tutorialId, keys);
      });
      return;
    }

    // Start immediately if keys are ready
    _startShowcaseWithKeys(tutorialId, validKeys);
  }

  void _startShowcaseWithKeys(String tutorialId, List<GlobalKey> keys) {
    if (isShowingTutorial.value) return;
    if (_showcaseContext == null) return;

    // Filter to only mounted keys
    final mountedKeys = keys.where((k) => k.currentContext != null).toList();
    if (mountedKeys.isEmpty) {
      debugPrint('⚠️ No mounted keys for: $tutorialId');
      return;
    }

    // Set state
    currentTutorialId.value = tutorialId;
    isShowingTutorial.value = true;

    debugPrint(
      '🎯 Starting tutorial: $tutorialId with ${mountedKeys.length} steps',
    );

    // Start showcase
    try {
      ShowCaseWidget.of(_showcaseContext!).startShowCase(mountedKeys);
    } catch (e) {
      debugPrint('❌ Error starting showcase: $e');
      isShowingTutorial.value = false;
      currentTutorialId.value = '';
    }
  }

  // ===== TUTORIAL CONTROL =====

  /// Check if a tutorial should be shown
  bool shouldShowTutorial(String tutorialId) {
    return !completedTutorials.contains(tutorialId);
  }

  /// Called by HMTutorialOverlay when showcase finishes
  void onShowcaseComplete() {
    if (currentTutorialId.value.isNotEmpty) {
      completeTutorial(currentTutorialId.value);
    }
  }

  /// Mark a tutorial as completed
  void completeTutorial(String tutorialId) {
    completedTutorials.add(tutorialId);
    _storage.setCompletedTutorials(completedTutorials.toList());
    isShowingTutorial.value = false;
    currentTutorialId.value = '';
    debugPrint('✅ Completed tutorial: $tutorialId');
  }

  /// Reset all tutorials (for Settings page)
  void resetAllTutorials() {
    completedTutorials.clear();
    _triggeredTabs.clear();
    _storage.setCompletedTutorials([]);
    isShowingTutorial.value = false;
    currentTutorialId.value = '';
    debugPrint('🔄 All tutorials have been reset');
  }

  /// Skip current tutorial
  void skipTutorial() {
    if (currentTutorialId.value.isNotEmpty) {
      completeTutorial(currentTutorialId.value);
    }
  }

  // ===== STEP INFO =====

  /// Get step info for a key
  TutorialStepDef? getStepInfo(String keyId) {
    for (final steps in [
      TutorialDefinitions.todaySteps,
      TutorialDefinitions.exploreSteps,
      TutorialDefinitions.meSteps,
      TutorialDefinitions.hskExamSteps,
    ]) {
      final step = steps.where((s) => s.id == keyId).firstOrNull;
      if (step != null) return step;
    }
    return null;
  }

  /// Get step index
  int getStepIndex(String tutorialId, String keyId) {
    final steps = _getStepsForTutorial(tutorialId);
    return steps.indexWhere((s) => s.id == keyId) + 1;
  }

  /// Get total steps
  int getTotalSteps(String tutorialId) {
    return _getStepsForTutorial(tutorialId).length;
  }
}

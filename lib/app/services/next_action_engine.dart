import '../data/models/today_model.dart';
import '../routes/app_routes.dart';

/// Recommended action for the user
/// Priority: Review → Learn New → Quick Practice → Game
class RecommendedAction {
  final String id;
  final String title;
  final String subtitle;
  final int etaMinutes;
  final String primaryButtonText;
  final String route;
  final Map<String, dynamic>? payload;
  final ActionPriority priority;
  final String icon;

  RecommendedAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.etaMinutes,
    required this.primaryButtonText,
    required this.route,
    this.payload,
    required this.priority,
    required this.icon,
  });
}

/// Action priority levels
enum ActionPriority {
  critical, // Review queue >= 10
  high, // New words available
  medium, // Quick practice
  low, // Games / Optional
}

/// Next Action Engine - determines what user should do next
class NextActionEngine {
  NextActionEngine._();

  /// Compute the best next action based on today's data
  /// 
  /// PRIORITY ORDER (quan trọng!):
  /// 0. isNewQueueLocked from API → BẮT BUỘC ôn tập/master trước
  /// 1. Streak at risk → Học ngay để giữ streak (nếu không bị block)
  /// 2. Còn quota từ mới → "Học ngay" (MAIN ACTION)
  /// 3. Đã học đủ quota + có từ vừa học → "Củng cố từ vừa học"
  /// 4. Có review SRS → "Ôn tập SRS"
  /// 5. Game 30s (fallback)
  static RecommendedAction computeNextAction(TodayModel today) {
    final reviewCount = today.reviewQueue.length;
    final remainingNew = today.remainingNewLimit;
    final learnedToday = today.newLearnedToday;
    final dailyLimit = today.dailyNewLimit;
    final hasStudiedToday = today.streakStatus?.hasStudiedToday ?? false;

    // 🚨 Priority 0: API says new queue is LOCKED
    if (today.isNewQueueLocked) {
      // Check lock reason
      if (today.isBlockedByReviewOverload) {
        // Review overload - must review first
        final info = today.reviewOverloadInfo;
        return RecommendedAction(
          id: 'review_overload',
          title: '⚠️ Quá tải ôn tập!',
          subtitle: info?.message ?? 'Có $reviewCount từ cần ôn. Hãy ôn bớt để học tiếp!',
          etaMinutes: _estimateMinutes(info?.excessCount ?? reviewCount),
          primaryButtonText: 'Ôn tập ngay',
          route: Routes.srsReviewList,
          payload: null,
          priority: ActionPriority.critical,
          icon: '📚',
        );
      } else if (today.isBlockedByMastery) {
        // Mastery required - must master current batch
        final req = today.unlockRequirement;
        return RecommendedAction(
          id: 'mastery_required',
          title: '🎯 Cần master từ đã học!',
          subtitle: req?.message ?? 'Hãy ôn tập để master ${req?.wordsToMaster ?? 0} từ còn lại',
          etaMinutes: _estimateMinutes(req?.wordsToMaster ?? 10),
          primaryButtonText: 'Ôn tập để master',
          route: Routes.srsReviewList,
          payload: null,
          priority: ActionPriority.critical,
          icon: '🎯',
        );
      }
    }

    // Priority 1: Streak at risk - encourage to start learning
    if (!hasStudiedToday && today.streak > 0) {
      // Nếu còn quota và không bị lock → học mới, không thì ôn tập
      final shouldLearnNew = remainingNew > 0 && !today.isNewQueueLocked;
      return RecommendedAction(
        id: 'maintain_streak',
        title: 'Duy trì chuỗi ${today.streak} ngày! 🔥',
        subtitle: shouldLearnNew 
            ? 'Học từ mới để giữ streak' 
            : 'Ôn tập để giữ streak',
        etaMinutes: 3,
        primaryButtonText: shouldLearnNew ? 'Học ngay' : 'Ôn tập ngay',
        route: Routes.practice,
        payload: {'mode': shouldLearnNew ? 'learn_new' : 'review_srs'},
        priority: ActionPriority.critical,
        icon: '🔥',
      );
    }

    // Priority 2: CÒN QUOTA TỪ MỚI + KHÔNG BỊ LOCK → "HỌC NGAY" (MAIN ACTION)
    if (remainingNew > 0 && !today.isNewQueueLocked) {
      // Mỗi session học 5 từ (SessionConfig.learnNew.vocabCount = 5)
      const wordsPerSession = 5;
      final sessionsNeeded = (remainingNew / wordsPerSession).ceil();
      return RecommendedAction(
        id: 'learn_new',
        title: 'Học $remainingNew từ mới',
        subtitle: 'Đã học $learnedToday/$dailyLimit từ hôm nay • $sessionsNeeded lượt',
        etaMinutes: _estimateMinutes(wordsPerSession, isNew: true),
        primaryButtonText: 'Học ngay',
        route: Routes.practice,
        payload: {'mode': 'learn_new'},
        priority: ActionPriority.high,
        icon: '✨',
      );
    }

    // Priority 3: ĐÃ HỌC ĐỦ QUOTA → Hiện trạng thái hoàn thành
    // Không cho phép "củng cố ngay" liên tục vì sẽ dẫn đến học thêm từ mới
    if (learnedToday >= dailyLimit) {
      // Đã hoàn thành mục tiêu hôm nay
      if (reviewCount > 0) {
        // Có từ cần ôn tập SRS → chuyển sang ôn tập
        return RecommendedAction(
          id: 'completed_review',
          title: 'Hoàn thành $dailyLimit từ! 🎉',
          subtitle: 'Ôn tập $reviewCount từ SRS để củng cố',
          etaMinutes: _estimateMinutes(reviewCount),
          primaryButtonText: 'Ôn tập SRS',
          route: Routes.practice,
          payload: {'mode': 'review_srs'},
          priority: ActionPriority.medium,
          icon: '🏆',
        );
      }
      // Không có gì để làm → chơi game hoặc nghỉ ngơi
      return RecommendedAction(
        id: 'completed_done',
        title: 'Hoàn thành $dailyLimit từ! 🎉',
        subtitle: 'Tuyệt vời! Hãy nghỉ ngơi hoặc chơi game',
        etaMinutes: 1,
        primaryButtonText: 'Chơi game',
        route: Routes.game30Home,
        payload: null,
        priority: ActionPriority.low,
        icon: '🏆',
      );
    }

    // Priority 4: Có review SRS
    if (reviewCount > 0) {
      return RecommendedAction(
        id: 'review_srs',
        title: 'Ôn tập $reviewCount từ',
        subtitle: 'Từ vựng cần củng cố theo SRS',
        etaMinutes: _estimateMinutes(reviewCount),
        primaryButtonText: 'Ôn tập ngay',
        route: Routes.practice,
        payload: {'mode': 'review_srs'},
        priority: ActionPriority.medium,
        icon: '📚',
      );
    }

    // Priority 5: Game 30s (fallback - không có gì để làm)
    return RecommendedAction(
      id: 'game_30s',
      title: 'Chơi game 30 giây',
      subtitle: 'Thử thách trí nhớ của bạn!',
      etaMinutes: 1,
      primaryButtonText: 'Chơi ngay',
      route: Routes.game30Home,
      payload: null,
      priority: ActionPriority.low,
      icon: '🎮',
    );
  }

  /// Estimate minutes based on word count
  static int _estimateMinutes(int wordCount, {bool isNew = false}) {
    // New words take longer (~1.5 min each), review ~0.5 min each
    final perWord = isNew ? 1.5 : 0.5;
    return (wordCount * perWord).ceil().clamp(1, 30);
  }

  /// Get color for priority
  static String getPriorityColor(ActionPriority priority) {
    switch (priority) {
      case ActionPriority.critical:
        return '#FF6B6B'; // Red-orange
      case ActionPriority.high:
        return '#4ECDC4'; // Teal
      case ActionPriority.medium:
        return '#95E1D3'; // Light teal
      case ActionPriority.low:
        return '#A8E6CF'; // Light green
    }
  }
}


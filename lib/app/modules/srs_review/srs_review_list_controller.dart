import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/models/vocab_model.dart';
import '../../routes/app_routes.dart';
import '../../services/local_today_service.dart';
import '../../services/local_progress_service.dart';

/// SRS Review List Controller - Manages the list of words due for review
///
/// OFFLINE-FIRST: Uses LocalTodayService (SQLite) as primary data source.
/// Review queue updates immediately after each review answer.
class SrsReviewListController extends GetxController {
  late final LocalTodayService _localTodayService;
  LocalProgressService? _localProgress;

  // State
  final RxBool isLoading = true.obs;
  final RxBool isStartingReview = false.obs;
  final RxList<VocabModel> reviewQueue = <VocabModel>[].obs;

  /// Maximum review words before blocking new learning
  static const int maxReviewBeforeBlock = 50;

  @override
  void onInit() {
    super.onInit();
    _localTodayService = Get.find<LocalTodayService>();

    try {
      _localProgress = Get.find<LocalProgressService>();
    } catch (_) {
      Logger.w('SrsReviewListController', 'LocalProgressService not available');
    }

    _loadReviewQueue();
  }

  /// Load review queue from LocalTodayService (LOCAL SQLite)
  void _loadReviewQueue() {
    isLoading.value = true;

    try {
      // Get from local SQLite
      final today = _localTodayService.today.value;
      if (today != null) {
        reviewQueue.value = today.reviewQueue.toList();
      }

      // Listen for LocalTodayService updates (rebuilds after progress changes)
      ever(_localTodayService.today, (data) {
        if (data != null) {
          reviewQueue.value = data.reviewQueue.toList();
          Logger.d(
            'SrsReviewListController',
            '📊 Review queue updated: ${data.reviewQueue.length} items',
          );
        }
      });

      // Also listen to progress updates to trigger rebuild if needed
      if (_localProgress != null) {
        _localProgress!.onProgressUpdate.listen((_) {
          // LocalTodayService already listens to this, but ensure we refresh
          Logger.d(
            'SrsReviewListController',
            '📊 Progress updated, refreshing...',
          );
        });
      }
    } catch (e) {
      Logger.e('SrsReviewListController', 'Failed to load review queue', e);
      HMToast.error('Không thể tải danh sách ôn tập');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh data - rebuilds TodayModel from local SQLite
  @override
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      // Rebuild TodayModel from local SQLite (fast, no network)
      await _localTodayService.refresh();

      final today = _localTodayService.today.value;
      if (today != null) {
        reviewQueue.value = today.reviewQueue.toList();
      }
    } catch (e) {
      Logger.e('SrsReviewListController', 'Failed to refresh', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Open word detail
  void openWordDetail(VocabModel vocab) {
    Get.toNamed(Routes.wordDetail, arguments: vocab);
  }

  /// Start SRS review session
  void startReview() {
    if (reviewQueue.isEmpty) {
      HMToast.info('Không có từ nào cần ôn!');
      return;
    }

    isStartingReview.value = true;

    try {
      Get.toNamed(Routes.practice, arguments: {'mode': 'review_srs'});
    } catch (e) {
      Logger.e('SrsReviewListController', 'Failed to start review', e);
      HMToast.error('Không thể bắt đầu ôn tập');
    } finally {
      isStartingReview.value = false;
    }
  }

  /// Check if new word learning should be blocked
  bool get isNewLearningBlocked => reviewQueue.length > maxReviewBeforeBlock;

  /// Get the number of words to review before unblocking
  int get wordsToReviewBeforeUnblock =>
      (reviewQueue.length - maxReviewBeforeBlock).clamp(0, reviewQueue.length);
}

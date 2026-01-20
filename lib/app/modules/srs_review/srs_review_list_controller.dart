import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/models/vocab_model.dart';
import '../../routes/app_routes.dart';
import '../../services/realtime/today_store.dart';

/// SRS Review List Controller - Manages the list of words due for review
class SrsReviewListController extends GetxController {
  final TodayStore _todayStore = Get.find<TodayStore>();

  // State
  final RxBool isLoading = true.obs;
  final RxBool isStartingReview = false.obs;
  final RxList<VocabModel> reviewQueue = <VocabModel>[].obs;

  /// Maximum review words before blocking new learning
  static const int maxReviewBeforeBlock = 50;

  @override
  void onInit() {
    super.onInit();
    _loadReviewQueue();
  }

  /// Load review queue from TodayStore
  void _loadReviewQueue() {
    isLoading.value = true;

    try {
      final today = _todayStore.today.data.value;
      if (today != null) {
        reviewQueue.value = today.reviewQueue.toList();
      }

      // Listen for updates
      ever(_todayStore.today.data, (data) {
        if (data != null) {
          reviewQueue.value = data.reviewQueue.toList();
        }
      });
    } catch (e) {
      Logger.e('SrsReviewListController', 'Failed to load review queue', e);
      HMToast.error('Không thể tải danh sách ôn tập');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      await _todayStore.syncNow(force: true);
      final today = _todayStore.today.data.value;
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
      Get.toNamed(
        Routes.practice,
        arguments: {'mode': 'review_srs'},
      );
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


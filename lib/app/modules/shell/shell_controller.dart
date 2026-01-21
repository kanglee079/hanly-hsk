import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/realtime/realtime_sync_service.dart';
import '../../services/tutorial_service.dart';
import '../today/today_controller.dart';

/// Shell controller for bottom navigation with instant smooth transitions
/// All tab controllers are initialized immediately in ShellBinding for best UX
class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();

  // GlobalKey for bottom nav - managed by controller to prevent duplicate key issue
  // when navigating away and back to shell (e.g., switching accounts)
  final GlobalKey bottomNavKey = GlobalKey(debugLabel: 'bottomNav');

  @override
  void onInit() {
    super.onInit();
    // Notify tab controllers when tab changes
    ever(currentIndex, _onTabChanged);

    // Trigger initial tab tutorial after a delay (for first launch)
    Future.delayed(const Duration(milliseconds: 1500), () {
      _tryStartTutorialForCurrentTab();
    });
  }

  void _onTabChanged(int index) {
    // Light haptic feedback for tab change
    HapticFeedback.selectionClick();

    // Notify TodayController when Today tab becomes visible
    if (index == 0) {
      if (Get.isRegistered<TodayController>()) {
        Get.find<TodayController>().onScreenVisible();
      }
    }

    // Trigger tutorial for the new tab (with delay for UI to settle)
    Future.delayed(const Duration(milliseconds: 800), () {
      _tryStartTutorialForCurrentTab();
    });
  }

  /// Try to start tutorial for the currently active tab
  void _tryStartTutorialForCurrentTab() {
    if (!Get.isRegistered<TutorialService>()) return;

    final tutorialService = Get.find<TutorialService>();
    tutorialService.tryStartTutorialForTab(currentIndex.value);
  }

  /// Change to a specific tab with instant crossfade transition
  void changePage(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
  }

  // Debounce: track last full sync time to prevent burst calls
  static DateTime? _lastFullSync;

  /// Force a realtime sync for key resources (useful after completing a session).
  /// Debounced to prevent excessive API calls.
  Future<void> refreshAllData() async {
    final now = DateTime.now();
    // Skip if synced within last 30 seconds
    if (_lastFullSync != null &&
        now.difference(_lastFullSync!).inSeconds < 30) {
      return;
    }
    _lastFullSync = now;

    // Only sync essential resources, not all
    await _rt.syncNowKeys(const [
      'today',
      'learnedToday',
      'todayForecast',
    ], force: true);
    // Also refresh local cache counts
    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().onScreenVisible();
    }
  }
}

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/realtime/realtime_sync_service.dart';
import '../../services/tutorial_service.dart';
import '../../services/tutorial_flows.dart';
import '../today/today_controller.dart';

/// Shell controller for bottom navigation with instant smooth transitions
/// All tab controllers are initialized immediately in ShellBinding for best UX
class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();
  
  // Track which tutorials have been triggered
  final Set<String> _triggeredTutorials = {};

  @override
  void onInit() {
    super.onInit();
    // Notify tab controllers when tab changes
    ever(currentIndex, _onTabChanged);
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
    
    // Trigger Learn tab tutorial when first visiting
    if (index == 1 && !_triggeredTutorials.contains('learn_tab_v1')) {
      _maybeStartLearnTutorial();
    }
  }
  
  void _maybeStartLearnTutorial() {
    if (!Get.isRegistered<TutorialService>()) return;
    
    final tutorialService = Get.find<TutorialService>();
    
    // Don't start if another tutorial is showing or already completed
    if (tutorialService.isShowingTutorial.value) return;
    if (!tutorialService.shouldShowTutorial('learn_tab_v1')) return;
    
    _triggeredTutorials.add('learn_tab_v1');
    
    // Delay to let the screen render
    Future.delayed(const Duration(milliseconds: 800), () {
      if (currentIndex.value == 1 && 
          tutorialService.shouldShowTutorial('learn_tab_v1') &&
          !tutorialService.isShowingTutorial.value) {
        tutorialService.startTutorial(TutorialFlows.learnTabTutorial);
      }
    });
  }

  /// Change to a specific tab with instant crossfade transition
  void changePage(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
  }
  
  /// Force a realtime sync for key resources (useful after completing a session).
  Future<void> refreshAllData() async {
    await _rt.syncNowAll(force: true);
    // Also refresh local cache counts
    if (Get.isRegistered<TodayController>()) {
      Get.find<TodayController>().onScreenVisible();
    }
  }
}

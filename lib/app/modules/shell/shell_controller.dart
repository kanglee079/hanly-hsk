import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/realtime/realtime_sync_service.dart';
import '../today/today_controller.dart';

/// Shell controller for bottom navigation with smooth transitions
/// All tab controllers are initialized immediately in ShellBinding for best UX
class ShellController extends GetxController {
  final RxInt currentIndex = 0.obs;
  
  late final PageController pageController;
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    
    // Notify tab controllers when tab changes
    ever(currentIndex, _onTabChanged);
  }
  
  void _onTabChanged(int index) {
    // Notify TodayController when Today tab becomes visible
    if (index == 0) {
      if (Get.isRegistered<TodayController>()) {
        Get.find<TodayController>().onScreenVisible();
      }
    }
  }

  void changePage(int index) {
    if (currentIndex.value == index) return;
    
    currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void onPageChanged(int index) {
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

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

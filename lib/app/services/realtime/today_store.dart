import 'dart:async';

import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/models/today_model.dart';
import '../local_today_service.dart';

/// Single source of truth for "Today" domain.
///
/// OFFLINE-FIRST: Uses LocalTodayService to build TodayModel from SQLite.
/// NO API POLLING - all data comes from local database.
/// Server sync happens in background via ProgressSyncService.
class TodayStore extends GetxService {
  LocalTodayService? _localTodayService;

  // Expose today data from LocalTodayService
  Rx<TodayModel?> get today =>
      _localTodayService?.today ?? Rx<TodayModel?>(null);

  // Event trigger for immediate UI updates (listenable)
  final RxInt onLearnedUpdate = 0.obs;

  /// Local "now" ticker to drive countdown UI without hitting backend.
  final Rx<DateTime> now = DateTime.now().obs;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();

    try {
      _localTodayService = Get.find<LocalTodayService>();
      Logger.i(
        'TodayStore',
        '✅ Using LocalTodayService (offline-first, no API polling)',
      );
    } catch (_) {
      Logger.w(
        'TodayStore',
        '⚠️ LocalTodayService not available, TodayModel will be null',
      );
    }

    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      now.value = DateTime.now();
    });
  }

  /// Refresh today data from local database
  /// NO API call - just rebuilds from SQLite
  Future<void> syncNow({bool force = false}) async {
    await _localTodayService?.refresh();
    onLearnedUpdate.value++;
    Logger.d('TodayStore', '🔄 Refreshed TodayModel from local DB');
  }

  /// Clear all cached data (called on logout to prevent cross-account data leakage)
  void clearAllData() {
    _localTodayService?.today.value = null;
    Logger.d('TodayStore', '🗑️ Cleared all cached data');
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}

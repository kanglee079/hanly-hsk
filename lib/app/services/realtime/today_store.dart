import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/today_model.dart';
import '../../data/repositories/dashboard_repo.dart';
import '../../data/repositories/learning_repo.dart';
import 'realtime_resource.dart';
import 'realtime_sync_service.dart';

/// Single source of truth for "Today" domain.
///
/// Owns:
/// - GET /today
/// - (optional) GET /today/forecast
/// - (optional) GET /today/learned-today
/// - local ticker for time-based UI (e.g., streak countdown)
class TodayStore extends GetxService {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  DashboardRepo? _dashboardRepo;

  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();

  late final RealtimeResource<TodayModel> today;
  RealtimeResource<ForecastModel>? forecast;
  RealtimeResource<LearnedTodayModel>? learnedToday;

  // Event trigger for immediate UI updates (listenable)
  final RxInt onLearnedUpdate = 0.obs;

  /// Local "now" ticker to drive countdown UI without hitting backend.
  final Rx<DateTime> now = DateTime.now().obs;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();

    try {
      _dashboardRepo = Get.find<DashboardRepo>();
    } catch (_) {
      _dashboardRepo = null;
    }

    // OPTIMIZED: Reduced polling from 15s to 5 minutes
    // /today data changes rarely - only after learning sessions
    // Force sync is triggered after session completion anyway
    today = RealtimeResource<TodayModel>(
      key: 'today',
      interval: const Duration(minutes: 5),
      fetcher: () => _learningRepo.getToday(),
      fingerprinter: (v) => jsonEncode(v.toJson()),
    );
    _rt.register(today);

    if (_dashboardRepo != null) {
      forecast = RealtimeResource<ForecastModel>(
        key: 'todayForecast',
        // Forecast changes slowly; keep interval conservative.
        interval: const Duration(minutes: 5),
        fetcher: () => _dashboardRepo!.getForecast(days: 7),
        fingerprinter: (v) => jsonEncode(v.toJson()),
      );
      _rt.register(forecast!);

      learnedToday = RealtimeResource<LearnedTodayModel>(
        key: 'learnedToday',
        // Learned-today list may change after each session; poll moderately.
        interval: const Duration(minutes: 2),
        fetcher: () => _dashboardRepo!.getLearnedToday(),
        fingerprinter: (v) => jsonEncode(v.toJson()),
      );
      _rt.register(learnedToday!);
    } else {
      Logger.w(
        'TodayStore',
        'DashboardRepo not available; forecast/learnedToday disabled',
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

  Future<void> syncNow({bool force = false}) async {
    await _rt.syncNowKeys(const [
      'today',
      'todayForecast',
      'learnedToday',
    ], force: force);
  }

  /// Clear all cached data (called on logout to prevent cross-account data leakage)
  void clearAllData() {
    today.data.value = null;
    forecast?.data.value = null;
    learnedToday?.data.value = null;
    Logger.d('TodayStore', '🗑️ Cleared all cached data');
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}

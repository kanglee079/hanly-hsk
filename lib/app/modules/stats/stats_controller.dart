import 'package:get/get.dart';
import '../../data/repositories/me_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/request_guard.dart';

/// User stats and achievements controller
/// OPTIMIZED: Uses caching to prevent redundant API calls
class StatsController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();

  final RxBool isLoading = true.obs;
  final Rx<UserStats?> stats = Rx<UserStats?>(null);
  final RxList<Achievement> achievements = <Achievement>[].obs;
  final RxList<CalendarDay> calendar = <CalendarDay>[].obs;

  // Tab state
  final RxInt selectedTab = 0.obs;
  
  // Guard against duplicate initialization
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      loadData();
    }
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    // Prevent duplicate calls
    if (isLoading.value && !forceRefresh) return;
    
    // Skip if already have data and not forcing
    if (!forceRefresh && stats.value != null) return;
    
    isLoading.value = true;
    try {
      await Future.wait([
        loadStats(forceRefresh: forceRefresh),
        loadAchievements(forceRefresh: forceRefresh),
        loadCalendar(forceRefresh: forceRefresh),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats({bool forceRefresh = false}) async {
    try {
      // Cache stats for 10 minutes
      stats.value = await RequestGuard.memoize(
        'user_stats',
        () => _meRepo.getStats(),
        ttl: const Duration(minutes: 10),
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      Logger.e('StatsController', 'loadStats error', e);
    }
  }

  Future<void> loadAchievements({bool forceRefresh = false}) async {
    try {
      // Cache achievements for 1 hour (rarely changes)
      achievements.value = await RequestGuard.memoize(
        'user_achievements',
        () => _meRepo.getAchievements(),
        ttl: const Duration(hours: 1),
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      Logger.e('StatsController', 'loadAchievements error', e);
    }
  }

  Future<void> loadCalendar({bool forceRefresh = false}) async {
    try {
      // Cache calendar for 30 minutes
      calendar.value = await RequestGuard.memoize(
        'user_calendar',
        () => _meRepo.getCalendar(),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      Logger.e('StatsController', 'loadCalendar error', e);
    }
  }

  void setTab(int index) {
    selectedTab.value = index;
  }

  @override
  Future<void> refresh() async {
    await loadData(forceRefresh: true);
  }

  // Stats helpers
  List<Achievement> get unlockedAchievements =>
      achievements.where((a) => a.unlocked).toList();

  List<Achievement> get lockedAchievements =>
      achievements.where((a) => !a.unlocked).toList();

  int get streakDays {
    int streak = 0;
    final now = DateTime.now();
    for (var i = 0; i < calendar.length; i++) {
      final day = calendar[calendar.length - 1 - i];
      final diff = now.difference(day.date).inDays;
      if (diff == i && day.completed) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}


import 'package:get/get.dart';
import '../../data/repositories/me_repo.dart';
import '../../core/utils/logger.dart';

/// User stats and achievements controller
class StatsController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();

  final RxBool isLoading = true.obs;
  final Rx<UserStats?> stats = Rx<UserStats?>(null);
  final RxList<Achievement> achievements = <Achievement>[].obs;
  final RxList<CalendarDay> calendar = <CalendarDay>[].obs;

  // Tab state
  final RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadStats(),
        loadAchievements(),
        loadCalendar(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      stats.value = await _meRepo.getStats();
    } catch (e) {
      Logger.e('StatsController', 'loadStats error', e);
    }
  }

  Future<void> loadAchievements() async {
    try {
      achievements.value = await _meRepo.getAchievements();
    } catch (e) {
      Logger.e('StatsController', 'loadAchievements error', e);
    }
  }

  Future<void> loadCalendar() async {
    try {
      calendar.value = await _meRepo.getCalendar();
    } catch (e) {
      Logger.e('StatsController', 'loadCalendar error', e);
    }
  }

  void setTab(int index) {
    selectedTab.value = index;
  }

  @override
  Future<void> refresh() async {
    await loadData();
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


import 'package:get/get.dart';
import '../../data/repositories/me_repo.dart';
import '../../data/repositories/learning_repo.dart';
import '../../data/models/today_model.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_streak_bottom_sheet.dart';
import '../today/today_controller.dart';

/// Calendar day data for progress screen
class CalendarDayData {
  final int day; // 0 for empty cell
  final int minutes;
  final bool isToday;
  final double intensity; // 0-1 based on activity

  CalendarDayData({
    required this.day,
    this.minutes = 0,
    this.isToday = false,
    this.intensity = 0,
  });
}

/// Progress controller for streak and calendar view
class ProgressController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();
  final LearningRepo _learningRepo = Get.find<LearningRepo>();

  // Loading state
  final RxBool isLoading = true.obs;

  // Streak data
  final RxInt streak = 0.obs;
  final RxBool hasStreakFreeze = false.obs;

  // Stats
  final RxInt totalWords = 0.obs;
  final RxInt totalMinutes = 0.obs;
  final RxInt accuracy = 0.obs;
  final RxBool hasStudiedToday = false.obs;
  final RxString streakRank = ''.obs;

  // Calendar
  final RxInt currentMonth = DateTime.now().month.obs;
  final RxInt currentYear = DateTime.now().year.obs;
  final RxString currentMonthLabel = ''.obs;
  final RxList<CalendarDayData> calendarDays = <CalendarDayData>[].obs;

  // Calendar data from API
  final RxList<DayProgress> _weeklyProgress = <DayProgress>[].obs;
  final RxMap<String, DayProgress> _calendarMap = <String, DayProgress>{}.obs;

  // Goal
  final RxString nextGoal = 'Đạt cột mốc 30 ngày'.obs;
  final RxInt goalProgress = 0.obs;
  final RxInt goalTarget = 30.obs;

  @override
  void onInit() {
    super.onInit();
    _updateMonthLabel();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      // Load today data for streak and weekly progress
      final todayData = await _learningRepo.getToday();
      
      streak.value = todayData.streak;
      streakRank.value = todayData.streakRank;
      hasStudiedToday.value = todayData.completedMinutes > 0;
      totalWords.value = todayData.totalLearned;
      totalMinutes.value = todayData.completedMinutes;
      accuracy.value = todayData.todayAccuracy;
      _weeklyProgress.value = todayData.weeklyProgress;

      // Build calendar map from weekly progress
      for (final day in _weeklyProgress) {
        _calendarMap[day.date] = day;
      }

      // Try to load calendar data from me/calendar
      try {
        final calendar = await _meRepo.getCalendar();
        for (final day in calendar) {
          final dateStr = '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
          _calendarMap[dateStr] = DayProgress(
            date: dateStr,
            minutes: day.minutes,
            newCount: day.newCount,
            reviewCount: day.reviewCount,
            accuracy: day.accuracy.round(),
          );
        }
      } catch (e) {
        // Calendar API might not be available, use weekly progress
        Logger.w('ProgressController', 'Calendar API not available: $e');
      }

      // Update goal based on streak
      _updateGoal();

      // Generate calendar grid
      _generateCalendar();
    } catch (e) {
      Logger.e('ProgressController', 'Error loading data', e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await _loadData();
  }

  void _updateGoal() {
    final s = streak.value;
    if (s < 7) {
      nextGoal.value = 'Đạt cột mốc 7 ngày';
      goalTarget.value = 7;
      goalProgress.value = s;
    } else if (s < 30) {
      nextGoal.value = 'Đạt cột mốc 30 ngày';
      goalTarget.value = 30;
      goalProgress.value = s;
    } else if (s < 100) {
      nextGoal.value = 'Đạt cột mốc 100 ngày';
      goalTarget.value = 100;
      goalProgress.value = s;
    } else if (s < 365) {
      nextGoal.value = 'Đạt cột mốc 365 ngày';
      goalTarget.value = 365;
      goalProgress.value = s;
    } else {
      nextGoal.value = 'Duy trì streak!';
      goalTarget.value = s;
      goalProgress.value = s;
    }
  }

  void _updateMonthLabel() {
    const months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    currentMonthLabel.value = '${months[currentMonth.value]} ${currentYear.value}';
  }

  void previousMonth() {
    if (currentMonth.value == 1) {
      currentMonth.value = 12;
      currentYear.value--;
    } else {
      currentMonth.value--;
    }
    _updateMonthLabel();
    _generateCalendar();
  }

  void nextMonth() {
    final now = DateTime.now();
    // Don't go past current month
    if (currentYear.value == now.year && currentMonth.value >= now.month) {
      return;
    }
    
    if (currentMonth.value == 12) {
      currentMonth.value = 1;
      currentYear.value++;
    } else {
      currentMonth.value++;
    }
    _updateMonthLabel();
    _generateCalendar();
  }

  /// Get weekly streak data for bottom sheet
  List<StreakDayData> get weeklyStreakData {
    return _weeklyProgress.map((day) {
      final dt = DateTime.tryParse(day.date);
      return StreakDayData(
        dayOfWeek: dt?.weekday ?? 1,
        isCompleted: day.minutes > 0,
        isToday: day.isToday,
        minutes: day.minutes,
      );
    }).toList();
  }
  
  /// Show streak details bottom sheet
  void showStreakDetails() {
    try {
      Get.find<TodayController>().showStreakDetails();
    } catch (_) {
      // Fallback
      HMStreakBottomSheet.show(
        streak: streak.value,
        hasStudiedToday: hasStudiedToday.value,
        completedMinutes: totalMinutes.value,
        weeklyData: weeklyStreakData,
      );
    }
  }

  void _generateCalendar() {
    final year = currentYear.value;
    final month = currentMonth.value;
    final today = DateTime.now();

    // First day of month
    final firstDay = DateTime(year, month, 1);
    // Last day of month
    final lastDay = DateTime(year, month + 1, 0);
    
    // Monday = 1, Sunday = 7
    // We want to start from Monday
    int startWeekday = firstDay.weekday; // 1-7
    
    List<CalendarDayData> days = [];
    
    // Add empty cells for days before first of month
    for (int i = 1; i < startWeekday; i++) {
      days.add(CalendarDayData(day: 0));
    }

    // Find max minutes for intensity calculation
    int maxMinutes = 1;
    for (int d = 1; d <= lastDay.day; d++) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final progress = _calendarMap[dateStr];
      if (progress != null && progress.minutes > maxMinutes) {
        maxMinutes = progress.minutes;
      }
    }

    // Add days of month
    for (int d = 1; d <= lastDay.day; d++) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      final progress = _calendarMap[dateStr];
      final minutes = progress?.minutes ?? 0;
      final isToday = year == today.year && month == today.month && d == today.day;

      days.add(CalendarDayData(
        day: d,
        minutes: minutes,
        isToday: isToday,
        intensity: minutes > 0 ? (minutes / maxMinutes).clamp(0.3, 1.0) : 0,
      ));
    }

    // Pad to complete last week
    while (days.length % 7 != 0) {
      days.add(CalendarDayData(day: 0));
    }

    calendarDays.value = days;
  }
}


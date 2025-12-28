import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/me_repo.dart';
import '../../services/auth_session_service.dart';
import '../../services/realtime/today_store.dart';
import '../../core/widgets/hm_toast.dart';
import '../../routes/app_routes.dart';

/// Onboarding controller - single page form
class OnboardingController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();

  final displayNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Form fields
  final RxString displayName = ''.obs;
  final Rx<GoalType?> goalType = Rx<GoalType?>(GoalType.hskExam);
  final RxInt currentLevel = 1.obs;
  final RxInt dailyWords = 10.obs; // Primary: number of words per day
  final RxBool listeningEnabled = false.obs;
  final RxBool hanziEnabled = true.obs;
  final RxBool notificationsEnabled = false.obs;
  final RxBool isLoading = false.obs;

  final List<int> dailyWordsOptions = [5, 10, 20, 30];
  final List<int> levelOptions = [1, 2, 3, 4, 5, 6];

  @override
  void onInit() {
    super.onInit();
    displayNameController.addListener(
      () => displayName.value = displayNameController.text,
    );
  }

  @override
  void onClose() {
    displayNameController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  bool get canSubmit => displayName.value.trim().length >= 2;

  void setGoalType(GoalType type) {
    goalType.value = type;
  }

  void setLevel(int level) {
    currentLevel.value = level;
  }

  void setDailyWords(int words) {
    dailyWords.value = words;
  }

  void toggleListening() {
    listeningEnabled.value = !listeningEnabled.value;
  }

  void toggleHanzi() {
    hanziEnabled.value = !hanziEnabled.value;
  }

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
  }

  /// Get daily new word limit (direct from selection)
  int get dailyNewLimit => dailyWords.value;

  /// Get daily minutes based on word count
  int get dailyMinutes {
    switch (dailyWords.value) {
      case 5:
        return 5;
      case 10:
        return 15;
      case 20:
        return 30;
      case 30:
        return 45;
      default:
        return 15;
    }
  }

  /// Get description for daily word goal
  String get dailyWordsDescription {
    switch (dailyWords.value) {
      case 5:
        return 'Nhẹ nhàng • Khoảng 5 phút mỗi ngày';
      case 10:
        return 'Vừa sức • Khoảng 15 phút mỗi ngày';
      case 20:
        return 'Tích cực • Khoảng 30 phút mỗi ngày';
      case 30:
        return 'Chuyên sâu • Khoảng 45 phút mỗi ngày';
      default:
        return '';
    }
  }

  /// Compute focus weights
  Map<String, double> get focusWeights {
    final listening = listeningEnabled.value ? 1.0 : 0.0;
    final hanzi = hanziEnabled.value ? 1.0 : 0.0;
    final total = listening + hanzi + 1.0; // meaning is always 1.0

    return {
      'listening': listening / total,
      'hanzi': hanzi / total,
      'meaning': 1.0 / total,
    };
  }

  void skip() {
    // Skip onboarding and go to shell with default values
    _submitProfile();
  }

  Future<void> submitProfile() async {
    if (!canSubmit) {
      HMToast.error('Vui lòng nhập tên hiển thị (ít nhất 2 ký tự)');
      return;
    }
    await _submitProfile();
  }

  Future<void> _submitProfile() async {
    isLoading.value = true;

    final name = displayName.value.trim().isEmpty
        ? 'Học viên'
        : displayName.value.trim();

    final success = await _authService.submitOnboarding(
      displayName: name,
      goalType: goalType.value?.apiValue ?? 'both',
      currentLevel: 'HSK${currentLevel.value}',
      dailyMinutesTarget: dailyMinutes,
      dailyNewLimit: dailyNewLimit,
      focusWeights: focusWeights,
      notificationsEnabled: notificationsEnabled.value,
    );

    if (success) {
      // WORKAROUND: BE ignores dailyNewLimit in /me/onboarding
      // So we call /me/profile to explicitly set the correct value
      try {
        final meRepo = Get.find<MeRepo>();
        await meRepo.updateProfile({
          'dailyNewLimit': dailyNewLimit,
          'dailyMinutesTarget': dailyMinutes,
        });
        
        // Refresh user data to get updated profile
        await _authService.fetchCurrentUser();
        
        // Force sync TodayStore to get updated data from BE
        final todayStore = Get.find<TodayStore>();
        await todayStore.syncNow(force: true);
      } catch (e) {
        // Continue even if workaround fails - user can adjust later
        debugPrint('Onboarding workaround failed: $e');
      }
      
      isLoading.value = false;
      HMToast.success('Đã tạo hồ sơ thành công!');
      Get.offAllNamed(Routes.shell);
    } else {
      isLoading.value = false;
      HMToast.error('Không thể tạo hồ sơ. Vui lòng thử lại.');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_session_service.dart';
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
  final RxInt dailyMinutes = 15.obs;
  final RxBool listeningEnabled = false.obs;
  final RxBool hanziEnabled = true.obs;
  final RxBool notificationsEnabled = false.obs;
  final RxBool isLoading = false.obs;

  final List<int> dailyMinutesOptions = [5, 15, 30, 45];
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

  void setDailyMinutes(int minutes) {
    dailyMinutes.value = minutes;
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

  /// Get daily new word limit based on minutes
  int get dailyNewLimit {
    switch (dailyMinutes.value) {
      case 5:
        return 5;
      case 15:
        return 10;
      case 30:
        return 20;
      case 45:
        return 30;
      default:
        return 10;
    }
  }

  /// Get description for daily minutes
  String get dailyMinutesDescription {
    switch (dailyMinutes.value) {
      case 5:
        return 'Nhẹ nhàng • Khoảng 5 từ mới mỗi ngày';
      case 15:
        return 'Vừa sức • Khoảng 10 từ mới mỗi ngày';
      case 30:
        return 'Tích cực • Khoảng 20 từ mới mỗi ngày';
      case 45:
        return 'Chuyên sâu • Khoảng 30 từ mới mỗi ngày';
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
      dailyMinutesTarget: dailyMinutes.value,
      focusWeights: focusWeights,
      notificationsEnabled: notificationsEnabled.value,
    );

    isLoading.value = false;

    if (success) {
      HMToast.success('Đã tạo hồ sơ thành công!');
      Get.offAllNamed(Routes.shell);
    } else {
      HMToast.error('Không thể tạo hồ sơ. Vui lòng thử lại.');
    }
  }
}

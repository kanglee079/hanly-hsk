import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_session_service.dart';
import '../../services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';

class SetupController extends GetxController {
  final pageController = PageController();
  final currentStep = 0.obs;
  final isLoading = false.obs;
  
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final StorageService _storage = Get.find<StorageService>();

  // Step 1: Name
  final nameController = TextEditingController();
  final nameValid = false.obs;

  // Step 2: Level
  final selectedLevel = ''.obs;
  final levels = [
    LevelOption(id: 'HSK1', title: 'Mới bắt đầu', subtitle: 'HSK 1', icon: '🌱'),
    LevelOption(id: 'HSK2', title: 'Cơ bản', subtitle: 'HSK 2', icon: '📗'),
    LevelOption(id: 'HSK3', title: 'Sơ cấp', subtitle: 'HSK 3', icon: '📘'),
    LevelOption(id: 'HSK4', title: 'Trung cấp', subtitle: 'HSK 4', icon: '📙'),
    LevelOption(id: 'HSK5', title: 'Cao cấp', subtitle: 'HSK 5', icon: '📕'),
    LevelOption(id: 'HSK6', title: 'Thành thạo', subtitle: 'HSK 6', icon: '🎓'),
  ];

  // Step 3: Goals (multi-select)
  final selectedGoals = <String>[].obs;
  final goals = [
    GoalOption(id: 'travel', title: 'Du lịch', icon: '✈️'),
    GoalOption(id: 'work', title: 'Công việc', icon: '💼'),
    GoalOption(id: 'exam', title: 'Thi HSK', icon: '📝'),
    GoalOption(id: 'daily', title: 'Giao tiếp hàng ngày', icon: '💬'),
    GoalOption(id: 'media', title: 'Xem phim/đọc sách', icon: '📺'),
  ];

  // Step 4: Daily word limit (1 word = 1 minute)
  final selectedWordLimit = 10.obs;
  final wordLimitOptions = [
    WordLimitOption(words: 3, title: '3 từ/ngày', subtitle: 'Nhẹ nhàng (~3 phút)', icon: '🌿'),
    WordLimitOption(words: 5, title: '5 từ/ngày', subtitle: 'Cơ bản (~5 phút)', icon: '📗'),
    WordLimitOption(words: 10, title: '10 từ/ngày', subtitle: 'Cân bằng (~10 phút)', icon: '⚖️'),
    WordLimitOption(words: 20, title: '20 từ/ngày', subtitle: 'Nghiêm túc (~20 phút)', icon: '🎯'),
  ];

  @override
  void onInit() {
    super.onInit();
    nameController.addListener(_validateName);
  }

  void _validateName() {
    nameValid.value = nameController.text.trim().length >= 2;
  }

  bool get canProceed {
    switch (currentStep.value) {
      case 0:
        return nameValid.value;
      case 1:
        return selectedLevel.value.isNotEmpty;
      case 2:
        return selectedGoals.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void selectLevel(String levelId) {
    selectedLevel.value = levelId;
  }

  void toggleGoal(String goalId) {
    if (selectedGoals.contains(goalId)) {
      selectedGoals.remove(goalId);
    } else {
      selectedGoals.add(goalId);
    }
  }

  void selectWordLimit(int words) {
    selectedWordLimit.value = words;
  }

  void nextStep() {
    if (!canProceed) return;
    
    if (currentStep.value < 3) {
      currentStep.value++;
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      finishSetup();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> finishSetup() async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      
      // Save to local storage
      _storage.userDisplayName = nameController.text.trim();
      _storage.userLevel = selectedLevel.value;
      _storage.userGoals = selectedGoals.toList();
      _storage.userDailyNewLimit = selectedWordLimit.value; // Words per day (1 word = 1 minute)
      
      // Create anonymous user
      final success = await _authService.createAnonymousUser();
      
      if (!success) {
        Get.snackbar(
          'Lỗi',
          'Không thể kết nối server. Vui lòng thử lại.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Submit onboarding to server
      // dailyMinutesTarget = selectedWordLimit (1 word = 1 minute)
      await _authService.submitOnboarding(
        displayName: nameController.text.trim(),
        goalType: selectedGoals.contains('exam') ? 'hsk_exam' : 
                 selectedGoals.contains('daily') ? 'conversation' : 'both',
        currentLevel: selectedLevel.value,
        dailyMinutesTarget: selectedWordLimit.value, // 1 word = 1 minute
        dailyNewLimit: selectedWordLimit.value,
        focusWeights: {'listening': 0.33, 'hanzi': 0.34, 'meaning': 0.33},
      );
      
      _authService.markSetupComplete();
      
      Logger.d('SetupController', 'Setup complete: ${nameController.text}, ${selectedLevel.value}');
      
      // Navigate to main app
      Get.offAllNamed(Routes.shell);
    } catch (e) {
      Logger.e('SetupController', 'finishSetup error', e);
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    pageController.dispose();
    super.onClose();
  }
}

class LevelOption {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  LevelOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class GoalOption {
  final String id;
  final String title;
  final String icon;

  GoalOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class WordLimitOption {
  final int words;
  final String title;
  final String subtitle;
  final String icon;

  WordLimitOption({
    required this.words,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

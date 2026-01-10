import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_session_service.dart';
import '../../routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

class IntroController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;
  
  final AuthSessionService _authService = Get.find<AuthSessionService>();

  // Using app's color palette for consistent branding
  final List<IntroSlideData> slides = [
    // Slide 1: Welcome - Primary Blue (app's main color)
    IntroSlideData(
      title: 'Chào mừng đến với HanLy!',
      description: 'Học tiếng Trung dễ dàng và hiệu quả với phương pháp khoa học',
      icon: '🇨🇳',
      gradient: [AppColors.primaryDark, AppColors.primary],
      accentColor: AppColors.secondary,
    ),
    // Slide 2: SRS - Dark Navy (app's dark theme)
    IntroSlideData(
      title: 'Phương pháp SRS',
      description: 'Ôn tập đúng lúc, nhớ lâu hơn gấp 5 lần với thuật toán Spaced Repetition',
      icon: '🧠',
      gradient: [AppColors.backgroundDark, AppColors.surfaceDark],
      accentColor: AppColors.success,
    ),
    // Slide 3: Learning Modes - Success Green
    IntroSlideData(
      title: '7+ Chế độ học',
      description: 'Flashcard, Nghe, Phát âm, Đặt câu, Ghép cặp, Thi thử HSK...',
      icon: '📚',
      gradient: [AppColors.successDark, AppColors.success],
      accentColor: AppColors.white,
    ),
    // Slide 4: Get Started - Primary Blue gradient
    IntroSlideData(
      title: 'Sẵn sàng chưa?',
      description: 'Bắt đầu hành trình chinh phục tiếng Trung ngay hôm nay!',
      icon: '🚀',
      gradient: [AppColors.primary, AppColors.primaryLight],
      accentColor: AppColors.secondary,
      isLast: true,
    ),
  ];

  void nextPage() {
    if (currentPage.value < slides.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      goToSetup();
    }
  }

  void skip() {
    goToSetup();
  }

  void goToSetup() {
    _authService.markIntroSeen();
    Get.offAllNamed(Routes.setup);
  }
  
  /// Navigate to login screen for users who already have an account
  void goToLogin() {
    _authService.markIntroSeen();
    Get.toNamed(Routes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class IntroSlideData {
  final String title;
  final String description;
  final String icon;
  final List<Color> gradient;
  final Color accentColor;
  final bool isLast;

  IntroSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.accentColor = AppColors.secondary,
    this.isLast = false,
  });
}

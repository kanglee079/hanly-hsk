import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_session_service.dart';
import '../../routes/app_routes.dart';

class IntroController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;
  
  final AuthSessionService _authService = Get.find<AuthSessionService>();

  final List<IntroSlideData> slides = [
    IntroSlideData(
      title: 'Chào mừng đến với HanLy!',
      description: 'Học tiếng Trung dễ dàng và hiệu quả với phương pháp khoa học',
      icon: '🇨🇳',
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
    ),
    IntroSlideData(
      title: 'Phương pháp SRS',
      description: 'Ôn tập đúng lúc, nhớ lâu hơn gấp 5 lần với thuật toán Spaced Repetition',
      icon: '🧠',
      gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    ),
    IntroSlideData(
      title: '7+ Chế độ học',
      description: 'Flashcard, Nghe, Phát âm, Đặt câu, Ghép cặp, Thi thử HSK...',
      icon: '📚',
      gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    ),
    IntroSlideData(
      title: 'Sẵn sàng chưa?',
      description: 'Bắt đầu hành trình chinh phục tiếng Trung ngay hôm nay!',
      icon: '🚀',
      gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
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
  final bool isLast;

  IntroSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    this.isLast = false,
  });
}

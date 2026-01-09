import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'intro_controller.dart';

class IntroScreen extends GetView<IntroController> {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: controller.pageController,
            itemCount: controller.slides.length,
            onPageChanged: (index) => controller.currentPage.value = index,
            itemBuilder: (context, index) {
              final slide = controller.slides[index];
              return _buildSlide(slide);
            },
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Obx(() {
              if (controller.currentPage.value == controller.slides.length - 1) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: controller.skip,
                child: Text(
                  'Bỏ qua',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              );
            }),
          ),

          // Bottom section
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator
                  Obx(() => _buildPageIndicator()),
                  const SizedBox(height: 32),
                  // Continue button
                  Obx(() => _buildButton()),
                  const SizedBox(height: 16),
                  // Login link for existing users
                  Obx(() => _buildLoginLink()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(IntroSlideData slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      slide.icon,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Title
              Text(
                slide.title,
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                slide.description,
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withAlpha(220),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        controller.slides.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: controller.currentPage.value == index ? 24 : 8,
          decoration: BoxDecoration(
            color: controller.currentPage.value == index
                ? Colors.white
                : Colors.white.withAlpha(100),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildButton() {
    final isLast = controller.currentPage.value == controller.slides.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.nextPage,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isLast ? 'Bắt đầu ngay!' : 'Tiếp tục',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Login link for users who already have an account
  Widget _buildLoginLink() {
    // Only show on last slide
    if (controller.currentPage.value != controller.slides.length - 1) {
      return const SizedBox.shrink();
    }
    
    return TextButton(
      onPressed: controller.goToLogin,
      child: Text(
        'Đã có tài khoản? Đăng nhập',
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withAlpha(200),
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withAlpha(150),
        ),
      ),
    );
  }
}

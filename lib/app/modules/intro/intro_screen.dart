import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
              return _buildSlide(slide, index);
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
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GestureDetector(
                  onTap: controller.skip,
                  child: Text(
                    'Bỏ qua',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),

          // Bottom section with glass effect
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(30),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                40,
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

  Widget _buildSlide(IntroSlideData slide, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            slide.gradient[0],
            slide.gradient[1],
            slide.gradient[1].withAlpha(200),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -120,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Icon with enhanced styling
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(40),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: slide.accentColor.withAlpha(60),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          slide.icon,
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  // Title with shadow for better readability
                  Text(
                    slide.title,
                    style: AppTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Description with subtle background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      slide.description,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withAlpha(230),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        controller.slides.length,
        (index) {
          final isActive = controller.currentPage.value == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 10,
            width: isActive ? 28 : 10,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withAlpha(80),
              borderRadius: BorderRadius.circular(5),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withAlpha(60),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final isLast = controller.currentPage.value == controller.slides.length - 1;
    final currentSlide = controller.slides[controller.currentPage.value];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: currentSlide.gradient[0].withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.nextPage,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 22,
                  color: currentSlide.gradient[0],
                ),
                const SizedBox(width: 10),
                Text(
                  isLast ? 'Bắt đầu ngay!' : 'Tiếp tục',
                  style: AppTypography.titleMedium.copyWith(
                    color: currentSlide.gradient[0],
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
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        'Đã có tài khoản? Đăng nhập',
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withAlpha(180),
        ),
      ),
    );
  }
}

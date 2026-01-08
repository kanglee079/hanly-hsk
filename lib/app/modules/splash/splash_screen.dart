import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/config/app_config.dart';
import 'splash_controller.dart';

/// Splash screen - beautiful animated loading screen
class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access controller to ensure it's instantiated
    // ignore: unused_local_variable
    final _ = controller;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _AnimatedBackground(isDark: isDark),

          // Floating particles
          _FloatingParticles(size: size),

          // Main content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Animated Logo
                  Obx(() => AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: controller.showLogo.value ? 1.0 : 0.0,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 800),
                          scale: controller.showLogo.value ? 1.0 : 0.5,
                          curve: Curves.easeOutBack,
                          child: _LogoWidget(isDark: isDark),
                        ),
                      )),

                  const SizedBox(height: 32),

                  // App Title
                  Obx(() => AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: controller.showTitle.value ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 600),
                          offset: controller.showTitle.value
                              ? Offset.zero
                              : const Offset(0, 0.3),
                          curve: Curves.easeOutCubic,
                          child: Text(
                            'HanLy',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 42,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      )),

                  const SizedBox(height: 8),

                  // Tagline
                  Obx(() => AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: controller.showTagline.value ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 600),
                          offset: controller.showTagline.value
                              ? Offset.zero
                              : const Offset(0, 0.5),
                          curve: Curves.easeOutCubic,
                          child: Text(
                            'Chinh phục Tiếng Trung từ gốc',
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )),

                  const Spacer(flex: 2),

                  // Loading section
                  Obx(() => AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: controller.showLoader.value ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 500),
                          offset: controller.showLoader.value
                              ? Offset.zero
                              : const Offset(0, 0.5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Column(
                              children: [
                                // Progress bar with glow
                                _GlowingProgressBar(
                                  progress: controller.loadingProgress.value,
                                  isDark: isDark,
                                ),

                                const SizedBox(height: 16),

                                // Loading message
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    controller.loadingMessage.value,
                                    key: ValueKey(controller.loadingMessage.value),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),

                  const Spacer(flex: 1),

                  // Footer
                  Obx(() => AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: controller.showLoader.value ? 1.0 : 0.0,
                        child: Column(
                          children: [
                            Text(
                              'DESIGNED FOR VIETNAMESE LEARNERS',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark.withAlpha(150)
                                    : AppColors.textTertiary.withAlpha(150),
                                letterSpacing: 2,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'v${AppConfig.appVersion}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textTertiaryDark.withAlpha(100)
                                    : AppColors.textTertiary.withAlpha(100),
                              ),
                            ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated gradient background
class _AnimatedBackground extends StatefulWidget {
  final bool isDark;

  const _AnimatedBackground({required this.isDark});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDark
                  ? [
                      AppColors.backgroundDark,
                      const Color(0xFF0F172A),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEFF6FF),
                      const Color(0xFFF1F5F9),
                    ],
              stops: [
                0.0,
                0.5 + 0.1 * math.sin(_controller.value * 2 * math.pi),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Floating particles effect
class _FloatingParticles extends StatefulWidget {
  final Size size;

  const _FloatingParticles({required this.size});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Generate random particles
    final random = math.Random(42);
    _particles = List.generate(15, (index) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 2 + random.nextDouble() * 4,
        speed: 0.2 + random.nextDouble() * 0.4,
        opacity: 0.1 + random.nextDouble() * 0.2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: widget.size,
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _controller.value,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y =
          (particle.y + animationValue * particle.speed) % 1.0 * size.height;
      final x = particle.x * size.width +
          math.sin(animationValue * 2 * math.pi + particle.y * 10) * 20;

      final paint = Paint()
        ..color = color.withAlpha((particle.opacity * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Logo widget with glow effect
class _LogoWidget extends StatelessWidget {
  final bool isDark;

  const _LogoWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 80,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Hanzi character
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFE0E7FF)],
            ).createShader(bounds),
            child: const Text(
              '漢',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing progress bar
class _GlowingProgressBar extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _GlowingProgressBar({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark.withAlpha(100)
            : AppColors.border.withAlpha(100),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          // Progress fill with gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shimmer effect
          if (progress < 1.0)
            Positioned.fill(
              child: _ShimmerEffect(),
            ),
        ],
      ),
    );
  }
}

/// Shimmer effect for progress bar
class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withAlpha(50),
                Colors.transparent,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}

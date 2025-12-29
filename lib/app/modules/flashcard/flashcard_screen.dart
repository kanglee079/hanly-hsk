import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/vocab_model.dart';
import 'flashcard_controller.dart';

/// Flashcard Screen with beautiful 3D flip animation
class FlashcardScreen extends GetView<FlashcardController> {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        showBackButton: true,
        onBackPressed: controller.goBack,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ÔN TẬP NHANH',
              style: AppTypography.labelSmall.copyWith(
                color: (isDark ? Colors.white : AppColors.textTertiary)
                    .withValues(alpha: 0.7),
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              'Flashcards',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.vocabs.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.currentIndex.value + 1}/${controller.vocabs.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE0F2FE),
                    const Color(0xFFBAE6FD),
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingState(isDark);
            }

            if (controller.vocabs.isEmpty) {
              return _buildEmptyState(isDark);
            }

            if (controller.hasFinished.value) {
              return _buildFinishedState(isDark);
            }

            return _buildFlashcardContent(context, isDark);
          }),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải thẻ từ...',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.style_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có từ nào',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy học thêm từ mới để sử dụng tính năng thẻ từ nhé!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: HMButton(
                text: 'Quay lại',
                onPressed: controller.goBack,
                variant: HMButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Hoàn thành! 🎉',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã xem hết ${controller.vocabs.length} thẻ từ',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Stats breakdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withAlpha(13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.newWordsCount.value > 0) ...[
                    _buildStatChip(
                      '${controller.newWordsCount.value} mới',
                      const Color(0xFF3B82F6),
                      isDark,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (controller.reviewWordsCount.value > 0)
                    _buildStatChip(
                      '${controller.reviewWordsCount.value} ôn tập',
                      const Color(0xFF10B981),
                      isDark,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFinishButton(
                      icon: Icons.refresh_rounded,
                      label: 'Xem lại',
                      onTap: controller.restart,
                      isDark: isDark,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFinishButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Hoàn tất',
                      onTap: controller.goBack,
                      isDark: isDark,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Progress bar
        Obx(() => _buildProgressBar(isDark)),

        const SizedBox(height: 24),

        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(() => _buildFlashcard(context, isDark)),
          ),
        ),

        const SizedBox(height: 32),

        // Navigation controls (only prev/next)
        _buildControls(context, isDark),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.vocabs.length, (index) {
              final isActive = index == controller.currentIndex.value;
              final isPast = index < controller.currentIndex.value;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : isPast
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(BuildContext context, bool isDark) {
    final vocab = controller.currentVocab;
    if (vocab == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.flipCard();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -300) {
            // Swipe left -> next
            HapticFeedback.lightImpact();
            controller.nextCard();
          } else if (details.primaryVelocity! > 300) {
            // Swipe right -> previous
            HapticFeedback.lightImpact();
            controller.previousCard();
          }
        }
      },
      child: Obx(() {
        final isFlipped = controller.isFlipped.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isFlipped ? 1 : 0),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            // Determine which side to show based on flip progress
            final showBack = value >= 0.5;
            final angle = value * math.pi;
            
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _buildCardBack(vocab, isDark),
                    )
                  : _buildCardFront(vocab, isDark),
            );
          },
        );
      }),
    );
  }

  Widget _buildCardFront(VocabModel vocab, bool isDark) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vocab.level,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Hanzi - Main character
          Text(
            vocab.hanzi,
            style: TextStyle(
              fontFamily: 'NotoSansSC',
              fontSize: 88,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Pinyin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              vocab.pinyin,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Tap hint with flip icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flip_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chạm để lật thẻ',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white38 : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(VocabModel vocab, bool isDark) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E40AF), const Color(0xFF3730A3)]
              : [const Color(0xFF3B82F6), const Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===== HEADER: Hanzi + Pinyin + Audio =====
          Row(
            children: [
              // Hanzi and Pinyin
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vocab.hanzi,
                      style: const TextStyle(
                        fontFamily: 'NotoSansSC',
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        vocab.pinyin,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Audio button
              _buildCompactAudioButton(() => controller.playAudio()),
            ],
          ),

          const SizedBox(height: 16),

          // ===== CONTENT: Compact sections =====
          Expanded(
            child: Column(
              children: [
                // Meaning - always show
                _buildCompactSection('Nghĩa', vocab.meaningVi),

                // Word type - inline if exists
                if (vocab.wordType != null && vocab.wordType!.isNotEmpty)
                  _buildCompactSection('Loại từ', vocab.wordType!),

                // Example - if exists
                if (vocab.examples.isNotEmpty)
                  _buildCompactSection(
                    'Ví dụ',
                    '${vocab.examples.first.hanzi}\n${vocab.examples.first.meaningVi}',
                  ),

                // Mnemonic - if exists (lowest priority)
                if (vocab.mnemonic != null && vocab.mnemonic!.isNotEmpty)
                  _buildCompactSection('Mẹo nhớ', vocab.mnemonic!),

                const Spacer(),
              ],
            ),
          ),

          // ===== FOOTER: Favorite + Hint =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFavoriteButton(isDark),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lật thẻ',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAudioButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCompactSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(bool isDark) {
    return Obx(() {
      final vocabs = controller.vocabs;
      final currentIndex = controller.currentIndex.value;
      
      if (vocabs.isEmpty || currentIndex >= vocabs.length) {
        return const SizedBox.shrink();
      }
      
      final vocab = vocabs[currentIndex];
      final isFavorite = vocab.isFavorite;
      
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.toggleFavorite();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isFavorite
                ? AppColors.favorite.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFavorite
                  ? AppColors.favorite.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(isFavorite),
                  color: isFavorite ? AppColors.favorite : Colors.white54,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isFavorite ? 'Đã thích' : 'Yêu thích',
                style: AppTypography.labelSmall.copyWith(
                  color: isFavorite ? AppColors.favorite : Colors.white54,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildControls(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          Obx(() => _buildControlButton(
                icon: Icons.arrow_back_rounded,
                label: 'Trước',
                onTap: controller.currentIndex.value > 0
                    ? controller.previousCard
                    : null,
                isDark: isDark,
              )),

          // Next button
          Obx(() => _buildControlButton(
                icon: Icons.arrow_forward_rounded,
                label: controller.currentIndex.value < controller.vocabs.length - 1
                    ? 'Tiếp'
                    : 'Xong',
                onTap: controller.nextCard,
                isDark: isDark,
                isPrimary: true,
              )),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isPrimary ? 64 : 52,
              height: isPrimary ? 64 : 52,
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(isPrimary ? 20 : 16),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                size: isPrimary ? 28 : 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white24
                      : Colors.black.withValues(alpha: 0.1),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


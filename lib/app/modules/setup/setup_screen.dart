import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/hm_button.dart';
import '../../core/widgets/hm_text_field.dart';
import '../../core/widgets/hm_loading.dart';
import 'setup_controller.dart';

class SetupScreen extends GetView<SetupController> {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Obx(() => _buildProgressBar()),
            
            // Content
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NameStep(controller: controller, isDark: isDark),
                  _LevelStep(controller: controller, isDark: isDark),
                  _GoalStep(controller: controller, isDark: isDark),
                  _DurationStep(controller: controller, isDark: isDark),
                ],
              ),
            ),

            // Bottom navigation
            _buildBottomNav(isDark),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= controller.currentStep.value;
          final isCompleted = index < controller.currentStep.value;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCompleted
                  ? Container(color: AppColors.primary)
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Obx(() {
      final canProceed = controller.canProceed;
      final isFirst = controller.currentStep.value == 0;
      final isLast = controller.currentStep.value == 3;
      final isLoading = controller.isLoading.value;

      return Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Back button (only show if not first step)
            if (!isFirst)
              TextButton.icon(
                onPressed: controller.previousStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Quay lại'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              )
            else
              const SizedBox(width: 100), // Placeholder for alignment
            
            const Spacer(),
            
            // Continue button
            if (isLoading)
              const HMLoadingIndicator.small()
            else
              HMButton(
                text: isLast ? 'Bắt đầu!' : 'Tiếp tục',
                onPressed: canProceed ? controller.nextStep : null,
                fullWidth: false,
                icon: Icon(
                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
              ),
          ],
        ),
      );
    });
  }
}

// Step 1: Name
class _NameStep extends StatelessWidget {
  final SetupController controller;
  final bool isDark;

  const _NameStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Chào bạn! 👋',
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tên bạn là gì?',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          HMTextField(
            controller: controller.nameController,
            hintText: 'Nhập tên của bạn',
            prefixIcon: const Icon(Icons.person_outline_rounded),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Chúng tôi sẽ gọi bạn bằng tên này',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Level
class _LevelStep extends StatelessWidget {
  final SetupController controller;
  final bool isDark;

  const _LevelStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Trình độ hiện tại?',
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn level phù hợp để bắt đầu',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...controller.levels.map((level) => Obx(() {
            final isSelected = controller.selectedLevel.value == level.id;
            return _buildOptionCard(
              icon: level.icon,
              title: level.title,
              subtitle: level.subtitle,
              isSelected: isSelected,
              onTap: () => controller.selectLevel(level.id),
              isDark: isDark,
            );
          })),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// Step 3: Goals
class _GoalStep extends StatelessWidget {
  final SetupController controller;
  final bool isDark;

  const _GoalStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Mục tiêu học?',
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn một hoặc nhiều mục tiêu',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: controller.goals.map((goal) => Obx(() {
              final isSelected = controller.selectedGoals.contains(goal.id);
              return _buildGoalChip(
                icon: goal.icon,
                title: goal.title,
                isSelected: isSelected,
                onTap: () => controller.toggleGoal(goal.id),
                isDark: isDark,
              );
            })).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalChip({
    required String icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 4: Duration
class _DurationStep extends StatelessWidget {
  final SetupController controller;
  final bool isDark;

  const _DurationStep({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Số từ mỗi ngày?',
            style: AppTypography.displaySmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn muốn học bao nhiêu từ mới mỗi ngày',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...controller.wordLimitOptions.map((option) => Obx(() {
            final isSelected = controller.selectedWordLimit.value == option.words;
            return _buildDurationCard(
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              isSelected: isSelected,
              onTap: () => controller.selectWordLimit(option.words),
              isDark: isDark,
            );
          })),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bạn có thể thay đổi mục tiêu này sau trong Cài đặt',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard({
    required String icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(20)
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'onboarding_controller.dart';

/// Onboarding screen - single page form matching design
class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back, progress, skip
            _buildHeader(context, isDark),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      'Chào mừng bạn!',
                      style: AppTypography.displaySmall.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy dành chút thời gian để cá nhân hóa lộ trình học Hán ngữ của bạn.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Display name
                    _buildSection(
                      title: 'Tên hiển thị',
                      isDark: isDark,
                      child: HMTextField(
                        controller: controller.displayNameController,
                        hintText: 'Nhập tên của bạn',
                        textInputAction: TextInputAction.done,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Goal type
                    _buildSection(
                      title: 'Mục tiêu chính',
                      isDark: isDark,
                      child: Obx(() => Row(
                            children: [
                              _GoalCard(
                                icon: Icons.school_outlined,
                                label: 'Thi HSK',
                                isSelected:
                                    controller.goalType.value == GoalType.hskExam,
                                onTap: () =>
                                    controller.setGoalType(GoalType.hskExam),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              _GoalCard(
                                icon: Icons.chat_bubble_outline,
                                label: 'Giao tiếp',
                                isSelected:
                                    controller.goalType.value == GoalType.conversation,
                                onTap: () =>
                                    controller.setGoalType(GoalType.conversation),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 12),
                              _GoalCard(
                                icon: Icons.auto_awesome,
                                label: 'Cả hai',
                                isSelected:
                                    controller.goalType.value == GoalType.both,
                                onTap: () =>
                                    controller.setGoalType(GoalType.both),
                                isDark: isDark,
                              ),
                            ],
                          )),
                    ),

                    const SizedBox(height: 24),

                    // Current level
                    _buildSection(
                      title: 'Trình độ hiện tại',
                      isDark: isDark,
                      trailing: Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'HSK ${controller.currentLevel.value}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                      child: Obx(() => Row(
                            children: controller.levelOptions.map((level) {
                              final isSelected =
                                  controller.currentLevel.value == level;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.setLevel(level),
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(right: level < 6 ? 8 : 0),
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.surfaceVariantDark
                                              : AppColors.surfaceVariant),
                                      borderRadius: BorderRadius.circular(12),
                                      border: !isSelected
                                          ? Border.all(
                                              color: isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.border,
                                            )
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$level',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimary),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
                    ),

                    const SizedBox(height: 24),

                    // Daily words
                    _buildSection(
                      title: 'Số từ mới mỗi ngày',
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Row(
                                children:
                                    controller.dailyWordsOptions.map((words) {
                                  final isSelected =
                                      controller.dailyWords.value == words;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          controller.setDailyWords(words),
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            right: words < 30 ? 8 : 0),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDark
                                                  ? AppColors.surfaceDark
                                                  : Colors.white)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : (isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.border),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$words',
                                                style:
                                                    AppTypography.titleMedium.copyWith(
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : (isDark
                                                          ? AppColors.textPrimaryDark
                                                          : AppColors.textPrimary),
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              Text(
                                                'từ',
                                                style:
                                                    AppTypography.labelSmall.copyWith(
                                                  color: isSelected
                                                      ? AppColors.primary.withAlpha(180)
                                                      : (isDark
                                                          ? AppColors.textTertiaryDark
                                                          : AppColors.textTertiary),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )),
                          const SizedBox(height: 8),
                          Obx(() => Text(
                                controller.dailyWordsDescription,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Focus skills
                    _buildSection(
                      title: 'Kỹ năng ưu tiên',
                      isDark: isDark,
                      child: Column(
                        children: [
                          Obx(() => _SkillToggle(
                                icon: Icons.headphones_outlined,
                                label: 'Luyện nghe',
                                isEnabled: controller.listeningEnabled.value,
                                onTap: controller.toggleListening,
                                isDark: isDark,
                              )),
                          const SizedBox(height: 12),
                          Obx(() => _SkillToggle(
                                icon: Icons.edit_outlined,
                                label: 'Viết Hanzi',
                                isEnabled: controller.hanziEnabled.value,
                                onTap: controller.toggleHanzi,
                                isDark: isDark,
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Notifications card
                    Obx(() => _NotificationCard(
                          isEnabled: controller.notificationsEnabled.value,
                          onToggle: controller.toggleNotifications,
                          isDark: isDark,
                        )),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Submit button - fixed at bottom with safe area
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Obx(() => HMButton(
                    text: 'Tạo hồ sơ →',
                    onPressed:
                        controller.canSubmit ? controller.submitProfile : null,
                    isLoading: controller.isLoading.value,
                    fullWidth: true,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Spacer to balance the Skip button on the right
          const SizedBox(width: 60),

          const Spacer(),

          // App logo/icon in center
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: AppColors.primary,
              size: 24,
            ),
          ),

          const Spacer(),

          // Skip button
          TextButton(
            onPressed: controller.skip,
            child: Text(
              'Bỏ qua',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required Widget child,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Goal card widget
class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _GoalCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primarySurface
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skill toggle widget
class _SkillToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool isDark;

  const _SkillToggle({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primarySurface
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primary.withAlpha(25)
                    : (isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isEnabled
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color:
                      isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ),
            // Custom toggle switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceVariantDark : const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isEnabled
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification card widget
class _NotificationCard extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onToggle;
  final bool isDark;

  const _NotificationCard({
    required this.isEnabled,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(20),
            AppColors.primary.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withAlpha(50),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duy trì thói quen?',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhận nhắc nhở nhẹ nhàng mỗi ngày để không đứt quãng chuỗi học tập.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: isEnabled
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled ? Icons.check : Icons.notifications_none,
                          size: 18,
                          color: isEnabled
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEnabled ? 'Đã bật' : 'Bật thông báo',
                          style: AppTypography.labelMedium.copyWith(
                            color: isEnabled
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
}

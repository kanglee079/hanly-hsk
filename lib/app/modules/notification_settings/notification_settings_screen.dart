import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import 'notification_settings_controller.dart';

class NotificationSettingsScreen extends GetView<NotificationSettingsController> {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        title: 'Cài đặt thông báo',
        showBackButton: true,
        actions: [
          Obx(() => controller.isSaving.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: HMLoadingIndicator.medium());
        }

        final settings = controller.settings.value;
        if (settings == null) {
          return const Center(child: Text('Không thể tải cài đặt'));
        }

        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Master Switch
            HMCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bật thông báo',
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nhận nhắc nhở học hàng ngày',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: settings.enabled,
                    activeTrackColor: AppColors.primary,
                        onChanged: controller.toggleEnabled,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reminder Time
            _SectionHeader(title: 'Thời gian nhắc nhở', isDark: isDark),
            const SizedBox(height: 12),

                  HMCard(
              onTap: settings.enabled ? () => _showTimePicker(context) : null,
              padding: const EdgeInsets.all(16),
              child: Opacity(
                opacity: settings.enabled ? 1.0 : 0.5,
                    child: Row(
                      children: [
                        Icon(
                      Icons.access_time_rounded,
                      size: 24,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                        'Giờ nhắc nhở',
                            style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                      controller.reminderTimeDisplay,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
            ),

                  const SizedBox(height: 24),

            // Notification Types
                  _SectionHeader(title: 'Loại thông báo', isDark: isDark),
            const SizedBox(height: 12),

            HMCard(
              padding: EdgeInsets.zero,
              child: Opacity(
                opacity: settings.enabled ? 1.0 : 0.5,
                child: Column(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.event_note_rounded,
                      title: 'Nhắc nhở học hàng ngày',
                      subtitle: 'Nhắc nhở vào ${controller.reminderTimeDisplay} mỗi ngày',
                      value: settings.types.dailyReminder,
                      onChanged: settings.enabled ? (v) => controller.toggleType('dailyReminder', v) : null,
                    isDark: isDark,
                  ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Cảnh báo mất streak',
                      subtitle: 'Nhắc khi sắp mất chuỗi ngày học',
                      value: settings.types.streakReminder,
                      onChanged: settings.enabled ? (v) => controller.toggleType('streakReminder', v) : null,
                    isDark: isDark,
                  ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      icon: Icons.new_releases_rounded,
                    title: 'Nội dung mới',
                      subtitle: 'Từ vựng và bài tập mới',
                      value: settings.types.newContent,
                      onChanged: settings.enabled ? (v) => controller.toggleType('newContent', v) : null,
                    isDark: isDark,
                  ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      icon: Icons.emoji_events_rounded,
                      title: 'Huy hiệu và thành tích',
                      subtitle: 'Khi đạt thành tích mới',
                      value: settings.types.achievements,
                      onChanged: settings.enabled ? (v) => controller.toggleType('achievements', v) : null,
                    isDark: isDark,
                      isLast: true,
                  ),
                ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.border,
      ),
    );
  }

  void _showTimePicker(BuildContext context) async {
    final currentTime = controller.reminderTime ?? const TimeOfDay(hour: 20, minute: 0);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != currentTime) {
      controller.updateReminderTime(picked);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}

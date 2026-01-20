import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../routes/app_routes.dart';
import '../../services/tutorial_service.dart';
import 'me_controller.dart';

/// Me tab screen - Profile & Settings
class MeScreen extends GetView<MeController> {
  const MeScreen({super.key});

  // Get registered keys from TutorialService
  GlobalKey get _profileKey =>
      Get.find<TutorialService>().registerKey('me_profile');
  GlobalKey get _dailyGoalKey =>
      Get.find<TutorialService>().registerKey('me_daily_goal');
  GlobalKey get _statsKey =>
      Get.find<TutorialService>().registerKey('me_stats');
  GlobalKey get _favoritesKey =>
      Get.find<TutorialService>().registerKey('me_favorites');
  GlobalKey get _settingsKey =>
      Get.find<TutorialService>().registerKey('me_settings');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                // Offline mode banner (shown when auth failed)
                Obx(() {
                  if (controller.isOfflineMode) {
                    return _buildOfflineBanner(isDark);
                  }
                  return const SizedBox.shrink();
                }),

                const SizedBox(height: 12),

                // Profile section
                Showcase(
                  key: _profileKey,
                  title: 'Hồ sơ của bạn',
                  description:
                      'Xem và chỉnh sửa thông tin cá nhân, mục tiêu học tập.',
                  overlayOpacity: 0.7,
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildProfileSection(isDark),
                ),

                const SizedBox(height: 16),

                // Stats section
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    children: [
                      // Daily Goal Card
                      Showcase(
                        key: _dailyGoalKey,
                        title: 'Mục tiêu hàng ngày',
                        description:
                            'Đặt và theo dõi mục tiêu học tập của bạn.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildDailyGoalCard(isDark),
                      ),

                      const SizedBox(height: 12),

                      // Stats row
                      Showcase(
                        key: _statsKey,
                        title: 'Thống kê học tập',
                        description:
                            'Theo dõi tiến trình, số từ đã thuộc và nhiều chỉ số khác.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildStatsRow(isDark),
                      ),

                      const SizedBox(height: 20),

                      // Favorites Section
                      Showcase(
                        key: _favoritesKey,
                        title: 'Từ yêu thích',
                        description:
                            'Xem và ôn tập các từ bạn đã lưu vào danh sách yêu thích.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildFavoritesSection(isDark),
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions
                      _buildQuickActionsSection(isDark),

                      const SizedBox(height: 20),

                      // Account section
                      _buildAccountSection(isDark),

                      const SizedBox(height: 20),

                      // Preferences
                      Showcase(
                        key: _settingsKey,
                        title: 'Cài đặt',
                        description:
                            'Tùy chỉnh giao diện, âm thanh và các cài đặt khác.',
                        overlayOpacity: 0.7,
                        targetShapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildPreferencesSection(isDark),
                      ),

                      const SizedBox(height: 16),

                      // Logout & Delete Account
                      _buildDangerSection(isDark),

                      const SizedBox(height: 20),

                      // App version
                      _buildAppVersion(isDark),

                      // Bottom padding for glass nav bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding.copyWith(top: 8, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title + Subtitle stacked
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TÀI KHOẢN',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
                ),
                Text(
                  S.me,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Settings icon
          GestureDetector(
            onTap: () => Get.toNamed(Routes.settings),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_outlined,
                size: 18,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return Obx(
      () => Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySurface,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 3,
                  ),
                ),
                child: controller.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          controller.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarPlaceholder(),
                        ),
                      )
                    : _buildAvatarPlaceholder(),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: controller.editProfile,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Display name
          Text(
            controller.displayName.isNotEmpty
                ? controller.displayName
                : 'Người dùng',
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        size: 48,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildDailyGoalCard(bool isDark) {
    return Obx(
      () => GestureDetector(
        onTap: controller.adjustDailyWordCount,
        child: HMCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          S.dailyGoal,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${controller.dailyGoalCurrent}',
                            style: AppTypography.displaySmall.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/${controller.dailyGoalTarget}',
                            style: AppTypography.titleLarge.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: '  ${S.words}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring
              HMProgressRing(
                progress: controller.dailyGoalProgress,
                size: 64,
                strokeWidth: 6,
                progressColor: AppColors.primary,
                backgroundColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                child: HMAnimatedNumber(
                  value: controller.dailyGoalPercent,
                  suffix: '%',
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Obx(
      () => Row(
        children: [
          // Day Streak card - tappable to show streak details
          Expanded(child: _buildStreakCard(isDark)),
          const SizedBox(width: 12),
          // Total learned card - tappable to show stats
          Expanded(
            child: GestureDetector(
              onTap: controller.goToStats,
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
                value: '${controller.totalLearned}',
                label: 'Đã học',
                isDark: isDark,
                showChevron: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Streak card using HMStreakWidget for consistent UI
  Widget _buildStreakCard(bool isDark) {
    return GestureDetector(
      onTap: controller.showStreakDetails,
      child: HMCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fire icon with animation effect
                HMStreakWidget(
                  streak: controller.streak,
                  hasStudiedToday: controller.hasStudiedToday,
                  size: StreakWidgetSize.small,
                  showMessage: false,
                  onTap: null, // GestureDetector above handles tap
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${controller.streak}',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              S.dayStreak,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
    bool showChevron = false,
  }) {
    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yêu thích',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: controller.goToFavorites,
          child: HMCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Animated heart icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Transform.rotate(
                        angle: (1 - value) * 0.1,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.favorite.withAlpha(30),
                                AppColors.favorite.withAlpha(15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 28,
                            color: AppColors.favorite,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Từ yêu thích',
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Xem và quản lý từ đã lưu',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.quickActions,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Adjust Learning Settings
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.tune,
                label: S.adjustGoal,
                onTap: controller.adjustLearningSettings,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            // Donate button (replaced Premium)
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.favorite_rounded,
                label: 'Ủng hộ',
                onTap: () => Get.toNamed(Routes.donation),
                isDark: isDark,
                isPrimary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: AppSpacing.borderRadiusLg,
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary
                  ? AppColors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isPrimary
                    ? AppColors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.preferences,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        HMCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildPreferenceItem(
                icon: Icons.person_outline,
                title: S.account,
                onTap: controller.goToAccount,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildPreferenceItem(
                icon: Icons.notifications_outlined,
                title: S.notifications,
                onTap: controller.goToNotifications,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildPreferenceItem(
                icon: Icons.volume_up_outlined,
                title: S.soundHaptics,
                onTap: controller.goToSoundSettings,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildPreferenceItem(
                icon: Icons.translate,
                title: S.vietnameseSupport,
                onTap: controller.goToVietnameseSupport,
                isDark: isDark,
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool showBorder = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: showBorder ? null : AppSpacing.borderRadiusLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Account section - shows link account or email if logged in
  Widget _buildAccountSection(bool isDark) {
    return Obx(() {
      final isAnonymous = controller.isAnonymous;
      final email = controller.userEmail;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tài khoản',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Prominent banner for anonymous users
          if (isAnonymous) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF2D4A6F)]
                      : [AppColors.primarySurface, AppColors.primaryLight.withValues(alpha: 0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.warning_rounded, color: AppColors.warning, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dữ liệu chưa được đồng bộ',
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dữ liệu có thể mất khi xóa app. Tạo tài khoản để backup.',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: HMButton(
                      text: 'Tạo tài khoản để backup',
                      onPressed: () => Get.toNamed(Routes.authRegister),
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          HMCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (isAnonymous) ...[
                  // Login to existing account
                  InkWell(
                    onTap: () => Get.toNamed(Routes.login),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.login_rounded,
                              size: 22,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đăng nhập tài khoản có sẵn',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Đã tạo tài khoản? Đăng nhập để đồng bộ data',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Logged in user - show email
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 22,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email ?? 'Đã liên kết',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Dữ liệu được đồng bộ',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: AppColors.success),
                              SizedBox(width: 4),
                              Text(
                                'Đã xác thực',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDangerSection(bool isDark) {
    return Obx(() {
      final isAnonymous = controller.isAnonymous;

      return HMCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Logout - only show if logged in (not anonymous)
            if (!isAnonymous) ...[
              InkWell(
                onTap: controller.logout,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 22, color: AppColors.warning),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          S.signOut,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDivider(isDark),
            ],
            // Delete account
            InkWell(
              onTap: controller.deleteAccount,
              borderRadius: BorderRadius.vertical(
                top: isAnonymous ? const Radius.circular(16) : Radius.zero,
                bottom: const Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 22,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        S.deleteAccount,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Build offline mode banner - shown when auth failed
  Widget _buildOfflineBanner(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withAlpha(25),
              AppColors.warning.withAlpha(15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withAlpha(100),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ Offline',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dữ liệu chưa được đồng bộ với máy chủ',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            HMButton(
              text: 'Thử kết nối lại',
              variant: HMButtonVariant.outline,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              size: HMButtonSize.small,
              fullWidth: true,
              onPressed: () async {
                final success = await controller.retryAuthentication();
                if (success) {
                  HMToast.success('Đã kết nối thành công!');
                } else {
                  HMToast.error('Không thể kết nối. Vui lòng thử lại sau.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    );
  }

  Widget _buildAppVersion(bool isDark) {
    return Text(
      '${S.appVersion} 2.4.0',
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
    );
  }
}

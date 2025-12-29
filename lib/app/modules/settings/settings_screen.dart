import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/audio_service.dart';
import '../../services/tutorial_service.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(title: S.settings),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Cache section
          _SectionHeader(title: 'Bộ nhớ đệm', isDark: isDark),
          const SizedBox(height: 8),
          _CacheInfoTile(isDark: isDark),
          const SizedBox(height: 24),

          // Tutorial section
          _SectionHeader(title: 'Hướng dẫn', isDark: isDark),
          const SizedBox(height: 8),
          _TutorialResetTile(isDark: isDark),
          const SizedBox(height: 24),

          // Legal section
          _SectionHeader(title: 'Pháp lý', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: S.privacyPolicy,
            onTap: () => Get.toNamed(Routes.privacyPolicy),
            isDark: isDark,
          ),
          _SettingsItem(
            icon: Icons.description_outlined,
            title: S.termsOfService,
            onTap: () => Get.toNamed(Routes.termsOfService),
            isDark: isDark,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'HanLy v1.0.0',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
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

class _CacheInfoTile extends StatefulWidget {
  final bool isDark;

  const _CacheInfoTile({required this.isDark});

  @override
  State<_CacheInfoTile> createState() => _CacheInfoTileState();
}

class _CacheInfoTileState extends State<_CacheInfoTile> {
  String _audioCacheSize = 'Đang tính...';
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    try {
      final audioService = Get.find<AudioService>();
      final size = await audioService.getCacheSizeFormatted();
      if (mounted) {
        setState(() => _audioCacheSize = size);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _audioCacheSize = 'Không thể tính');
      }
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);

    try {
      final cacheService = Get.find<CacheService>();
      await cacheService.clearAllCache();
      await _loadCacheSize();
      HMToast.success('Đã xóa bộ nhớ đệm');
    } catch (e) {
      HMToast.error('Không thể xóa bộ nhớ đệm');
    }

    if (mounted) {
      setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HMCard(
      padding: AppSpacing.cardInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_outlined,
                size: 24,
                color: widget.isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Cache',
                      style: AppTypography.bodyLarge.copyWith(
                        color: widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _audioCacheSize,
                      style: AppTypography.bodySmall.copyWith(
                        color: widget.isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cache giúp giảm dung lượng internet và tải nhanh hơn. '
            'File audio được lưu cục bộ sau lần tải đầu tiên.',
            style: AppTypography.bodySmall.copyWith(
              color: widget.isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: HMButton(
              text: _isClearing ? 'Đang xóa...' : 'Xóa bộ nhớ đệm',
              variant: HMButtonVariant.outline,
              onPressed: _isClearing ? null : _clearCache,
              isLoading: _isClearing,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
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
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialResetTile extends StatelessWidget {
  final bool isDark;

  const _TutorialResetTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.help_outline_rounded,
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
                  'Xem lại hướng dẫn',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hiển thị lại các hướng dẫn tân thủ',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HMButton(
            text: 'Đặt lại',
            variant: HMButtonVariant.outline,
            size: HMButtonSize.small,
            fullWidth: false, // 🔧 FIX: Must be false when used in Row
            onPressed: () {
              if (Get.isRegistered<TutorialService>()) {
                Get.find<TutorialService>().resetAllTutorials();
                HMToast.success('Đã đặt lại hướng dẫn');
              }
            },
          ),
        ],
      ),
    );
  }
}

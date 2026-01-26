import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../services/dataset_sync_service.dart';
import 'offline_download_controller.dart';

class OfflineDownloadScreen extends GetView<OfflineDownloadController> {
  const OfflineDownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: const HMAppBar(
        title: 'Tải về Offline',
        showBackButton: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: HMLoadingIndicator.medium());
        }

        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppSpacing.borderRadiusLg,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_download_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tất cả đã có sẵn!',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.getTotalVocabs()} từ vựng • ${controller.getTotalSize().toStringAsFixed(1)} MB',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Sẵn sàng offline',
                          style: AppTypography.labelMedium.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final ds = controller.datasetSync;
                    final version = ds.localVersion.value;
                    final state = ds.state.value;
                    final progress = (ds.progress.value * 100).clamp(0.0, 100.0);

                    String statusText;
                    if (state == DatasetSyncState.downloading) {
                      statusText = 'Dang tai du lieu... ${progress.toStringAsFixed(0)}%';
                    } else if (state == DatasetSyncState.applying) {
                      statusText = 'Dang cap nhat du lieu...';
                    } else if (state == DatasetSyncState.failed) {
                      statusText = 'Khong the cap nhat du lieu';
                    } else if (version == '0' || version.isEmpty) {
                      statusText = 'Chua co du lieu offline';
                    } else {
                      statusText = 'Phien ban: $version';
                    }

                    return Column(
                      children: [
                        Text(
                          statusText,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                        if (state == DatasetSyncState.downloading) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ds.progress.value,
                            backgroundColor: Colors.white.withAlpha(30),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: controller.checkForUpdates,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kiem tra cap nhat'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'CHI TIẾT THEO CẤP ĐỘ',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Bundle list
            ...controller.bundles.map((bundle) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BundleCard(bundle: bundle, isDark: isDark),
            )),

            const SizedBox(height: 24),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.primary.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tất cả từ vựng đã được đóng gói sẵn trong app. Bạn có thể học offline bất cứ lúc nào!',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final OfflineBundleModel bundle;
  final bool isDark;

  const _BundleCard({required this.bundle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return HMCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundle.name,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bundle.vocabCount} từ • ${bundle.sizeInMB.toStringAsFixed(1)} MB',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Đã tải',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

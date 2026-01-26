import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../services/connectivity_service.dart';
import '../../services/progress_sync_service.dart';

class HMSyncStatusChip extends StatelessWidget {
  const HMSyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();
    final sync = Get.find<ProgressSyncService>();

    return Obx(() {
      final isOnline = connectivity.isOnline.value;
      final pending = sync.pendingCount.value;
      final state = sync.state.value;

      String label;
      Color color;

      if (!isOnline) {
        label = 'Offline';
        color = AppColors.error;
      } else if (state == ProgressSyncState.syncing) {
        label = 'Dang dong bo...';
        color = AppColors.primary;
      } else if (state == ProgressSyncState.failed) {
        label = pending > 0 ? 'Dong bo loi ($pending)' : 'Dong bo loi';
        color = AppColors.warning;
      } else if (pending > 0) {
        label = 'Cho dong bo ($pending)';
        color = AppColors.warning;
      } else {
        label = 'Da dong bo';
        color = AppColors.success;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}

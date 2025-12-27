import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../data/network/api_exception.dart';

/// Toast notification helper using Get.snackbar
class HMToast {
  HMToast._();

  /// Show success toast
  static void success(String message, {String? title}) {
    _show(
      title: title ?? 'Thành công',
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Show error toast
  static void error(String message, {String? title}) {
    _show(
      title: title ?? 'Lỗi',
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
    );
  }

  /// Show warning toast
  static void warning(String message, {String? title}) {
    _show(
      title: title ?? 'Cảnh báo',
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_rounded,
    );
  }

  /// Show info toast
  static void info(String message, {String? title}) {
    _show(
      title: title ?? 'Thông báo',
      message: message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_rounded,
    );
  }

  /// Show toast from ApiException with appropriate styling
  static void fromException(ApiException e) {
    switch (e.errorCode) {
      case ApiErrorCode.networkError:
      case ApiErrorCode.timeout:
        _show(
          title: 'Lỗi kết nối',
          message: e.message,
          backgroundColor: AppColors.warning,
          icon: Icons.wifi_off_rounded,
        );
        break;

      case ApiErrorCode.rateLimited:
        _show(
          title: 'Quá nhiều yêu cầu',
          message: e.message,
          backgroundColor: AppColors.warning,
          icon: Icons.hourglass_empty_rounded,
        );
        break;

      case ApiErrorCode.unauthorized:
        _show(
          title: 'Phiên hết hạn',
          message: e.message,
          backgroundColor: AppColors.error,
          icon: Icons.logout_rounded,
        );
        break;

      case ApiErrorCode.notFound:
        _show(
          title: 'Không tìm thấy',
          message: e.message,
          backgroundColor: AppColors.warning,
          icon: Icons.search_off_rounded,
        );
        break;

      default:
        error(e.message);
    }
  }

  /// Show offline mode notification
  static void offline() {
    _show(
      title: 'Ngoại tuyến',
      message: 'Không có kết nối mạng. Một số tính năng có thể bị hạn chế.',
      backgroundColor: AppColors.warning,
      icon: Icons.cloud_off_rounded,
    );
  }

  /// Show rate limit notification with countdown
  static void rateLimited({int? secondsRemaining}) {
    final message = secondsRemaining != null
        ? 'Vui lòng đợi $secondsRemaining giây trước khi thử lại.'
        : 'Quá nhiều yêu cầu. Vui lòng đợi một lát.';
    _show(
      title: 'Thử lại sau',
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.timer_rounded,
    );
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      icon: Icon(icon, color: AppColors.textOnPrimary),
      backgroundColor: backgroundColor,
      colorText: AppColors.textOnPrimary,
      titleText: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      messageText: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textOnPrimary,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }
}


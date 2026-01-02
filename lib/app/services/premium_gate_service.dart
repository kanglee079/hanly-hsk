import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/network/interceptors/premium_interceptor.dart';
import '../core/utils/logger.dart';
import '../modules/premium/widgets/premium_upsell_sheet.dart';

/// Service to handle premium gating and upsell modal display
///
/// Features:
/// - Throttles upsell display (30 second cooldown)
/// - Prevents multiple simultaneous modals
/// - Stores last premium details for UI
///
/// Note: Backend now correctly returns dailyNewLimit from user profile
/// (fixed in commit 11c2e01)
class PremiumGateService extends GetxService {
  /// Minimum time between upsell displays (milliseconds)
  static const int _throttleDurationMs = 30000; // 30 seconds

  /// Last time upsell was shown
  DateTime? _lastShownAt;

  /// Currently showing modal
  bool _isModalOpen = false;

  /// Last premium required details
  final Rx<PremiumRequiredDetails?> lastDetails = Rx<PremiumRequiredDetails?>(
    null,
  );

  /// Stream controller for premium required events
  final _premiumRequiredController =
      StreamController<PremiumRequiredDetails>.broadcast();

  /// Stream of premium required events (for listeners)
  Stream<PremiumRequiredDetails> get onPremiumRequired =>
      _premiumRequiredController.stream;

  @override
  void onClose() {
    _premiumRequiredController.close();
    super.onClose();
  }

  /// Trigger upsell modal (with throttling)
  void triggerUpsell(PremiumRequiredDetails details) {
    Logger.d('PremiumGateService', 'triggerUpsell: ${details.feature}');

    // Store details
    lastDetails.value = details;

    // Broadcast event
    _premiumRequiredController.add(details);

    // Check throttle
    if (_shouldThrottle()) {
      Logger.d('PremiumGateService', 'Throttled - showing too frequently');
      return;
    }

    // Check if modal already open
    if (_isModalOpen) {
      Logger.d('PremiumGateService', 'Modal already open');
      return;
    }

    // Show upsell
    _showUpsellModal(details);
  }

  /// Check if we should throttle the upsell
  bool _shouldThrottle() {
    if (_lastShownAt == null) return false;

    final elapsed = DateTime.now().difference(_lastShownAt!).inMilliseconds;
    return elapsed < _throttleDurationMs;
  }

  /// Show upsell bottom sheet
  void _showUpsellModal(PremiumRequiredDetails details) {
    _isModalOpen = true;
    _lastShownAt = DateTime.now();

    Get.bottomSheet(
      PremiumUpsellSheet(
        feature: details.feature,
        message: details.message,
        limit: details.limit,
        used: details.used,
        remaining: details.remaining,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    ).then((_) {
      _isModalOpen = false;
    });
  }

  /// Manually show upsell for a feature
  void showUpsellFor({
    required String feature,
    String? message,
    int? limit,
    int? used,
  }) {
    final details = PremiumRequiredDetails(
      code: 'PREMIUM_REQUIRED',
      message: message ?? 'Nâng cấp Premium để sử dụng tính năng này',
      feature: feature,
      limit: limit,
      used: used,
      remaining: limit != null && used != null ? (limit - used) : null,
    );

    triggerUpsell(details);
  }

  /// Check if a feature has reached its limit (for pre-emptive blocking)
  bool hasReachedLimit({
    required int? limit,
    required int used,
    required bool isPremium,
  }) {
    if (isPremium) return false;
    if (limit == null || limit == -1) return false;
    return used >= limit;
  }

  /// Get remaining uses for a feature
  int getRemainingUses({
    required int? limit,
    required int used,
    required bool isPremium,
  }) {
    if (isPremium) return -1; // Unlimited
    if (limit == null || limit == -1) return -1; // Unlimited
    return (limit - used).clamp(0, limit);
  }
}

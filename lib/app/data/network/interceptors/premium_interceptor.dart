import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../core/utils/logger.dart';
import '../../../services/premium_gate_service.dart';

/// Premium interceptor - handles 403 PREMIUM_REQUIRED responses globally
///
/// When backend returns 403 with error.code == 'PREMIUM_REQUIRED':
/// - Parses the premium details (feature, limit, used, remaining)
/// - Notifies PremiumGateService to show upsell modal
/// - Does NOT reject/throw - allows caller to handle gracefully
class PremiumInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check for 403 with PREMIUM_REQUIRED in body
    if (response.statusCode == 403 && _isPremiumRequired(response.data)) {
      _handlePremiumRequired(response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    // Check for 403 with PREMIUM_REQUIRED
    if (response?.statusCode == 403 && _isPremiumRequired(response?.data)) {
      _handlePremiumRequired(response!.data);
    }

    handler.next(err);
  }

  /// Check if response contains PREMIUM_REQUIRED error
  bool _isPremiumRequired(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return false;

    final error = data['error'];
    if (error == null || error is! Map<String, dynamic>) return false;

    final code = error['code']?.toString().toUpperCase();
    return code == 'PREMIUM_REQUIRED';
  }

  /// Handle premium required response
  void _handlePremiumRequired(Map<String, dynamic> data) {
    Logger.d('PremiumInterceptor', '🔒 PREMIUM_REQUIRED detected');

    final error = data['error'] as Map<String, dynamic>? ?? {};
    final details = PremiumRequiredDetails.fromJson(error);

    // Trigger upsell via service (throttled)
    try {
      if (Get.isRegistered<PremiumGateService>()) {
        final service = Get.find<PremiumGateService>();
        service.triggerUpsell(details);
      }
    } catch (e) {
      Logger.e('PremiumInterceptor', 'Failed to trigger upsell', e);
    }
  }
}

/// Details parsed from PREMIUM_REQUIRED error response
class PremiumRequiredDetails {
  final String code;
  final String message;
  final String? feature;
  final int? limit;
  final int? used;
  final int? remaining;
  final bool isPremium;

  PremiumRequiredDetails({
    required this.code,
    required this.message,
    this.feature,
    this.limit,
    this.used,
    this.remaining,
    this.isPremium = false,
  });

  factory PremiumRequiredDetails.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    Map<String, dynamic>? detailsMap;

    if (details is Map<String, dynamic>) {
      detailsMap = details;
    } else if (details is List && details.isNotEmpty && details.first is Map) {
      detailsMap = details.first as Map<String, dynamic>;
    }

    return PremiumRequiredDetails(
      code: json['code'] as String? ?? 'PREMIUM_REQUIRED',
      message: json['message'] as String? ?? 'Tính năng này yêu cầu Premium',
      feature: detailsMap?['feature'] as String?,
      limit: detailsMap?['limit'] as int?,
      used: detailsMap?['used'] as int?,
      remaining: detailsMap?['remaining'] as int?,
      isPremium: detailsMap?['isPremium'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'PremiumRequired: $feature (limit: $limit, used: $used, remaining: $remaining)';
}

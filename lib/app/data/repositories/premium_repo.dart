import '../models/subscription_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Repository for Premium/Subscription related API calls
class PremiumRepo {
  final ApiClient _api;

  PremiumRepo(this._api);

  /// Get current user's subscription info
  Future<SubscriptionModel> getSubscription() async {
    final response = await _api.get(ApiEndpoints.subscription);
    final data = response.data['data'] ?? response.data;
    return SubscriptionModel.fromJson(data);
  }

  /// Get available premium plans
  Future<List<PremiumPlanModel>> getPlans() async {
    final response = await _api.get(ApiEndpoints.premiumPlans);
    final data = response.data['data'] ?? response.data;
    final plans = data['plans'] as List<dynamic>? ?? [];
    return plans.map((e) => PremiumPlanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Subscribe to a premium plan
  Future<SubscriptionModel> subscribe({
    required String planId,
    required String paymentMethod,
    String? receiptData,
  }) async {
    final response = await _api.post(
      ApiEndpoints.premiumSubscribe,
      data: {
        'planId': planId,
        'paymentMethod': paymentMethod,
        if (receiptData != null) 'receiptData': receiptData,
      },
    );
    final data = response.data['data'] ?? response.data;
    return SubscriptionModel.fromJson(data);
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    await _api.post('${ApiEndpoints.subscription}/cancel');
  }

  /// Restore purchase (for iOS/Android IAP)
  Future<SubscriptionModel> restorePurchase({
    required String receiptData,
    required String platform, // "apple" | "google"
  }) async {
    final response = await _api.post(
      '${ApiEndpoints.subscription}/restore',
      data: {
        'receiptData': receiptData,
        'platform': platform,
      },
    );
    final data = response.data['data'] ?? response.data;
    return SubscriptionModel.fromJson(data);
  }
}


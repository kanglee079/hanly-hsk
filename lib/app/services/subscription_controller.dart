import 'package:get/get.dart';
import '../data/models/subscription_model.dart';
import '../data/repositories/premium_repo.dart';
import 'auth_session_service.dart';
import '../core/utils/logger.dart';

/// Reactive controller for subscription/premium state
/// Provides centralized access to user's premium status and limits
class SubscriptionController extends GetxController {
  final PremiumRepo _premiumRepo;
  final AuthSessionService _authService;

  SubscriptionController({
    required PremiumRepo premiumRepo,
    required AuthSessionService authService,
  }) : _premiumRepo = premiumRepo,
       _authService = authService;

  // Reactive subscription state
  final Rx<SubscriptionModel> subscription = SubscriptionModel().obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Convenience getters
  bool get isPremium => subscription.value.isPremium;
  bool get isActive => subscription.value.isActive;
  String get plan => subscription.value.plan;
  SubscriptionLimits get limits => subscription.value.limits;
  int get daysRemaining => subscription.value.daysRemaining;

  // Feature limits
  int get flashcardsPerDay => limits.flashcardsPerDay;
  int get gamePerDay => limits.gamePerDay;
  int get examAttemptsPerDay => limits.examAttemptsPerDay;
  bool get hasUnlimitedFlashcards => limits.hasUnlimitedFlashcards;
  bool get hasComprehensiveAccess => limits.hasComprehensive;

  @override
  void onInit() {
    super.onInit();

    // Listen to auth state changes
    ever(_authService.currentUser, (user) {
      if (user != null) {
        loadSubscription();
      } else {
        // Reset to free when logged out
        subscription.value = SubscriptionModel();
      }
    });

    // Load initial state if already logged in
    if (_authService.currentUser.value != null) {
      loadSubscription();
    }
  }

  /// Load subscription from API
  Future<void> loadSubscription() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _premiumRepo.getSubscription();
      subscription.value = result;
      Logger.d(
        'SubscriptionController',
        'Loaded: isPremium=${result.isPremium}, plan=${result.plan}',
      );
    } catch (e) {
      Logger.e('SubscriptionController', 'Failed to load subscription: $e');
      errorMessage.value = 'Không thể tải thông tin gói đăng ký';
      // Keep existing subscription state on error
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh subscription data
  @override
  Future<void> refresh() async {
    await loadSubscription();
  }

  /// Check if a specific feature is available
  bool canUseFeature(String featureId) {
    switch (featureId) {
      case 'comprehensive':
        return hasComprehensiveAccess;
      case 'unlimited_flashcards':
        return hasUnlimitedFlashcards;
      default:
        return isPremium || subscription.value.features.contains(featureId);
    }
  }

  /// Get remaining uses for a feature today
  /// Returns -1 for unlimited
  int getRemainingToday(String featureId) {
    if (isPremium) return -1; // Unlimited for premium

    switch (featureId) {
      case 'flashcards':
        return flashcardsPerDay;
      case 'game':
        return gamePerDay;
      case 'exam':
        return examAttemptsPerDay;
      default:
        return 0;
    }
  }

  /// Update subscription after successful purchase
  void updateSubscription(SubscriptionModel newSubscription) {
    subscription.value = newSubscription;
  }
}

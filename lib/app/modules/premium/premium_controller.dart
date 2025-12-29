import 'package:get/get.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/premium_repo.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';

/// Controller for Premium screen
class PremiumController extends GetxController {
  final PremiumRepo _premiumRepo = Get.find<PremiumRepo>();

  // Current subscription
  final Rxn<SubscriptionModel> subscription = Rxn<SubscriptionModel>();
  
  // Available plans from API
  final RxList<PremiumPlanModel> plans = <PremiumPlanModel>[].obs;
  
  // Selected plan index
  final RxInt selectedPlanIndex = 1.obs; // Default to yearly (most popular)
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isPurchasing = false.obs;
  final RxBool isRestoring = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    isLoading.value = true;
    try {
      // Load subscription and plans in parallel
      final results = await Future.wait([
        _premiumRepo.getSubscription(),
        _premiumRepo.getPlans(),
      ]);
      
      subscription.value = results[0] as SubscriptionModel;
      plans.value = results[1] as List<PremiumPlanModel>;
      
      // Auto-select popular plan
      final popularIndex = plans.indexWhere((p) => p.popular);
      if (popularIndex >= 0) {
        selectedPlanIndex.value = popularIndex;
      }
    } catch (e) {
      // Use fallback plans if API fails
      _useFallbackPlans();
    } finally {
      isLoading.value = false;
    }
  }

  void _useFallbackPlans() {
    plans.value = [
      PremiumPlanModel(
        id: 'monthly',
        name: 'Hàng tháng',
        price: 79000,
        period: 'month',
        features: [
          'Học từ mới không giới hạn',
          'Ôn tập tổng hợp',
          'Thống kê chi tiết',
        ],
      ),
      PremiumPlanModel(
        id: 'yearly',
        name: 'Hàng năm',
        price: 499000,
        period: 'year',
        discount: 47,
        originalPrice: 948000,
        popular: true,
        features: [
          'Học từ mới không giới hạn',
          'Ôn tập tổng hợp',
          'Tất cả đề thi HSK',
          'Bảo vệ streak 3 lần/tháng',
          'Thống kê 365 ngày',
        ],
      ),
      PremiumPlanModel(
        id: 'lifetime',
        name: 'Trọn đời',
        price: 999000,
        period: 'lifetime',
        features: [
          'Tất cả tính năng Premium',
          'Cập nhật miễn phí trọn đời',
          'Hỗ trợ ưu tiên',
        ],
      ),
    ];
  }

  /// Get selected plan
  PremiumPlanModel? get selectedPlan {
    if (plans.isEmpty || selectedPlanIndex.value >= plans.length) return null;
    return plans[selectedPlanIndex.value];
  }

  /// Check if user is already premium
  bool get isPremium => subscription.value?.isPremium ?? false;

  /// Check if subscription is active
  bool get isSubscriptionActive => subscription.value?.isActive ?? false;

  /// Get subscription expiry text
  String get expiryText {
    final sub = subscription.value;
    if (sub == null || !sub.isActive) return '';
    if (sub.plan == 'lifetime') return 'Trọn đời';
    final days = sub.daysRemaining;
    if (days <= 0) return 'Hết hạn';
    if (days == 1) return 'Còn 1 ngày';
    return 'Còn $days ngày';
  }

  /// Select a plan
  void selectPlan(int index) {
    if (index >= 0 && index < plans.length) {
      selectedPlanIndex.value = index;
    }
  }

  /// Get CTA button text
  String get ctaButtonText {
    final plan = selectedPlan;
    if (plan == null) return 'Đăng ký Premium';
    
    if (isPremium) return 'Đã là Premium';
    
    if (plan.period == 'lifetime') {
      return 'Mua ngay ${plan.formattedPrice}';
    }
    
    final periodText = plan.period == 'month' ? '/tháng' : '/năm';
    return 'Đăng ký ${plan.formattedPrice}$periodText';
  }

  /// Purchase selected plan
  Future<void> purchase() async {
    if (isPremium) {
      HMToast.info(ToastMessages.premiumAlreadyMember);
      return;
    }

    final plan = selectedPlan;
    if (plan == null) {
      HMToast.error(ToastMessages.premiumSelectPlan);
      return;
    }

    isPurchasing.value = true;
    
    try {
      // TODO: Integrate with StoreKit for iOS
      // For now, show coming soon message
      HMToast.info(ToastMessages.premiumPaymentComingSoon);
      
      // When StoreKit is integrated:
      // 1. Purchase product via StoreKit
      // 2. Get receipt data
      // 3. Send to backend for verification
      // await _premiumRepo.subscribe(
      //   planId: plan.id,
      //   receiptData: receiptData,
      //   platform: 'ios',
      // );
      // 4. Refresh subscription status
      // await _loadData();
      // HMToast.success('Đăng ký thành công!');
      
    } catch (e) {
      HMToast.error(ToastMessages.premiumPurchaseError);
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    isRestoring.value = true;
    
    try {
      // TODO: Integrate with StoreKit for iOS
      HMToast.info(ToastMessages.premiumRestoreComingSoon);
      
      // When StoreKit is integrated:
      // 1. Get receipts from StoreKit
      // 2. Send to backend for verification
      // await _premiumRepo.restorePurchases(receiptData: receiptData);
      // 3. Refresh subscription status
      // await _loadData();
      // HMToast.success('Khôi phục thành công!');
      
    } catch (e) {
      HMToast.error(ToastMessages.premiumRestoreError);
    } finally {
      isRestoring.value = false;
    }
  }

  /// Refresh subscription status
  Future<void> refresh() async {
    await _loadData();
  }
}


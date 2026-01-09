import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../services/auth_session_service.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';
import '../../data/network/api_client.dart';

/// Splash controller - handles initialization and navigation
class SplashController extends GetxController {
  late final StorageService _storage;
  late final ApiClient _apiClient;

  /// Loading progress (0.0 to 1.0)
  final RxDouble loadingProgress = 0.0.obs;

  /// Current loading message
  final RxString loadingMessage = 'Đang khởi động...'.obs;

  /// Animation states
  final RxBool showLogo = false.obs;
  final RxBool showTitle = false.obs;
  final RxBool showTagline = false.obs;
  final RxBool showLoader = false.obs;
  final RxBool isDataReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _apiClient = Get.find<ApiClient>();
    Logger.d('SplashController', 'onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    Logger.d('SplashController', 'onReady called');
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // Step 1: Show logo with animation
    await Future.delayed(const Duration(milliseconds: 300));
    showLogo.value = true;

    // Step 2: Show title
    await Future.delayed(const Duration(milliseconds: 400));
    showTitle.value = true;

    // Step 3: Show tagline
    await Future.delayed(const Duration(milliseconds: 300));
    showTagline.value = true;

    // Step 4: Show loader and start loading data
    await Future.delayed(const Duration(milliseconds: 400));
    showLoader.value = true;

    // Start actual data loading
    await _loadAppData();
  }

  Future<void> _loadAppData() async {
    try {
      // Phase 1: Check connectivity (20%)
      loadingMessage.value = 'Đang kiểm tra kết nối...';
      await _animateProgressTo(0.2);
      
      final isConnected = await _checkServerHealth();
      
      if (!isConnected) {
        loadingMessage.value = 'Đang sử dụng chế độ offline...';
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Phase 2: Load cached data (40%)
      loadingMessage.value = 'Đang tải dữ liệu...';
      await _animateProgressTo(0.4);
      await _loadCachedData();

      // Phase 3: Verify auth session (60%)
      loadingMessage.value = 'Đang xác thực...';
      await _animateProgressTo(0.6);
      await _verifyAuthSession();

      // Phase 4: Prepare UI (80%)
      loadingMessage.value = 'Đang chuẩn bị giao diện...';
      await _animateProgressTo(0.8);
      await Future.delayed(const Duration(milliseconds: 300));

      // Phase 5: Complete (100%)
      loadingMessage.value = 'Hoàn tất!';
      await _animateProgressTo(1.0);
      
      isDataReady.value = true;

      // Small delay before navigation for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));
      
      _navigateToNextScreen();
    } catch (e, stackTrace) {
      Logger.e('SplashController', 'Error during initialization', e);
      Logger.e('SplashController', 'Stack trace: $stackTrace');
      
      // Complete progress anyway and navigate
      loadingMessage.value = 'Đang hoàn tất...';
      await _animateProgressTo(1.0);
      await Future.delayed(const Duration(milliseconds: 300));
      
      _navigateToNextScreen();
    }
  }

  Future<bool> _checkServerHealth() async {
    try {
      final response = await _apiClient.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      Logger.w('SplashController', 'Health check failed: $e');
      return false;
    }
  }

  Future<void> _loadCachedData() async {
    // Load any cached preferences or data
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _verifyAuthSession() async {
    if (_storage.isLoggedIn) {
      try {
        final authService = Get.find<AuthSessionService>();
        // Verify token is still valid by loading user profile
        await authService.fetchCurrentUser();
      } catch (e) {
        Logger.w('SplashController', 'Session verification failed: $e');
        // Token might be expired, will be handled during navigation
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _animateProgressTo(double target) async {
    final current = loadingProgress.value;
    final steps = 10;
    final increment = (target - current) / steps;
    
    for (int i = 0; i < steps; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      loadingProgress.value = current + (increment * (i + 1));
    }
  }

  void _navigateToNextScreen() {
    final isLoggedIn = _storage.isLoggedIn;
    final isIntroSeen = _storage.isIntroSeen;
    final isSetupComplete = _storage.isSetupComplete;
    
    Logger.d('SplashController', 
      'Navigation check: isLoggedIn=$isLoggedIn, isIntroSeen=$isIntroSeen, isSetupComplete=$isSetupComplete');

    // Anonymous-First Flow:
    // 1. First launch (no tokens) → Intro slides → Setup → Create anonymous → Shell
    // 2. Returning user (has tokens) → Shell directly
    // 3. Setup not complete → Setup screen
    
    if (!isIntroSeen) {
      // First launch - show intro slides
      Logger.d('SplashController', 'First launch - navigating to intro');
      Get.offAllNamed(Routes.intro);
      return;
    }
    
    if (!isSetupComplete) {
      // Intro seen but setup not complete
      Logger.d('SplashController', 'Setup incomplete - navigating to setup');
      Get.offAllNamed(Routes.setup);
      return;
    }
    
    if (isLoggedIn) {
      // Has valid tokens - go to main app
      Logger.d('SplashController', 'Logged in - navigating to shell');
      Get.offAllNamed(Routes.shell);
    } else {
      // Setup complete but no tokens (edge case - token expired)
      // Create new anonymous user and go to shell
      Logger.d('SplashController', 'No tokens but setup complete - creating anonymous user');
      _createAnonymousAndNavigate();
    }
  }
  
  Future<void> _createAnonymousAndNavigate() async {
    try {
      final authService = Get.find<AuthSessionService>();
      final success = await authService.createAnonymousUser();
      
      if (success) {
        Get.offAllNamed(Routes.shell);
      } else {
        // Fallback - still try to go to shell (might work offline)
        Get.offAllNamed(Routes.shell);
      }
    } catch (e) {
      Logger.e('SplashController', 'Failed to create anonymous user', e);
      Get.offAllNamed(Routes.shell);
    }
  }
}

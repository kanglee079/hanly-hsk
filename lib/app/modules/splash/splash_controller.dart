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
    final authService = Get.find<AuthSessionService>();
    
    if (_storage.isLoggedIn) {
      // Has tokens - verify they're still valid
      try {
        await authService.fetchCurrentUser();
        Logger.d('SplashController', 'Existing session verified');
      } catch (e) {
        Logger.w('SplashController', 'Session verification failed: $e');
        // Token expired, will try to create/login with device ID
      }
    } else {
      // No tokens - try to create or login with device ID
      // This handles the case where device already has account on server
      Logger.d('SplashController', 'No tokens, trying device auth...');
      try {
        final success = await authService.createAnonymousUser();
        if (success) {
          Logger.d('SplashController', 'Device auth successful');
          // Fetch user profile after successful auth
          await authService.fetchCurrentUser();
        }
      } catch (e) {
        Logger.w('SplashController', 'Device auth failed: $e');
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
    // Re-check login status after auth attempt in _verifyAuthSession
    final isLoggedIn = _storage.isLoggedIn;
    final isIntroSeen = _storage.isIntroSeen;
    final isSetupComplete = _storage.isSetupComplete;
    final isOnboardingComplete = _storage.isOnboardingComplete;
    
    Logger.d('SplashController', 
      'Navigation: isLoggedIn=$isLoggedIn, isIntroSeen=$isIntroSeen, isSetupComplete=$isSetupComplete, isOnboardingComplete=$isOnboardingComplete');

    // PRIORITY 1: If logged in (has valid tokens from device auth)
    // Check if user has completed onboarding/profile setup on server
    if (isLoggedIn) {
      final authService = Get.find<AuthSessionService>();
      final user = authService.currentUser.value;
      final hasProfile = user?.hasProfile ?? false;
      
      if (hasProfile || isOnboardingComplete) {
        // User has profile - go to main app
        Logger.d('SplashController', 'Logged in with profile - going to shell');
        Get.offAllNamed(Routes.shell);
      } else {
        // Logged in but no profile - need setup
        // (This happens when device already had account but never completed setup)
        Logger.d('SplashController', 'Logged in but no profile - going to setup');
        _storage.isIntroSeen = true; // Skip intro since already has account
        Get.offAllNamed(Routes.setup);
      }
      return;
    }
    
    // PRIORITY 2: Not logged in - first time user flow
    if (!isIntroSeen) {
      Logger.d('SplashController', 'First launch - going to intro');
      Get.offAllNamed(Routes.intro);
      return;
    }
    
    if (!isSetupComplete) {
      Logger.d('SplashController', 'Setup incomplete - going to setup');
      Get.offAllNamed(Routes.setup);
      return;
    }
    
    // PRIORITY 3: Setup complete but no tokens (edge case - offline or error)
    Logger.d('SplashController', 'Setup complete but no tokens - going to shell anyway');
    Get.offAllNamed(Routes.shell);
  }
}

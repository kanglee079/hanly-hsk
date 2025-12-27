import 'package:get/get.dart';
import '../../services/storage_service.dart';
import '../../services/auth_session_service.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/logger.dart';

/// Splash controller
class SplashController extends GetxController {
  late final StorageService _storage;
  
  /// Loading progress (0.0 to 1.0)
  final RxDouble loadingProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    Logger.d('SplashController', 'onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    Logger.d('SplashController', 'onReady called');
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      Logger.d('SplashController', 'Starting auth check...');
      
      // Animate progress
      _animateProgress();
      
      // Simulate splash delay for branding
      await Future.delayed(const Duration(milliseconds: 1800));

      final isLoggedIn = _storage.isLoggedIn;
      Logger.d('SplashController', 'isLoggedIn: $isLoggedIn');

      if (isLoggedIn) {
        // Check if user needs onboarding
        final authService = Get.find<AuthSessionService>();
        Logger.d('SplashController', 'needsOnboarding: ${authService.needsOnboarding}');
        
        if (authService.needsOnboarding) {
          Logger.d('SplashController', 'Navigating to onboarding');
          Get.offAllNamed(Routes.onboarding);
        } else {
          Logger.d('SplashController', 'Navigating to shell');
          Get.offAllNamed(Routes.shell);
        }
      } else {
        Logger.d('SplashController', 'Navigating to auth');
        Get.offAllNamed(Routes.auth);
      }
    } catch (e, stackTrace) {
      Logger.e('SplashController', 'Error during auth check', e);
      Logger.e('SplashController', 'Stack trace: $stackTrace');
      // Fallback to auth screen on error
      Get.offAllNamed(Routes.auth);
    }
  }
  
  void _animateProgress() async {
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 80));
      loadingProgress.value = i / 100;
    }
  }
}

import 'package:get/get.dart';
import 'splash_controller.dart';

/// Splash binding
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}


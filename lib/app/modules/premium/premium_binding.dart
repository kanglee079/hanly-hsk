import 'package:get/get.dart';
import 'premium_controller.dart';

/// Binding for Premium screen
class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PremiumController>(() => PremiumController());
  }
}


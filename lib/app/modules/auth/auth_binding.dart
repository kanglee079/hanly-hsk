import 'package:get/get.dart';
import 'auth_controller.dart';

/// Auth binding
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}


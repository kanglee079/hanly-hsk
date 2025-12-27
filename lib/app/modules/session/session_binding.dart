import 'package:get/get.dart';
import 'session_controller.dart';

/// Session binding
class SessionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SessionController>(() => SessionController());
  }
}


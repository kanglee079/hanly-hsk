import 'package:get/get.dart';
import 'progress_controller.dart';

/// Binding for Progress screen
class ProgressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProgressController>(() => ProgressController());
  }
}


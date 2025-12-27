import 'package:get/get.dart';
import 'practice_controller.dart';

class PracticeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PracticeController>(() => PracticeController());
  }
}


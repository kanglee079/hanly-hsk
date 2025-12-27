import 'package:get/get.dart';
import 'pronunciation_controller.dart';

/// Pronunciation binding
class PronunciationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PronunciationController>(() => PronunciationController());
  }
}


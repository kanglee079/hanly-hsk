import 'package:get/get.dart';
import 'sentence_formation_controller.dart';

class SentenceFormationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SentenceFormationController>(() => SentenceFormationController());
  }
}

import 'package:get/get.dart';
import 'game30_controller.dart';

class Game30Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Game30Controller>(() => Game30Controller());
  }
}


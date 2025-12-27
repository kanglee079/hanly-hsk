import 'package:get/get.dart';
import 'game30_home_controller.dart';

class Game30HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Game30HomeController>(() => Game30HomeController());
  }
}


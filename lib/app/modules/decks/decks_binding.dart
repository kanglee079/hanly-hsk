import 'package:get/get.dart';
import 'decks_controller.dart';

/// Decks binding
class DecksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DecksController>(() => DecksController());
  }
}


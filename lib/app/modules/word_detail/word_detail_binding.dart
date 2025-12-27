import 'package:get/get.dart';
import 'word_detail_controller.dart';

/// Word detail binding
class WordDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WordDetailController>(() => WordDetailController());
  }
}


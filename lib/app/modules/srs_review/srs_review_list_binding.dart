import 'package:get/get.dart';
import 'srs_review_list_controller.dart';

class SrsReviewListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SrsReviewListController>(() => SrsReviewListController());
  }
}


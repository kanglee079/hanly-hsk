import 'package:get/get.dart';
import 'collection_detail_controller.dart';

/// Collection detail binding
class CollectionDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionDetailController>(() => CollectionDetailController());
  }
}


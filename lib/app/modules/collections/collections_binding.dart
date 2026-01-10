import 'package:get/get.dart';
import 'collections_controller.dart';

class CollectionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CollectionsController>(() => CollectionsController());
  }
}

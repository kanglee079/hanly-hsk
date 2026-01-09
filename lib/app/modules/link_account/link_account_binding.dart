import 'package:get/get.dart';
import 'link_account_controller.dart';

class LinkAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LinkAccountController>(() => LinkAccountController());
  }
}

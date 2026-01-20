import 'package:get/get.dart';
import 'offline_download_controller.dart';

class OfflineDownloadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => OfflineDownloadController());
  }
}

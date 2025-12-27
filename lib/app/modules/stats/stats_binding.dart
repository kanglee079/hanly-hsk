import 'package:get/get.dart';
import 'stats_controller.dart';

/// Stats binding
class StatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatsController>(() => StatsController());
  }
}


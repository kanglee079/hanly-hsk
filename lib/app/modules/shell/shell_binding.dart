import 'package:get/get.dart';
import 'shell_controller.dart';
import '../today/today_controller.dart';
import '../learn/learn_controller.dart';
import '../hsk_exam/hsk_exam_controller.dart';
import '../explore/explore_controller.dart';
import '../me/me_controller.dart';

/// Shell binding - All controllers initialize immediately for best UX
/// Data is loaded in parallel when user enters the main app
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    // Shell controller first
    Get.put<ShellController>(ShellController());
    
    // All tab controllers - use Get.put() to initialize immediately
    // This ensures all data is loaded in parallel when entering the app
    Get.put<TodayController>(TodayController());
    Get.put<LearnController>(LearnController());
    Get.put<HskExamController>(HskExamController());
    Get.put<ExploreController>(ExploreController());
    Get.put<MeController>(MeController());
  }
}


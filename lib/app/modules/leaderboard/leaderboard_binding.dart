import 'package:get/get.dart';
import 'leaderboard_controller.dart';

/// Leaderboard binding
class LeaderboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaderboardController>(() => LeaderboardController());
  }
}


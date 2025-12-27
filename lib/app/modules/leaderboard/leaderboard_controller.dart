import 'package:get/get.dart';
import '../../data/repositories/game_repo.dart';
import '../../core/utils/logger.dart';

/// Leaderboard controller
class LeaderboardController extends GetxController {
  final GameRepo _gameRepo = Get.find<GameRepo>();

  final RxString selectedGameType = 'speed30s'.obs;
  final RxString selectedPeriod = 'week'.obs;
  final RxBool isLoading = true.obs;
  final Rx<LeaderboardResponse?> leaderboard = Rx<LeaderboardResponse?>(null);
  final Rx<GameStats?> myStats = Rx<GameStats?>(null);

  final List<String> gameTypes = ['speed30s', 'listening', 'pronunciation', 'matching'];
  final List<String> periods = ['today', 'week', 'month', 'all'];

  String getGameTypeName(String type) {
    switch (type) {
      case 'speed30s':
        return 'Game 30s';
      case 'listening':
        return 'Luyện nghe';
      case 'pronunciation':
        return 'Phát âm';
      case 'matching':
        return 'Ghép từ';
      default:
        return type;
    }
  }

  String getPeriodName(String period) {
    switch (period) {
      case 'today':
        return 'Hôm nay';
      case 'week':
        return 'Tuần này';
      case 'month':
        return 'Tháng này';
      case 'all':
        return 'Tất cả';
      default:
        return period;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
    loadMyStats();
  }

  Future<void> loadLeaderboard() async {
    isLoading.value = true;
    try {
      final response = await _gameRepo.getLeaderboard(
        selectedGameType.value,
        period: selectedPeriod.value,
        limit: 50,
      );
      leaderboard.value = response;
    } catch (e) {
      Logger.e('LeaderboardController', 'loadLeaderboard error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyStats() async {
    try {
      myStats.value = await _gameRepo.getMyStats();
    } catch (e) {
      Logger.e('LeaderboardController', 'loadMyStats error', e);
    }
  }

  void setGameType(String type) {
    if (selectedGameType.value != type) {
      selectedGameType.value = type;
      loadLeaderboard();
    }
  }

  void setPeriod(String period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadLeaderboard();
    }
  }

  @override
  Future<void> refresh() async {
    await Future.wait([loadLeaderboard(), loadMyStats()]);
  }
}


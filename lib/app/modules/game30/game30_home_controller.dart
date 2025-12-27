import 'package:get/get.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../data/repositories/game_repo.dart';
import '../../routes/app_routes.dart';
import '../../services/realtime/today_store.dart';
import '../../services/storage_service.dart';

/// Game 30s Home Controller - Manages leaderboard and game launch
class Game30HomeController extends GetxController {
  final TodayStore _todayStore = Get.find<TodayStore>();
  final StorageService _storage = Get.find<StorageService>();
  GameRepo? _gameRepo;

  // Minimum words required to play Game 30s
  // Need at least 50 learned words to avoid word repetition
  static const int minRequiredWords = 50;
  
  // Daily game limit for free users
  static const int dailyGameLimitFree = 3;

  // State
  final RxBool isLoading = true.obs;
  final RxBool isStartingGame = false.obs;
  final RxList<LeaderboardEntry> leaderboardEntries = <LeaderboardEntry>[].obs;
  final Rxn<LeaderboardEntry> currentUserEntry = Rxn<LeaderboardEntry>();
  final RxInt totalPlayers = 0.obs;
  final RxInt localHighScore = 0.obs;
  final RxInt gamesPlayed = 0.obs;
  final RxBool canPlay = false.obs;
  final RxInt learnedWordsCount = 0.obs;
  
  // Game limit state
  final Rx<GameLimitInfo> gameLimit = GameLimitInfo().obs;
  final RxString cannotPlayReason = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _gameRepo = Get.isRegistered<GameRepo>() ? Get.find<GameRepo>() : null;
    _loadLocalStats();
    loadLeaderboard();
    _checkCanPlay();
  }

  /// Load local stats from storage (used as fallback)
  void _loadLocalStats() {
    try {
      localHighScore.value = _storage.getGame30sHighScore();
      // Local games played is just a fallback - API data takes priority
      final localGames = _storage.getGame30sGamesPlayed();
      if (gamesPlayed.value == 0) {
        gamesPlayed.value = localGames;
      }
    } catch (e) {
      Logger.e('Game30HomeController', 'Failed to load local stats', e);
    }
  }

  /// Check if user can play (needs minimum words + daily limit)
  void _checkCanPlay() {
    final today = _todayStore.today.data.value;
    if (today != null) {
      _updatePlayStatus(today);
    }
    
    // Listen to data updates
    ever(_todayStore.today.data, (data) {
      if (data != null) {
        _updatePlayStatus(data);
      }
    });
  }

  void _updatePlayStatus(dynamic today) {
    // Use totalLearned from API (total words learned since account creation)
    // Fall back to reviewQueue.length if not available
    final totalLearned = today.totalLearned as int? ?? today.reviewQueue.length;
    learnedWordsCount.value = totalLearned;
    
    // Check game limit from API
    if (today.gameLimit != null) {
      gameLimit.value = today.gameLimit;
    }
    
    // Determine if user can play
    String reason = '';
    bool canPlayNow = true;
    
    // Check 1: Minimum words requirement
    if (totalLearned < minRequiredWords) {
      canPlayNow = false;
      reason = 'Cần học tối thiểu $minRequiredWords từ để chơi.\nĐã học $totalLearned từ.';
    }
    // Check 2: Daily game limit (from API or local check)
    else if (gameLimit.value.canPlayGame == false) {
      canPlayNow = false;
      reason = 'Đã hết lượt chơi hôm nay (${gameLimit.value.gamePlaysToday}/${gameLimit.value.dailyGameLimit}).\nNâng cấp Premium để chơi không giới hạn!';
    }
    
    canPlay.value = canPlayNow;
    cannotPlayReason.value = reason;
  }

  /// Load leaderboard from API
  Future<void> loadLeaderboard() async {
    isLoading.value = true;
    
    try {
      if (_gameRepo != null) {
        // Load from API
        final response = await _gameRepo!.getLeaderboard(
          'speed30s',
          period: 'all',
          limit: 20,
        );
        
        Logger.d('Game30HomeController', 
          'Leaderboard API response: entries=${response.entries.length}, '
          'totalPlayers=${response.totalPlayers}, '
          'myRank=${response.myRank?.rank}, myScore=${response.myRank?.score}');
        
        // Use server data directly
        leaderboardEntries.value = response.entries;
        currentUserEntry.value = response.myRank;
        totalPlayers.value = response.totalPlayers;
        
        // Sync local storage with server data
        if (response.myRank != null) {
          if (response.myRank!.gamesPlayed > 0) {
            gamesPlayed.value = response.myRank!.gamesPlayed;
            _storage.setGame30sGamesPlayed(response.myRank!.gamesPlayed);
          }
          if (response.myRank!.score > 0) {
            localHighScore.value = response.myRank!.score;
            _storage.setGame30sHighScore(response.myRank!.score);
          }
        }
      } else {
        Logger.w('Game30HomeController', 'GameRepo not available');
      }
    } catch (e) {
      Logger.e('Game30HomeController', 'Failed to load leaderboard', e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Start the game
  Future<void> startGame() async {
    if (!canPlay.value) {
      if (cannotPlayReason.value.isNotEmpty) {
        HMToast.warning(cannotPlayReason.value);
      } else {
        HMToast.warning('Không thể bắt đầu game!');
      }
      return;
    }

    isStartingGame.value = true;
    
    try {
      // Navigate to game screen
      final result = await Get.toNamed(Routes.game30Play);
      
      // Update stats after game ends
      if (result is Map) {
        final score = result['score'] as int? ?? 0;
        final gameLimitData = result['gameLimit'];
        GameLimitInfo? newGameLimit;
        if (gameLimitData is GameLimitInfo) {
          newGameLimit = gameLimitData;
        } else if (gameLimitData is Map<String, dynamic>) {
          newGameLimit = GameLimitInfo.fromJson(gameLimitData);
        }
        updateAfterGame(score, newGameLimit: newGameLimit);
      }
      
      // Reload leaderboard
      await loadLeaderboard();
      // Refresh today data to get updated game limit
      _todayStore.today.syncNow(force: true);
    } catch (e) {
      Logger.e('Game30HomeController', 'Failed to start game', e);
      HMToast.error('Không thể bắt đầu game');
    } finally {
      isStartingGame.value = false;
    }
  }

  /// Called after game ends to update local stats
  void updateAfterGame(int score, {GameLimitInfo? newGameLimit}) {
    // Update game limit if provided by API
    if (newGameLimit != null) {
      gameLimit.value = newGameLimit;
      // Use gamePlaysToday from API response (more accurate)
      gamesPlayed.value = newGameLimit.gamePlaysToday;
      _storage.setGame30sGamesPlayed(newGameLimit.gamePlaysToday);
    } else {
      // Fallback: Increment games played locally
      gamesPlayed.value++;
      _storage.setGame30sGamesPlayed(gamesPlayed.value);
    }
    
    // Update high score if this is a new record
    if (score > localHighScore.value) {
      localHighScore.value = score;
      _storage.setGame30sHighScore(score);
      HMToast.success('🎉 Kỷ lục mới: $score điểm!');
    }
    
    // Recheck if can play
    final today = _todayStore.today.data.value;
    if (today != null) {
      _updatePlayStatus(today);
    }
  }
  
  /// Get remaining game plays display
  String get remainingPlaysDisplay {
    if (gameLimit.value.isPremium) return '∞';
    return '${gameLimit.value.remainingPlays}/${gameLimit.value.dailyGameLimit}';
  }
}


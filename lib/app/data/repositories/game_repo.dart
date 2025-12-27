import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../core/utils/logger.dart';

/// Game repository for leaderboard and game sessions
class GameRepo {
  final ApiClient _api;

  GameRepo(this._api);

  /// Get leaderboard for a game type
  /// [gameType]: speed30s, listening, pronunciation, matching
  /// [period]: today, week, month, all
  Future<LeaderboardResponse> getLeaderboard(
    String gameType, {
    String period = 'all',
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiEndpoints.gameLeaderboard(gameType),
      queryParameters: {
        'period': period,
        'limit': limit,
      },
    );
    final data = response.data['data'] ?? response.data;
    return LeaderboardResponse.fromJson(data);
  }

  /// Submit game result
  /// 
  /// BE expects:
  /// - gameType: "speed30s" | "listening" | "pronunciation" | "matching"
  /// - score: number >= 0
  /// - correctCount: number >= 0
  /// - totalCount: number >= 1
  /// - timeSpent: number in milliseconds
  /// - level: string (optional, default "HSK1")
  Future<GameSubmitResponse> submitGame({
    required String gameType,
    required int score,
    required int correctCount,
    required int totalCount,
    required int timeSpent,
    String level = 'HSK1',
  }) async {
    final requestBody = {
      'gameType': gameType,
      'score': score,
      'correctCount': correctCount,
      'totalCount': totalCount,
      'timeSpent': timeSpent,
      'level': level,
    };
    
    Logger.d('GameRepo', 'submitGame request: $requestBody');
    
    final response = await _api.post(
      ApiEndpoints.gameSubmit,
      data: requestBody,
    );
    
    Logger.d('GameRepo', 'submitGame response: ${response.data}');
    
    // Check if API returned success: false
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      if (responseData['success'] == false) {
        final error = responseData['error'];
        final message = error is Map ? error['message'] : 'Submit failed';
        throw Exception('Game submit failed: $message');
      }
    }
    
    final data = responseData['data'] ?? responseData;
    return GameSubmitResponse.fromJson(data);
  }

  /// Get my game stats
  Future<GameStats> getMyStats() async {
    final response = await _api.get(ApiEndpoints.gameMyStats);
    final data = response.data['data'] ?? response.data;
    return GameStats.fromJson(data);
  }
}

/// Leaderboard response
class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final LeaderboardEntry? myRank;
  final int totalPlayers;

  LeaderboardResponse({
    required this.entries,
    this.myRank,
    this.totalPlayers = 0,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      entries: (json['entries'] as List? ?? [])
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      myRank: json['myRank'] != null
          ? LeaderboardEntry.fromJson(json['myRank'])
          : null,
      totalPlayers: json['totalPlayers'] as int? ?? 0,
    );
  }
}

/// Leaderboard entry
class LeaderboardEntry {
  final int rank;
  final String odId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int gamesPlayed;
  final double accuracy;

  LeaderboardEntry({
    required this.rank,
    required this.odId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    this.gamesPlayed = 0,
    this.accuracy = 0,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      odId: json['userId'] as String? ?? json['_id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Ẩn danh',
      avatarUrl: json['avatarUrl'] as String?,
      score: json['score'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Game submit response
/// 
/// BE returns:
/// - session: { id, score, correctCount, totalCount, accuracy, timeSpent }
/// - rank: { rank, bestScore, percentile }
/// - newAchievements: ["achievement_id", ...]
/// - gameLimit: { gamePlaysToday, dailyGameLimit, remainingPlays, canPlayGame, isPremium }
class GameSubmitResponse {
  final GameSession session;
  final GameRank? rank;
  final List<String>? newAchievements;
  final GameLimitInfo? gameLimit;

  GameSubmitResponse({
    required this.session,
    this.rank,
    this.newAchievements,
    this.gameLimit,
  });

  factory GameSubmitResponse.fromJson(Map<String, dynamic> json) {
    return GameSubmitResponse(
      session: GameSession.fromJson(json['session'] ?? json),
      rank: json['rank'] != null 
          ? GameRank.fromJson(json['rank']) 
          : null,
      newAchievements: (json['newAchievements'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      gameLimit: json['gameLimit'] != null
          ? GameLimitInfo.fromJson(json['gameLimit'])
          : null,
    );
  }
  
  /// Check if this is a new high score
  bool get isNewHighScore => rank?.bestScore == session.score;
}

/// Game rank info from submit response
class GameRank {
  final int rank;
  final int bestScore;
  final double percentile;
  
  GameRank({
    required this.rank,
    required this.bestScore,
    this.percentile = 0,
  });
  
  factory GameRank.fromJson(Map<String, dynamic> json) {
    return GameRank(
      rank: json['rank'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      percentile: (json['percentile'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Game limit info for daily play limits
class GameLimitInfo {
  final int gamePlaysToday;
  final int dailyGameLimit;
  final int remainingPlays;
  final bool canPlayGame;
  final bool isPremium;

  GameLimitInfo({
    this.gamePlaysToday = 0,
    this.dailyGameLimit = 3,
    this.remainingPlays = 3,
    this.canPlayGame = true,
    this.isPremium = false,
  });

  factory GameLimitInfo.fromJson(Map<String, dynamic> json) {
    return GameLimitInfo(
      gamePlaysToday: json['gamePlaysToday'] as int? ?? 0,
      dailyGameLimit: json['dailyGameLimit'] as int? ?? 3,
      remainingPlays: json['remainingPlays'] as int? ?? 3,
      canPlayGame: json['canPlayGame'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  String get limitDisplay {
    if (isPremium) return '∞';
    return '$remainingPlays/$dailyGameLimit';
  }
}

/// Game session model
class GameSession {
  final String id;
  final String gameType;
  final int score;
  final int totalCount;
  final int correctCount;
  final int timeSpent;
  final double accuracy;
  final DateTime createdAt;

  GameSession({
    required this.id,
    this.gameType = '',
    required this.score,
    this.totalCount = 0,
    this.correctCount = 0,
    this.timeSpent = 0,
    this.accuracy = 0,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      gameType: json['gameType'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      timeSpent: json['timeSpent'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Game stats model
class GameStats {
  final Map<String, GameTypeStats> byType;
  final int totalGames;
  final int totalScore;
  final double overallAccuracy;

  GameStats({
    required this.byType,
    this.totalGames = 0,
    this.totalScore = 0,
    this.overallAccuracy = 0,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) {
    // BE returns stats by game type at root level
    final Map<String, GameTypeStats> byType = {};
    
    for (final gameType in ['speed30s', 'listening', 'pronunciation', 'matching']) {
      if (json[gameType] != null) {
        byType[gameType] = GameTypeStats.fromJson(json[gameType]);
      }
    }
    
    return GameStats(
      byType: byType,
      totalGames: json['totalGames'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      overallAccuracy: (json['overallAccuracy'] as num?)?.toDouble() ?? 0,
    );
  }
  
  /// Get stats for a specific game type
  GameTypeStats? getStats(String gameType) => byType[gameType];
}

/// Stats for a specific game type
class GameTypeStats {
  final int totalGames;
  final int bestScore;
  final double avgScore;
  final GameRank? rank;
  final List<RecentGame> recentGames;

  GameTypeStats({
    this.totalGames = 0,
    this.bestScore = 0,
    this.avgScore = 0,
    this.rank,
    this.recentGames = const [],
  });

  factory GameTypeStats.fromJson(Map<String, dynamic> json) {
    return GameTypeStats(
      totalGames: json['totalGames'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] != null ? GameRank.fromJson(json['rank']) : null,
      recentGames: (json['recentGames'] as List? ?? [])
          .map((e) => RecentGame.fromJson(e))
          .toList(),
    );
  }
}

/// Recent game entry
class RecentGame {
  final int score;
  final double accuracy;
  final DateTime date;
  
  RecentGame({
    required this.score,
    required this.accuracy,
    required this.date,
  });
  
  factory RecentGame.fromJson(Map<String, dynamic> json) {
    return RecentGame(
      score: json['score'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      date: json['date'] != null 
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
    );
  }
}

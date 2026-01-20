import 'package:get_storage/get_storage.dart';
import '../data/models/user_model.dart';

/// Storage service using GetStorage
class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLastEmail = 'last_email';
  static const String _keyRecentVocabs = 'recent_vocabs';
  static const String _keyDailyPick = 'daily_pick';
  static const String _keyMagicLinkAttempts = 'magic_link_attempts';
  static const String _keyMagicLinkLastAttempt = 'magic_link_last_attempt';
  static const String _keyLearnNewCompletedByDate = 'learn_new_completed_by_date';
  static const String _keyLearnNewVocabsByDate = 'learn_new_vocabs_by_date';
  static const String _keyGame30sHighScore = 'game30s_high_score';
  static const String _keyGame30sGamesPlayed = 'game30s_games_played';
  static const String _keyCompletedTutorials = 'completed_tutorials';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  
  // Anonymous-First flow keys
  static const String _keyDeviceId = 'device_id';
  static const String _keyIsAnonymous = 'is_anonymous';
  static const String _keyIsIntroSeen = 'is_intro_seen';
  static const String _keyIsSetupComplete = 'is_setup_complete';
  static const String _keyUserDisplayName = 'user_display_name';
  static const String _keyUserLevel = 'user_level';
  static const String _keyUserGoals = 'user_goals';
  static const String _keyUserDailyMinutes = 'user_daily_minutes';
  static const String _keyUserDailyNewLimit = 'user_daily_new_limit';

  final GetStorage _box;

  StorageService() : _box = GetStorage();

  /// Initialize storage
  static Future<void> init() async {
    await GetStorage.init();
  }

  // Access Token
  String? get accessToken => _box.read<String>(_keyAccessToken);
  set accessToken(String? value) {
    if (value == null) {
      _box.remove(_keyAccessToken);
    } else {
      _box.write(_keyAccessToken, value);
    }
  }

  // Refresh Token
  String? get refreshToken => _box.read<String>(_keyRefreshToken);
  set refreshToken(String? value) {
    if (value == null) {
      _box.remove(_keyRefreshToken);
    } else {
      _box.write(_keyRefreshToken, value);
    }
  }

  // User
  UserModel? get user {
    final data = _box.read<Map<String, dynamic>>(_keyUser);
    if (data == null) return null;
    try {
      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  set user(UserModel? value) {
    if (value == null) {
      _box.remove(_keyUser);
    } else {
      _box.write(_keyUser, value.toJson());
    }
  }

  // Onboarding complete (deprecated, use isSetupComplete)
  bool get isOnboardingComplete =>
      _box.read<bool>(_keyOnboardingComplete) ?? false;
  set isOnboardingComplete(bool value) =>
      _box.write(_keyOnboardingComplete, value);
  
  // === Anonymous-First Flow ===
  
  // Device ID (unique per device, persists across reinstalls)
  String? get deviceId => _box.read<String>(_keyDeviceId);
  set deviceId(String? value) {
    if (value == null) {
      _box.remove(_keyDeviceId);
    } else {
      _box.write(_keyDeviceId, value);
    }
  }
  
  // Is user anonymous (not linked email)
  bool get isAnonymous => _box.read<bool>(_keyIsAnonymous) ?? true;
  set isAnonymous(bool value) => _box.write(_keyIsAnonymous, value);
  
  // Has user seen intro slides
  bool get isIntroSeen => _box.read<bool>(_keyIsIntroSeen) ?? false;
  set isIntroSeen(bool value) => _box.write(_keyIsIntroSeen, value);
  
  // Has user completed initial setup (name, level, goals)
  bool get isSetupComplete => _box.read<bool>(_keyIsSetupComplete) ?? false;
  set isSetupComplete(bool value) => _box.write(_keyIsSetupComplete, value);
  
  // User display name (local)
  String? get userDisplayName => _box.read<String>(_keyUserDisplayName);
  set userDisplayName(String? value) {
    if (value == null) {
      _box.remove(_keyUserDisplayName);
    } else {
      _box.write(_keyUserDisplayName, value);
    }
  }
  
  // User HSK level (local)
  String? get userLevel => _box.read<String>(_keyUserLevel);
  set userLevel(String? value) {
    if (value == null) {
      _box.remove(_keyUserLevel);
    } else {
      _box.write(_keyUserLevel, value);
    }
  }
  
  // User learning goals (local)
  List<String> get userGoals {
    final data = _box.read<List<dynamic>>(_keyUserGoals);
    if (data == null) return [];
    return data.cast<String>();
  }
  set userGoals(List<String> value) => _box.write(_keyUserGoals, value);
  
  // User daily minutes target (local) - DEPRECATED, use userDailyNewLimit
  int get userDailyMinutes => _box.read<int>(_keyUserDailyMinutes) ?? userDailyNewLimit;
  set userDailyMinutes(int value) => _box.write(_keyUserDailyMinutes, value);
  
  // User daily new word limit (local) - PRIMARY source
  // 1 word = 1 minute, so dailyMinutes = dailyNewLimit
  int get userDailyNewLimit => _box.read<int>(_keyUserDailyNewLimit) ?? 10;
  set userDailyNewLimit(int value) {
    _box.write(_keyUserDailyNewLimit, value);
    // Sync to minutes for backward compatibility (1 word = 1 minute)
    _box.write(_keyUserDailyMinutes, value);
  }

  // Theme mode: 'light', 'dark', 'system'
  String get themeMode => _box.read<String>(_keyThemeMode) ?? 'system';
  set themeMode(String value) => _box.write(_keyThemeMode, value);

  // Last email used (for dev mode magic link)
  String? get lastEmail => _box.read<String>(_keyLastEmail);
  set lastEmail(String? value) {
    if (value == null) {
      _box.remove(_keyLastEmail);
    } else {
      _box.write(_keyLastEmail, value);
    }
  }

  // Check if logged in (has valid tokens)
  bool get isLoggedIn {
    final token = accessToken;
    return token != null && token.isNotEmpty;
  }

  // Check if user has complete profile
  bool get hasCompleteProfile => user?.hasProfile ?? false;

  // Save auth tokens atomically
  void saveTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  // Clear all auth data and user-specific data
  void clearAuth() {
    _box.remove(_keyAccessToken);
    _box.remove(_keyRefreshToken);
    _box.remove(_keyUser);
    clearUserSpecificData();
  }
  
  /// Clear only user-specific data (NOT tokens)
  /// Called when switching accounts to prevent cross-account data leakage
  void clearUserSpecificData() {
    _box.remove(_keyUser);
    _box.remove(_keyOnboardingComplete);
    // Clear user-specific cached data
    _box.remove(_keyRecentVocabs);
    _box.remove(_keyDailyPick);
    // Clear learning progress cache (user-specific!)
    _box.remove(_keyLearnNewCompletedByDate);
    _box.remove(_keyLearnNewVocabsByDate);
    // Clear anonymous-first flow data
    _box.remove(_keyIsAnonymous);
    _box.remove(_keyIsSetupComplete);
    _box.remove(_keyUserDisplayName);
    _box.remove(_keyUserLevel);
    _box.remove(_keyUserGoals);
    _box.remove(_keyUserDailyMinutes);
    _box.remove(_keyUserDailyNewLimit);
    // Keep lastEmail, isIntroSeen, and deviceId for convenience
  }

  // Clear all storage
  Future<void> clearAll() async {
    await _box.erase();
  }

  // Recent vocabs
  List<dynamic>? getRecentVocabs() {
    return _box.read<List<dynamic>>(_keyRecentVocabs);
  }

  void saveRecentVocabs(List<Map<String, dynamic>> vocabs) {
    _box.write(_keyRecentVocabs, vocabs);
  }

  // Daily pick
  Map<String, dynamic>? getDailyPick() {
    return _box.read<Map<String, dynamic>>(_keyDailyPick);
  }

  void saveDailyPick(Map<String, dynamic> data) {
    _box.write(_keyDailyPick, data);
  }

  // Magic link rate limiting (5 requests per 15 minutes)
  static const int _maxMagicLinkAttempts = 5;
  static const int _magicLinkWindowMinutes = 15;

  // ===== Learn New progress (client-side fallback) =====
  //
  // We store vocabIds completed for each local dateKey (YYYY-MM-DD).
  // This is a safety net to avoid repeating the same "Học từ mới" words
  // if BE queue refresh lags or the user continues multiple sessions in a day.

  Map<String, dynamic> _readLearnNewCompletedMap() {
    final raw = _box.read<Map<String, dynamic>>(_keyLearnNewCompletedByDate);
    if (raw == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(raw);
  }

  List<String> getLearnNewCompletedVocabIds(String dateKey) {
    final map = _readLearnNewCompletedMap();
    final raw = map[dateKey];
    if (raw is List) {
      return raw.whereType<String>().where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
  }

  void addLearnNewCompletedVocabId(String dateKey, String vocabId) {
    if (dateKey.isEmpty || vocabId.isEmpty) return;
    final map = _readLearnNewCompletedMap();
    final ids = <String>{...getLearnNewCompletedVocabIds(dateKey)};
    ids.add(vocabId);
    map[dateKey] = ids.toList();
    _box.write(_keyLearnNewCompletedByDate, map);
  }

  void clearLearnNewCompletedForDate(String dateKey) {
    final map = _readLearnNewCompletedMap();
    map.remove(dateKey);
    _box.write(_keyLearnNewCompletedByDate, map);
  }

  // ===== Store full vocab data for củng cố (review today) =====
  
  Map<String, dynamic> _readLearnNewVocabsMap() {
    final raw = _box.read<Map<String, dynamic>>(_keyLearnNewVocabsByDate);
    if (raw == null) return <String, dynamic>{};
    return Map<String, dynamic>.from(raw);
  }

  /// Store full vocab JSON for củng cố later
  void addLearnNewVocab(String dateKey, Map<String, dynamic> vocabJson) {
    if (dateKey.isEmpty) return;
    final vocabId = vocabJson['id'] as String? ?? vocabJson['_id'] as String? ?? '';
    if (vocabId.isEmpty) return;
    
    final map = _readLearnNewVocabsMap();
    final vocabsRaw = map[dateKey] as Map<String, dynamic>? ?? <String, dynamic>{};
    vocabsRaw[vocabId] = vocabJson;
    map[dateKey] = vocabsRaw;
    _box.write(_keyLearnNewVocabsByDate, map);
  }

  /// Get all vocabs learned today as list of JSON maps
  List<Map<String, dynamic>> getLearnNewVocabs(String dateKey) {
    final map = _readLearnNewVocabsMap();
    final vocabsRaw = map[dateKey] as Map<String, dynamic>?;
    if (vocabsRaw == null) return const [];
    
    return vocabsRaw.values
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Clear vocabs for a specific date
  void clearLearnNewVocabsForDate(String dateKey) {
    final map = _readLearnNewVocabsMap();
    map.remove(dateKey);
    _box.write(_keyLearnNewVocabsByDate, map);
  }

  /// Check if magic link can be sent (not rate limited)
  bool canSendMagicLink() {
    final attempts = _box.read<int>(_keyMagicLinkAttempts) ?? 0;
    final lastAttemptStr = _box.read<String>(_keyMagicLinkLastAttempt);
    
    if (lastAttemptStr == null) return true;
    
    final lastAttempt = DateTime.tryParse(lastAttemptStr);
    if (lastAttempt == null) return true;
    
    final windowEnd = lastAttempt.add(const Duration(minutes: _magicLinkWindowMinutes));
    
    // If window has passed, reset counter
    if (DateTime.now().isAfter(windowEnd)) {
      _box.remove(_keyMagicLinkAttempts);
      _box.remove(_keyMagicLinkLastAttempt);
      return true;
    }
    
    // Check if under limit
    return attempts < _maxMagicLinkAttempts;
  }

  /// Get remaining seconds before magic link can be sent again
  int getMagicLinkCooldownSeconds() {
    final lastAttemptStr = _box.read<String>(_keyMagicLinkLastAttempt);
    if (lastAttemptStr == null) return 0;
    
    final lastAttempt = DateTime.tryParse(lastAttemptStr);
    if (lastAttempt == null) return 0;
    
    final windowEnd = lastAttempt.add(const Duration(minutes: _magicLinkWindowMinutes));
    final remaining = windowEnd.difference(DateTime.now()).inSeconds;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Record a magic link attempt
  void recordMagicLinkAttempt() {
    final attempts = _box.read<int>(_keyMagicLinkAttempts) ?? 0;
    final lastAttemptStr = _box.read<String>(_keyMagicLinkLastAttempt);
    
    // Check if we need to start a new window
    if (lastAttemptStr != null) {
      final lastAttempt = DateTime.tryParse(lastAttemptStr);
      if (lastAttempt != null) {
        final windowEnd = lastAttempt.add(const Duration(minutes: _magicLinkWindowMinutes));
        if (DateTime.now().isAfter(windowEnd)) {
          // New window, reset counter
          _box.write(_keyMagicLinkAttempts, 1);
          _box.write(_keyMagicLinkLastAttempt, DateTime.now().toIso8601String());
          return;
        }
      }
    }
    
    // Same window, increment counter
    _box.write(_keyMagicLinkAttempts, attempts + 1);
    if (lastAttemptStr == null) {
      _box.write(_keyMagicLinkLastAttempt, DateTime.now().toIso8601String());
    }
  }

  /// Get remaining magic link attempts
  int getRemainingMagicLinkAttempts() {
    final attempts = _box.read<int>(_keyMagicLinkAttempts) ?? 0;
    return _maxMagicLinkAttempts - attempts;
  }

  // ===== Game 30s Stats =====

  /// Get Game 30s high score
  int getGame30sHighScore() {
    return _box.read<int>(_keyGame30sHighScore) ?? 0;
  }

  /// Set Game 30s high score
  void setGame30sHighScore(int score) {
    _box.write(_keyGame30sHighScore, score);
  }

  /// Get Game 30s total games played
  int getGame30sGamesPlayed() {
    return _box.read<int>(_keyGame30sGamesPlayed) ?? 0;
  }

  /// Set Game 30s total games played
  void setGame30sGamesPlayed(int count) {
    _box.write(_keyGame30sGamesPlayed, count);
  }

  // ===== Tutorial =====

  /// Get completed tutorials
  List<String> getCompletedTutorials() {
    final data = _box.read<List<dynamic>>(_keyCompletedTutorials);
    if (data == null) return [];
    return data.cast<String>();
  }

  /// Set completed tutorials
  void setCompletedTutorials(List<String> tutorialIds) {
    _box.write(_keyCompletedTutorials, tutorialIds);
  }

  /// Check if a specific tutorial is completed
  bool isTutorialCompleted(String tutorialId) {
    return getCompletedTutorials().contains(tutorialId);
  }

  /// Mark a tutorial as completed
  void markTutorialCompleted(String tutorialId) {
    final completed = getCompletedTutorials();
    if (!completed.contains(tutorialId)) {
      completed.add(tutorialId);
      setCompletedTutorials(completed);
    }
  }

  // ===== Sound & Haptics Settings =====

  /// Sound enabled
  bool get soundEnabled => _box.read<bool>(_keySoundEnabled) ?? true;
  set soundEnabled(bool value) => _box.write(_keySoundEnabled, value);

  /// Haptics enabled
  bool get hapticsEnabled => _box.read<bool>(_keyHapticsEnabled) ?? true;
  set hapticsEnabled(bool value) => _box.write(_keyHapticsEnabled, value);
}

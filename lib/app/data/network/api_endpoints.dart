/// API endpoints
/// See docs/API_DOCUMENTATION.md for full API documentation
class ApiEndpoints {
  ApiEndpoints._();

  // Health
  static const String health = '/health';

  // Auth (Anonymous-First + Email/Password + 2FA)
  static const String authAnonymous = '/auth/anonymous';
  static const String authDeviceLogin = '/auth/device-login';
  static const String authStatus = '/auth/status';
  static const String authLinkAccount = '/auth/link-account';
  static const String authVerifyLinkAccount = '/auth/verify-link-account';
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authVerify2FA = '/auth/verify-2fa';
  static const String authResend2FA = '/auth/resend-2fa';
  static const String authEnable2FA = '/auth/enable-2fa';
  static const String authDisable2FA = '/auth/disable-2fa';
  static const String authChangePassword = '/auth/change-password';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String me = '/me';
  static const String meProfile = '/me/profile';
  static const String meOnboarding = '/me/onboarding';
  static const String meStats = '/me/stats';
  static const String meAchievements = '/me/achievements';
  static const String meCalendar = '/me/calendar';

  // Account Deletion (Soft Delete)
  static const String meRequestDeletion = '/me/request-deletion';
  static const String meCancelDeletion = '/me/cancel-deletion';

  // Notification Settings
  static const String meNotifications = '/me/notifications';

  // Avatar Upload
  static const String meAvatar = '/me/avatar';

  // Level Progress (New mastery system)
  static const String meProgressLevel = '/me/progress/level';
  static const String meProgressUnlockNext = '/me/progress/unlock-next';
  static const String meProgressNeedsMastery = '/me/progress/needs-mastery';

  // Learned Vocabs (for games)
  static const String meLearnedVocabs = '/me/learned-vocabs';

  // Vocabs
  static const String vocabs = '/vocabs';
  static const String vocabsSearch = '/vocabs/search';
  static String vocabById(String id) => '/vocabs/$id';
  static const String vocabMetaTopics = '/vocabs/meta/topics';
  static const String vocabMetaTypes = '/vocabs/meta/types';

  // Learning
  static const String today = '/today';
  static const String reviewAnswer = '/review/answer';
  static const String sessionFinish = '/session/finish';

  // Dashboard (aggregated endpoint)
  static const String dashboard = '/dashboard';

  // Today extensions
  static const String todayForecast = '/today/forecast';
  static const String todayLearnedToday = '/today/learned-today';

  // Daily Pick
  static const String dailyPick = '/vocabs/daily-pick';

  // Study Modes
  static const String studyModes = '/study-modes';
  static String studyModeWords(String modeId) => '/study-modes/$modeId/words';

  // Favorites
  static const String favorites = '/favorites';
  static String favoriteById(String vocabId) => '/favorites/$vocabId';

  // Decks
  static const String decks = '/decks';
  static String deckById(String id) => '/decks/$id';
  static String deckAddVocab(String deckId, String vocabId) =>
      '/decks/$deckId/add/$vocabId';
  static String deckRemoveVocab(String deckId, String vocabId) =>
      '/decks/$deckId/remove/$vocabId';

  // Collections
  static const String collections = '/collections';
  static String collectionById(String id) => '/collections/$id';

  // Game & Leaderboard
  static const String gameSubmit = '/game/submit';
  static const String gameMyStats = '/game/my-stats';
  static String gameLeaderboard(String gameType) =>
      '/game/leaderboard/$gameType';

  // Pronunciation
  static const String pronunciationWords = '/pronunciation/words';
  static const String pronunciationEvaluate = '/pronunciation/evaluate';
  static const String pronunciationSession = '/pronunciation/session';
  static const String pronunciationHistory = '/pronunciation/history';

  // Offline Manager
  static const String offlineBundles = '/offline/bundles';
  static String offlineBundle(String level) => '/offline/bundle/$level';
  static const String offlineTopics = '/offline/topics';
  static const String offlineDownloads = '/offline/downloads';

  // Donations (replaced Premium)
  static const String donationOptions = '/donations/options';
  static const String donationWallOfFame = '/donations/wall-of-fame';
  static const String donationCreate = '/donations/create';
  static const String donationHistory = '/donations/history';
  static String donationVerify(String id) => '/donations/$id/verify';

  // Level Progress
  static const String levelProgress = '/me/level-progress';
  static const String advanceLevel = '/me/advance-level';

  // HSK Exam
  static const String hskExamOverview = '/hsk-exam/overview';
  static const String hskExamTests = '/hsk-exam/tests';
  static const String hskExamHistory = '/hsk-exam/history';
  static String hskExamTestById(String testId) => '/hsk-exam/tests/$testId';
  static String hskExamSubmit(String testId) =>
      '/hsk-exam/tests/$testId/submit';
  static String hskExamReview(String testId, String attemptId) =>
      '/hsk-exam/tests/$testId/review/$attemptId';
}

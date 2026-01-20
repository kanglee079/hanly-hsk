/// App route names
abstract class Routes {
  Routes._();

  static const String splash = '/splash';

  // Anonymous-First Flow
  static const String intro = '/intro'; // Intro slides (first launch)
  static const String setup = '/setup'; // Setup profile (name, level, goals)
  static const String linkAccount =
      '/link-account'; // Link email to anonymous account
  static const String login = '/login'; // Login with existing account

  // Legacy auth (kept for compatibility)
  static const String auth = '/auth'; // Redirects to login
  static const String authRegister = '/auth/register';
  static const String authVerify2FA = '/auth/verify-2fa';
  static const String onboarding = '/onboarding'; // Deprecated, use setup

  static const String shell = '/shell';
  static const String wordDetail = '/word-detail';
  static const String session = '/session';
  static const String favorites = '/favorites';
  static const String decks = '/decks';
  static const String deckDetail = '/decks/detail';
  static const String settings = '/settings';

  // Donation (replaced Premium)
  static const String donation = '/donation';
  @Deprecated('Premium removed, use donation instead')
  static const String premium = '/premium';

  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String game30Home = '/game30';
  static const String game30Play = '/game30/play';
  static const String collections = '/collections';
  static const String collectionDetail = '/collection-detail';

  // New routes
  static const String leaderboard = '/leaderboard';
  static const String pronunciation = '/pronunciation';
  static const String stats = '/stats';
  static const String deleteAccount = '/delete-account';
  static const String progress = '/progress';

  // Practice module (new learning system)
  static const String practice = '/practice';

  // SRS Review List
  static const String srsReviewList = '/srs-review-list';

  // Flashcard
  static const String flashcard = '/flashcard';

  // Listening Practice
  static const String listening = '/listening';

  // HSK Exam
  static const String hskExam = '/hsk-exam';
  static const String hskExamTest = '/hsk-exam/test';
  static const String hskExamHistory = '/hsk-exam/history';
  static const String hskExamReview = '/hsk-exam/review';
  static const String hskExamAllTests = '/hsk-exam/all-tests';

  // Sentence Formation Practice
  static const String sentenceFormation = '/sentence-formation';

  // Profile & Settings
  static const String editProfile = '/edit-profile';
  static const String notificationSettings = '/notification-settings';
  static const String soundSettings = '/sound-settings';
  static const String offlineDownload = '/offline-download';

  // Info Screens
  static const String aboutUs = '/about-us';
  static const String contactUs = '/contact-us';
}

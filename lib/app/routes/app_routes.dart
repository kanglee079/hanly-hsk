/// App route names
abstract class Routes {
  Routes._();

  static const String splash = '/splash';
  static const String auth = '/auth';              // Login screen
  static const String authRegister = '/auth/register';
  static const String authVerify2FA = '/auth/verify-2fa';
  static const String onboarding = '/onboarding';
  static const String shell = '/shell';
  static const String wordDetail = '/word-detail';
  static const String session = '/session';
  static const String favorites = '/favorites';
  static const String decks = '/decks';
  static const String deckDetail = '/decks/detail';
  static const String settings = '/settings';
  static const String premium = '/premium';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String game30Home = '/game30';
  static const String game30Play = '/game30/play';
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
}

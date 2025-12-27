import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_routes.dart';

// Modules
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/register_screen.dart';
import '../modules/auth/verify_2fa_screen.dart';
import '../modules/onboarding/onboarding_binding.dart';
import '../modules/onboarding/onboarding_screen.dart';
import '../modules/shell/shell_binding.dart';
import '../modules/shell/shell_screen.dart';
import '../modules/word_detail/word_detail_binding.dart';
import '../modules/word_detail/word_detail_screen.dart';
import '../modules/session/session_binding.dart';
import '../modules/session/session_screen.dart';
import '../modules/favorites/favorites_binding.dart';
import '../modules/favorites/favorites_screen.dart';
import '../modules/decks/decks_binding.dart';
import '../modules/decks/decks_screen.dart';
import '../modules/decks/deck_detail_screen.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/premium/premium_screen.dart';
import '../modules/game30/game30_binding.dart';
import '../modules/game30/game30_screen.dart';
import '../modules/game30/game30_home_binding.dart';
import '../modules/game30/game30_home_screen.dart';
import '../modules/collection_detail/collection_detail_binding.dart';
import '../modules/collection_detail/collection_detail_screen.dart';
import '../modules/leaderboard/leaderboard_binding.dart';
import '../modules/leaderboard/leaderboard_screen.dart';
import '../modules/pronunciation/pronunciation_binding.dart';
import '../modules/pronunciation/pronunciation_screen.dart';
import '../modules/stats/stats_binding.dart';
import '../modules/stats/stats_screen.dart';
import '../modules/delete_account/delete_account_binding.dart';
import '../modules/delete_account/delete_account_screen.dart';
import '../modules/progress/progress_binding.dart';
import '../modules/progress/progress_screen.dart';
import '../modules/practice/practice_binding.dart';
import '../modules/practice/practice_screen.dart';
import '../modules/srs_review/srs_review_list_binding.dart';
import '../modules/srs_review/srs_review_list_screen.dart';
import '../modules/flashcard/flashcard_binding.dart';
import '../modules/flashcard/flashcard_screen.dart';
import '../modules/listening/listening_binding.dart';
import '../modules/listening/listening_screen.dart';

/// App pages configuration
class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    // Splash
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),

    // Auth - Email + Password + 2FA
    GetPage(
      name: Routes.auth,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.authRegister,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.authVerify2FA,
      page: () => const Verify2FAScreen(),
    ),

    // Onboarding
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),

    // Shell (main app with bottom nav)
    GetPage(
      name: Routes.shell,
      page: () => const ShellScreen(),
      binding: ShellBinding(),
    ),

    // Word Detail
    GetPage(
      name: Routes.wordDetail,
      page: () => const WordDetailScreen(),
      binding: WordDetailBinding(),
    ),

    // Session
    GetPage(
      name: Routes.session,
      page: () => const SessionScreen(),
      binding: SessionBinding(),
    ),

    // Favorites
    GetPage(
      name: Routes.favorites,
      page: () => const FavoritesScreen(),
      binding: FavoritesBinding(),
    ),

    // Decks
    GetPage(
      name: Routes.decks,
      page: () => const DecksScreen(),
      binding: DecksBinding(),
    ),
    GetPage(
      name: Routes.deckDetail,
      page: () => const DeckDetailScreen(),
    ),

    // Settings
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
    ),

    // Premium
    GetPage(
      name: Routes.premium,
      page: () => const PremiumScreen(),
    ),

    // 30s Game - Home with leaderboard
    GetPage(
      name: Routes.game30Home,
      page: () => const Game30HomeScreen(),
      binding: Game30HomeBinding(),
    ),
    // 30s Game - Gameplay
    GetPage(
      name: Routes.game30Play,
      page: () => const Game30Screen(),
      binding: Game30Binding(),
    ),

    // Collection Detail
    GetPage(
      name: Routes.collectionDetail,
      page: () => const CollectionDetailScreen(),
      binding: CollectionDetailBinding(),
    ),

    // Leaderboard
    GetPage(
      name: Routes.leaderboard,
      page: () => const LeaderboardScreen(),
      binding: LeaderboardBinding(),
    ),

    // Pronunciation
    GetPage(
      name: Routes.pronunciation,
      page: () => const PronunciationScreen(),
      binding: PronunciationBinding(),
    ),

    // Stats
    GetPage(
      name: Routes.stats,
      page: () => const StatsScreen(),
      binding: StatsBinding(),
    ),

    // Delete Account
    GetPage(
      name: Routes.deleteAccount,
      page: () => const DeleteAccountScreen(),
      binding: DeleteAccountBinding(),
    ),

    // Progress (Streak)
    GetPage(
      name: Routes.progress,
      page: () => const ProgressScreen(),
      binding: ProgressBinding(),
    ),
    
    // Practice (New learning system)
    GetPage(
      name: Routes.practice,
      page: () => const PracticeScreen(),
      binding: PracticeBinding(),
    ),

    // SRS Review List
    GetPage(
      name: Routes.srsReviewList,
      page: () => const SrsReviewListScreen(),
      binding: SrsReviewListBinding(),
    ),

    // Flashcard
    GetPage(
      name: Routes.flashcard,
      page: () => const FlashcardScreen(),
      binding: FlashcardBinding(),
    ),

    // Listening Practice
    GetPage(
      name: Routes.listening,
      page: () => const ListeningScreen(),
      binding: ListeningBinding(),
    ),

    // Stubs
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const _PlaceholderScreen(title: 'Chính sách bảo mật'),
    ),
    GetPage(
      name: Routes.termsOfService,
      page: () => const _PlaceholderScreen(title: 'Điều khoản sử dụng'),
    ),
  ];
}

/// Placeholder screen for stubs
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Nội dung sẽ được cập nhật')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/core/theme/app_theme.dart';
import 'app/core/config/app_config.dart';
import 'app/routes/app_pages.dart';
import 'app/services/storage_service.dart';
import 'app/services/auth_session_service.dart';
import 'app/services/audio_service.dart';
import 'app/services/cache_service.dart';
import 'app/services/connectivity_service.dart';
import 'app/data/network/api_client.dart';
import 'app/data/repositories/auth_repo.dart';
import 'app/data/repositories/me_repo.dart';
import 'app/data/repositories/vocab_repo.dart';
import 'app/data/repositories/learning_repo.dart';
import 'app/data/repositories/favorites_repo.dart';
import 'app/data/repositories/decks_repo.dart';
import 'app/data/repositories/collections_repo.dart';
import 'app/data/repositories/game_repo.dart';
import 'app/data/repositories/pronunciation_repo.dart';
import 'app/data/repositories/dashboard_repo.dart';
import 'app/data/repositories/progress_repo.dart';
import 'app/data/repositories/premium_repo.dart';
import 'app/data/repositories/hsk_exam_repo.dart';
import 'app/services/deep_link_service.dart';
import 'app/services/realtime/realtime_sync_service.dart';
import 'app/services/realtime/today_store.dart';
import 'app/services/realtime/study_modes_store.dart';
import 'app/services/tutorial_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  await StorageService.init();
  
  // Initialize date formatting for Vietnamese locale
  await initializeDateFormatting('vi', null);

  // Register dependencies
  await _initDependencies();

  runApp(const HanLyApp());
}

Future<void> _initDependencies() async {
  // Storage
  Get.put(StorageService());

  // API Client
  final apiClient = ApiClient();
  Get.put(apiClient);

  // Repositories
  Get.put(AuthRepo(apiClient));
  Get.put(MeRepo(apiClient));
  Get.put(VocabRepo(apiClient));
  Get.put(LearningRepo(apiClient));
  Get.put(FavoritesRepo(apiClient));
  Get.put(DecksRepo(apiClient));
  Get.put(CollectionsRepo(apiClient));
  Get.put(GameRepo(apiClient));
  Get.put(PronunciationRepo(apiClient));
  Get.put(DashboardRepo(apiClient));
  Get.put(ProgressRepo(apiClient));
  Get.put(PremiumRepo(apiClient));
  Get.put(HskExamRepo(apiClient));

  // Services
  Get.put(AuthSessionService());
  Get.put(AudioService());
  Get.put(CacheService());

  // Connectivity (safe to init before UI; toasts are guarded)
  await Get.putAsync<ConnectivityService>(() => ConnectivityService().init());

  // Realtime streaming core + stores
  Get.put(RealtimeSyncService());
  Get.put(TodayStore());
  Get.put(StudyModesStore());
  
  // Tutorial service
  Get.put(TutorialService());
  
  // Deep Link Service (must be after AuthSessionService)
  await Get.putAsync<DeepLinkService>(() => DeepLinkService().init());
}

class HanLyApp extends StatelessWidget {
  const HanLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

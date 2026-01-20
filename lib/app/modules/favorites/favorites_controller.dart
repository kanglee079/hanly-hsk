import 'package:get/get.dart';
import '../../data/models/vocab_model.dart';
import '../../data/local/vocab_local_datasource.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../routes/app_routes.dart';

/// Favorites controller - OFFLINE-FIRST
/// Reads from local DB first, syncs to server in background
class FavoritesController extends GetxController {
  final VocabLocalDataSource _vocabLocal = Get.find<VocabLocalDataSource>();
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();

  final RxList<VocabModel> favorites = <VocabModel>[].obs;
  final RxBool isLoading = false.obs;
  
  // Guard against duplicate loads
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
    loadFavorites();
    }
  }

  /// Load favorites - OFFLINE-FIRST
  /// Reads from local DB for instant display, then syncs with server
  Future<void> loadFavorites() async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;

    try {
      // STEP 1: Load from local database (instant)
      final localData = await _vocabLocal.getFavorites();
      favorites.value = localData;
      
      // STEP 2: Sync with server in background (if online)
      _syncWithServer();
    } catch (e) {
      Logger.e('FavoritesController', 'loadFavorites error', e);
      // Fallback to API if local fails
      try {
        final data = await _favoritesRepo.getFavorites();
        favorites.value = data;
      } catch (_) {}
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Background sync with server (non-blocking)
  void _syncWithServer() {
    _favoritesRepo.getFavorites().then((serverData) {
      // TODO: Merge server data with local if needed
      // For now, we trust local as source of truth
      Logger.d('FavoritesController', 'Server has ${serverData.length} favorites');
    }).catchError((e) {
      Logger.w('FavoritesController', 'Server sync failed (offline?)');
    });
  }

  void openVocabDetail(VocabModel vocab) {
    Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab});
  }

  /// Remove from favorites - OFFLINE-FIRST
  Future<void> removeFavorite(VocabModel vocab) async {
    try {
      // Update local immediately for instant UI feedback
      await _vocabLocal.toggleFavorite(vocab.id, false);
      favorites.removeWhere((v) => v.id == vocab.id);
      HMToast.success(ToastMessages.favoritesRemoveSuccess);
      
      // Sync to server in background
      _favoritesRepo.removeFavorite(vocab.id).catchError((e) {
        Logger.w('FavoritesController', 'Server sync failed for remove');
      });
    } catch (e) {
      Logger.e('FavoritesController', 'removeFavorite error', e);
      HMToast.error(ToastMessages.favoritesRemoveError);
    }
  }
}


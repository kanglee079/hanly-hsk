import 'package:get/get.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../routes/app_routes.dart';

/// Favorites controller
class FavoritesController extends GetxController {
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();

  final RxList<VocabModel> favorites = <VocabModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    isLoading.value = true;

    try {
      final data = await _favoritesRepo.getFavorites();
      favorites.value = data;
    } catch (e) {
      Logger.e('FavoritesController', 'loadFavorites error', e);
    } finally {
      isLoading.value = false;
    }
  }

  void openVocabDetail(VocabModel vocab) {
    Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab});
  }

  Future<void> removeFavorite(VocabModel vocab) async {
    try {
      await _favoritesRepo.removeFavorite(vocab.id);
      favorites.removeWhere((v) => v.id == vocab.id);
      HMToast.success(ToastMessages.favoritesRemoveSuccess);
    } catch (e) {
      Logger.e('FavoritesController', 'removeFavorite error', e);
      HMToast.error(ToastMessages.favoritesRemoveError);
    }
  }
}


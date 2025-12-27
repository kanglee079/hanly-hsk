import 'package:get/get.dart';
import 'favorites_controller.dart';

/// Favorites binding
class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesController>(() => FavoritesController());
  }
}


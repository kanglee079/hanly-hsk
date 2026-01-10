import 'package:get/get.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/collections_repo.dart';
import '../../core/utils/logger.dart';
import '../../routes/app_routes.dart';

/// Controller for all collections screen
class CollectionsController extends GetxController {
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();

  final RxList<CollectionModel> collections = <CollectionModel>[].obs;
  final RxList<CollectionModel> filteredCollections = <CollectionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLevel = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCollections();
  }

  Future<void> loadCollections() async {
    isLoading.value = true;
    try {
      final result = await _collectionsRepo.getCollections();
      collections.value = result;
      _applyFilter();
      Logger.d('CollectionsController', 'Loaded ${result.length} collections');
    } catch (e) {
      Logger.e('CollectionsController', 'Error loading collections', e);
    } finally {
      isLoading.value = false;
    }
  }

  void filterByLevel(String level) {
    selectedLevel.value = level;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedLevel.value.isEmpty) {
      filteredCollections.value = collections.toList();
    } else {
      filteredCollections.value = collections
          .where((c) => c.level == selectedLevel.value || 
                       c.badge.toUpperCase().contains(selectedLevel.value.toUpperCase()))
          .toList();
    }
  }

  void openCollection(CollectionModel collection) {
    Get.toNamed(
      Routes.collectionDetail,
      arguments: {
        'id': collection.id,
        'collection': collection,
      },
    );
  }

  Future<void> refresh() async {
    await loadCollections();
  }
}

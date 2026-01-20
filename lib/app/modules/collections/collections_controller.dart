import 'package:get/get.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/collections_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/request_guard.dart';
import '../../routes/app_routes.dart';

/// Controller for all collections screen
/// OPTIMIZED: Uses caching and deduplication
class CollectionsController extends GetxController {
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();

  final RxList<CollectionModel> collections = <CollectionModel>[].obs;
  final RxList<CollectionModel> filteredCollections = <CollectionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLevel = ''.obs;
  
  // Guard against duplicate initialization
  bool _isInitialized = false;
  static const String _cacheKey = 'collections_list';

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
    loadCollections();
    }
  }

  /// Load collections with caching (24h TTL)
  Future<void> loadCollections({bool forceRefresh = false}) async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;
    
    try {
      // Use memoized request (cached for 24 hours)
      final result = await RequestGuard.memoize<List<CollectionModel>>(
        _cacheKey,
        () => _collectionsRepo.getCollections(),
        ttl: const Duration(hours: 24),
        forceRefresh: forceRefresh,
      );
      
      collections.value = result;
      _applyFilter();
      Logger.d('CollectionsController', 'Loaded ${result.length} collections (cached=${!forceRefresh})');
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
    await loadCollections(forceRefresh: true);
  }
}

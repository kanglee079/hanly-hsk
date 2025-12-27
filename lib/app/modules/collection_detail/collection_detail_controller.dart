import 'package:get/get.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/collections_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../routes/app_routes.dart';

/// Collection detail controller
class CollectionDetailController extends GetxController {
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();

  // Collection info
  final Rx<CollectionModel?> collection = Rx<CollectionModel?>(null);
  final RxList<VocabModel> vocabs = <VocabModel>[].obs;
  final Rx<PaginationInfo?> pagination = Rx<PaginationInfo?>(null);

  // States
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;

  // Collection ID passed as argument
  late String collectionId;

  @override
  void onInit() {
    super.onInit();
    
    // Get collection ID from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      collectionId = args['id'] ?? '';
      
      // If collection data is passed, use it
      if (args['collection'] != null) {
        collection.value = args['collection'] as CollectionModel;
      }
    } else if (args is String) {
      collectionId = args;
    } else {
      collectionId = '';
    }

    if (collectionId.isNotEmpty) {
      loadCollectionDetail();
    } else {
      isLoading.value = false;
      errorMessage.value = 'Collection không tồn tại';
    }
  }

  /// Load collection detail with vocabs
  Future<void> loadCollectionDetail({bool refresh = false}) async {
    if (refresh) {
      vocabs.clear();
    }

    isLoading.value = vocabs.isEmpty;
    errorMessage.value = '';

    try {
      final response = await _collectionsRepo.getCollectionDetail(
        collectionId,
        page: 1,
        limit: 20,
      );

      collection.value = response.collection;
      vocabs.value = response.vocabs;
      pagination.value = response.pagination;

      Logger.d('CollectionDetailController', 
        'Loaded ${response.vocabs.length} vocabs for collection $collectionId');
    } catch (e) {
      Logger.e('CollectionDetailController', 'Error loading collection', e);
      errorMessage.value = 'Không thể tải collection';
      HMToast.error('Không thể tải collection');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more vocabs (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value) return;
    if (pagination.value == null || !pagination.value!.hasNext) return;

    isLoadingMore.value = true;

    try {
      final nextPage = pagination.value!.page + 1;
      final response = await _collectionsRepo.getCollectionDetail(
        collectionId,
        page: nextPage,
        limit: 20,
      );

      vocabs.addAll(response.vocabs);
      pagination.value = response.pagination;

      Logger.d('CollectionDetailController', 
        'Loaded more: page $nextPage, total ${vocabs.length} vocabs');
    } catch (e) {
      Logger.e('CollectionDetailController', 'Error loading more', e);
      HMToast.error('Không thể tải thêm');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Open vocab detail
  void openVocabDetail(VocabModel vocab) {
    Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab});
  }

  /// Refresh data
  Future<void> refreshData() async {
    await loadCollectionDetail(refresh: true);
  }
}


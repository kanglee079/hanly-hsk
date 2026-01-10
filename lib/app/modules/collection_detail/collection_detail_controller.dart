import 'package:get/get.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/collections_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../routes/app_routes.dart';

/// Collection detail controller with page-based pagination
class CollectionDetailController extends GetxController {
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();

  // Collection info
  final Rx<CollectionModel?> collection = Rx<CollectionModel?>(null);
  final RxList<VocabModel> vocabs = <VocabModel>[].obs;
  final Rx<PaginationInfo?> pagination = Rx<PaginationInfo?>(null);

  // States
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  
  // Current page
  final RxInt currentPage = 1.obs;
  static const int pageLimit = 20;

  // Collection ID passed as argument
  late String collectionId;

  @override
  void onInit() {
    super.onInit();
    
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      collectionId = args['id'] ?? '';
      
      if (args['collection'] != null) {
        collection.value = args['collection'] as CollectionModel;
      }
    } else if (args is String) {
      collectionId = args;
    } else {
      collectionId = '';
    }

    if (collectionId.isNotEmpty) {
      loadPage(1);
    } else {
      isLoading.value = false;
      errorMessage.value = 'Collection không tồn tại';
    }
  }

  /// Load a specific page
  Future<void> loadPage(int page) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final response = await _collectionsRepo.getCollectionDetail(
        collectionId,
        page: page,
        limit: pageLimit,
      );

      collection.value = response.collection;
      vocabs.value = response.vocabs;
      pagination.value = response.pagination;
      currentPage.value = page;

      Logger.d('CollectionDetailController', 
        'Loaded page $page: ${response.vocabs.length} vocabs');
    } catch (e) {
      Logger.e('CollectionDetailController', 'Error loading page $page', e);
      errorMessage.value = 'Không thể tải dữ liệu';
      HMToast.error('Không thể tải dữ liệu');
    } finally {
      isLoading.value = false;
    }
  }

  /// Go to next page
  void nextPage() {
    if (!canGoNext) return;
    loadPage(currentPage.value + 1);
  }

  /// Go to previous page
  void previousPage() {
    if (!canGoPrevious) return;
    loadPage(currentPage.value - 1);
  }

  /// Go to first page
  void firstPage() {
    if (currentPage.value == 1) return;
    loadPage(1);
  }

  /// Go to last page
  void lastPage() {
    final totalPages = pagination.value?.totalPages ?? 1;
    if (currentPage.value == totalPages) return;
    loadPage(totalPages);
  }

  /// Check if can go next
  bool get canGoNext => pagination.value?.hasNext ?? false;

  /// Check if can go previous  
  bool get canGoPrevious => pagination.value?.hasPrev ?? false;

  /// Get total pages
  int get totalPages => pagination.value?.totalPages ?? 1;

  /// Open vocab detail
  void openVocabDetail(VocabModel vocab) {
    Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab, 'vocabId': vocab.id});
  }

  /// Refresh current page
  Future<void> refreshData() async {
    await loadPage(currentPage.value);
  }
}

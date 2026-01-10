import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/vocab_model.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/vocab_repo.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../data/repositories/collections_repo.dart';
import '../../services/storage_service.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../routes/app_routes.dart';

/// Recent item model
class RecentItem {
  final String id;
  final String hanzi;
  final String pinyin;
  final String meaning;
  final DateTime viewedAt;

  RecentItem({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    required this.viewedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'hanzi': hanzi,
    'pinyin': pinyin,
    'meaning': meaning,
    'viewedAt': viewedAt.toIso8601String(),
  };

  factory RecentItem.fromJson(Map<String, dynamic> json) => RecentItem(
    id: json['id'] ?? '',
    hanzi: json['hanzi'] ?? '',
    pinyin: json['pinyin'] ?? '',
    meaning: json['meaning'] ?? '',
    viewedAt: DateTime.tryParse(json['viewedAt'] ?? '') ?? DateTime.now(),
  );
}

/// Explore controller - uses real BE API
class ExploreController extends GetxController {
  final VocabRepo _vocabRepo = Get.find<VocabRepo>();
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();
  final StorageService _storage = Get.find<StorageService>();

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final RxBool isSearchFocused = false.obs;
  final RxBool isLoadingCollections = false.obs;
  
  final RxList<VocabModel> vocabs = <VocabModel>[].obs;
  final RxList<String> topics = <String>[].obs;
  final RxList<String> wordTypes = <String>[].obs;
  
  // Daily pick
  final Rx<VocabModel?> dailyPick = Rx<VocabModel?>(null);
  
  // Collections
  final RxList<CollectionModel> collections = <CollectionModel>[].obs;
  
  // Recent
  final RxList<RecentItem> recentItems = <RecentItem>[].obs;
  
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool showSearchResults = false.obs;
  
  // Filters
  final RxString selectedLevel = ''.obs;
  final RxString selectedWordType = ''.obs;
  final RxString selectedTopic = ''.obs;
  final RxString sortBy = 'Frequency'.obs;
  final RxString sortOrder = 'asc'.obs;
  final RxInt selectedChipIndex = 0.obs;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageLimit = 20;

  final List<String> chipLabels = ['Cho bạn', 'HSK 1-3', 'HSK 4-6', 'Chủ đề'];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
    loadCollections();
    _loadRecentItems();
    loadVocabs();
    loadMeta();
    loadDailyPick();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  /// Refresh all data - for pull-to-refresh
  @override
  Future<void> refresh() async {
    await Future.wait([
      loadCollections(),
      loadVocabs(refresh: true),
      loadDailyPick(),
    ]);
  }

  /// Open search results view and optionally focus the search field
  void openSearchView({bool focus = false}) {
    showSearchResults.value = true;
    if (focus) {
      isSearchFocused.value = true;
      // Delay to ensure the TextField is mounted
      Future.delayed(const Duration(milliseconds: 100), () {
        searchFocusNode.requestFocus();
      });
    }
  }

  /// Unfocus search field
  void unfocusSearch() {
    searchFocusNode.unfocus();
    isSearchFocused.value = false;
  }

  /// Load collections from API
  Future<void> loadCollections() async {
    isLoadingCollections.value = true;
    try {
      final result = await _collectionsRepo.getCollections();
      collections.value = result;
      Logger.d('ExploreController', 'Loaded ${result.length} collections');
    } catch (e) {
      Logger.e('ExploreController', 'Error loading collections', e);
      // Keep empty list on error
    } finally {
      isLoadingCollections.value = false;
    }
  }

  /// Open all collections screen
  void openAllCollections() {
    Get.toNamed(Routes.collections);
  }

  /// Open collection detail
  void openCollection(CollectionModel collection) {
    Get.toNamed(
      Routes.collectionDetail,
      arguments: {
        'id': collection.id,
        'collection': collection,
      },
    );
  }

  /// Load daily pick vocab
  Future<void> loadDailyPick() async {
    try {
      // Check if we have a cached daily pick for today
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final cached = _storage.getDailyPick();
      if (cached != null && cached['date'] == today && cached['vocab'] != null) {
        dailyPick.value = VocabModel.fromJson(cached['vocab'] as Map<String, dynamic>);
        return;
      }

      // Load a random vocab
      final result = await _vocabRepo.getVocabs(
        page: 1,
        limit: 1,
        sort: 'frequency_rank',
        order: 'asc',
      );
      if (result.items.isNotEmpty) {
        dailyPick.value = result.items.first;
        // Cache for today
        _storage.saveDailyPick({
          'date': today,
          'vocab': result.items.first.toJson(),
        });
      }
    } catch (e) {
      Logger.e('ExploreController', 'Error loading daily pick', e);
    }
  }

  void _loadRecentItems() {
    try {
      final data = _storage.getRecentVocabs();
      if (data != null) {
        recentItems.value = data
            .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
            .take(5)
            .toList();
      }
    } catch (e) {
      Logger.e('ExploreController', 'loadRecentItems error', e);
    }
  }

  void _saveRecentItems() {
    try {
      final data = recentItems.take(10).map((e) => e.toJson()).toList();
      _storage.saveRecentVocabs(data);
    } catch (e) {
      Logger.e('ExploreController', 'saveRecentItems error', e);
    }
  }

  void addToRecent(VocabModel vocab) {
    // Remove if already exists
    recentItems.removeWhere((e) => e.id == vocab.id);
    
    // Add to beginning
    recentItems.insert(0, RecentItem(
      id: vocab.id,
      hanzi: vocab.hanzi,
      pinyin: vocab.pinyin,
      meaning: vocab.meaningVi,
      viewedAt: DateTime.now(),
    ));
    
    // Keep only last 10
    if (recentItems.length > 10) {
      recentItems.removeRange(10, recentItems.length);
    }
    
    _saveRecentItems();
  }

  Future<void> loadVocabs({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      isLoading.value = true;
    } else {
      if (!_hasMore || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final result = await _vocabRepo.getVocabs(
        page: _currentPage,
        limit: _pageLimit,
        level: selectedLevel.value.isNotEmpty ? selectedLevel.value : null,
        wordType: selectedWordType.value.isNotEmpty ? selectedWordType.value : null,
        topic: selectedTopic.value.isNotEmpty ? selectedTopic.value : null,
        sort: sortBy.value,
        order: sortOrder.value,
      );
      
      if (refresh) {
        vocabs.value = result.items;
        // Set daily pick from first vocab if available
        if (result.items.isNotEmpty && dailyPick.value == null) {
          dailyPick.value = result.items.first;
        }
      } else {
        vocabs.addAll(result.items);
      }
      
      _hasMore = result.hasNext;
      _currentPage++;
    } catch (e) {
      Logger.e('ExploreController', 'loadVocabs error', e);
      HMToast.error('Không thể tải từ vựng');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    await loadVocabs(refresh: false);
  }

  Future<void> loadMeta() async {
    try {
      final topicsData = await _vocabRepo.getTopics();
      topics.value = topicsData;
      
      final typesData = await _vocabRepo.getWordTypes();
      wordTypes.value = typesData;
    } catch (e) {
      Logger.e('ExploreController', 'loadMeta error', e);
    }
  }

  Future<void> search() async {
    if (searchQuery.value.isEmpty) {
      showSearchResults.value = false;
      return;
    }

    isSearching.value = true;
    showSearchResults.value = true;

    try {
      final results = await _vocabRepo.searchVocabs(searchQuery.value);
      vocabs.value = results;
      _hasMore = false;
    } catch (e) {
      Logger.e('ExploreController', 'search error', e);
      HMToast.error('Không thể tìm kiếm');
    } finally {
      isSearching.value = false;
    }
  }

  void setChipFilter(int index) {
    selectedChipIndex.value = index;
    
    switch (index) {
      case 0: // Cho bạn - show all
        selectedLevel.value = '';
        showSearchResults.value = false;
        break;
      case 1: // HSK 1-3
        selectedLevel.value = 'HSK1,HSK2,HSK3';
        showSearchResults.value = true;
        loadVocabs();
        break;
      case 2: // HSK 4-6
        selectedLevel.value = 'HSK4,HSK5,HSK6';
        showSearchResults.value = true;
        loadVocabs();
        break;
      case 3: // Chủ đề - show topics
        showSearchResults.value = false;
        break;
    }
  }

  void applyFilters({
    String? wordType,
    String? topic,
    String? sort,
    String? order,
  }) {
    if (wordType != null) selectedWordType.value = wordType;
    if (topic != null) selectedTopic.value = topic;
    if (sort != null) sortBy.value = sort;
    if (order != null) sortOrder.value = order;
    showSearchResults.value = true;
    loadVocabs();
  }

  void clearFilters() {
    selectedLevel.value = '';
    selectedWordType.value = '';
    selectedTopic.value = '';
    sortBy.value = 'Frequency';
    sortOrder.value = 'asc';
    searchController.clear();
    searchQuery.value = '';
    selectedChipIndex.value = 0;
    showSearchResults.value = false;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    showSearchResults.value = false;
    isSearchFocused.value = false;
    searchFocusNode.unfocus();
  }

  void sortVocabs() {
    String apiSort;
    switch (sortBy.value) {
      case 'Frequency':
        apiSort = 'frequency_rank';
        break;
      case 'Difficulty':
        apiSort = 'difficulty_score';
        break;
      case 'Level':
        apiSort = 'order_in_level';
        break;
      default:
        apiSort = 'frequency_rank';
    }
    applyFilters(sort: apiSort);
  }

  void openVocabDetail(VocabModel vocab) {
    addToRecent(vocab);
    Get.toNamed(Routes.wordDetail, arguments: {'vocabId': vocab.id, 'vocab': vocab});
  }

  void openRecentItem(RecentItem item) {
    Get.toNamed(Routes.wordDetail, arguments: {'vocabId': item.id});
  }

  Future<void> saveDailyPick() async {
    final vocab = dailyPick.value;
    if (vocab == null) return;

    try {
      await _favoritesRepo.addFavorite(vocab.id);
      HMToast.success('Đã lưu vào yêu thích!');
    } catch (e) {
      Logger.e('ExploreController', 'saveDailyPick error', e);
      HMToast.error('Không thể lưu');
    }
  }

  Future<void> toggleFavorite(VocabModel vocab) async {
    try {
      if (vocab.isFavorite) {
        await _favoritesRepo.removeFavorite(vocab.id);
        HMToast.success(ToastMessages.favoritesRemoveSuccess);
      } else {
        await _favoritesRepo.addFavorite(vocab.id);
        HMToast.success(ToastMessages.favoritesAddSuccess);
      }
      
      final index = vocabs.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        vocabs[index] = vocab.copyWith(isFavorite: !vocab.isFavorite);
      }
    } catch (e) {
      Logger.e('ExploreController', 'toggleFavorite error', e);
      HMToast.error(ToastMessages.favoritesUpdateError);
    }
  }
}

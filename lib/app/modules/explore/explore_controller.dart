import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/vocab_model.dart';
import '../../data/models/collection_model.dart';
import '../../data/local/vocab_local_datasource.dart';
import '../../data/repositories/favorites_repo.dart';
import '../../data/repositories/collections_repo.dart';
import '../../data/repositories/vocab_repo.dart';
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

/// Browse mode enum
enum BrowseMode {
  home, // Main explore view
  search, // Search results
  level, // Browse by HSK level
  topic, // Browse by topic
}

/// Explore controller - uses LOCAL DATABASE (offline-first)
class ExploreController extends GetxController {
  // HYBRID: Local database + API fallback
  final VocabLocalDataSource _vocabLocal = Get.find<VocabLocalDataSource>();
  final FavoritesRepo _favoritesRepo = Get.find<FavoritesRepo>();
  final CollectionsRepo _collectionsRepo = Get.find<CollectionsRepo>();
  final StorageService _storage = Get.find<StorageService>();
  VocabRepo? _vocabRepo; // Optional - for API fallback

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final RxBool isSearchFocused = false.obs;
  final RxBool isLoadingCollections = false.obs;

  final RxList<VocabModel> vocabs = <VocabModel>[].obs;
  final RxList<VocabModel> browseVocabs = <VocabModel>[].obs;
  final RxList<String> topics = <String>[].obs;
  final RxList<String> wordTypes = <String>[].obs;

  // Daily pick
  final Rx<VocabModel?> dailyPick = Rx<VocabModel?>(null);
  final RxBool isLoadingDailyPick = false.obs;

  // Collections
  final RxList<CollectionModel> collections = <CollectionModel>[].obs;

  // Recent
  final RxList<RecentItem> recentItems = <RecentItem>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;

  // Browse mode state
  final Rx<BrowseMode> browseMode = BrowseMode.home.obs;
  final RxString browseTitle = ''.obs;

  // Filters
  final RxString selectedLevel = ''.obs;
  final RxString selectedWordType = ''.obs;
  final RxString selectedTopic = ''.obs;
  final RxString sortBy = 'frequency_rank'.obs;
  final RxString sortOrder = 'asc'.obs;
  final RxInt selectedChipIndex = 0.obs;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageLimit = 20;

  // Debounce timer for real-time search
  Timer? _searchDebounce;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 400);

  // Filter chip labels - simplified for clarity
  final List<String> chipLabels = [
    'Khám phá',
    'HSK 1-2',
    'HSK 3-4',
    'HSK 5-6',
    'Chủ đề',
  ];

  @override
  void onInit() {
    super.onInit();
    // Try to get VocabRepo for API fallback (may not be registered)
    try {
      _vocabRepo = Get.find<VocabRepo>();
    } catch (_) {
      _vocabRepo = null;
    }
    searchController.addListener(_onSearchQueryChanged);
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([loadCollections(), loadMeta(), loadDailyPick()]);
    _loadRecentItems();
  }

  /// Called when search text changes - debounced real-time search
  void _onSearchQueryChanged() {
    final query = searchController.text.trim();
    searchQuery.value = query;

    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    if (query.isEmpty) {
      // Reset to home mode if was in search
      if (browseMode.value == BrowseMode.search) {
        browseMode.value = BrowseMode.home;
        selectedChipIndex.value = 0;
      }
      return;
    }

    // Switch to search mode
    browseMode.value = BrowseMode.search;
    isSearching.value = true;

    // Debounce the actual API call
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (query.isNotEmpty) {
        _performSearch();
      }
    });
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  /// Refresh all data - for pull-to-refresh
  @override
  Future<void> refresh() async {
    await Future.wait([loadCollections(), loadDailyPick()]);
    if (browseMode.value != BrowseMode.home) {
      await loadBrowseVocabs(refresh: true);
    }
  }

  /// Open search mode and optionally focus the search field
  void openSearchView({bool focus = false}) {
    browseMode.value = BrowseMode.search;
    if (focus) {
      isSearchFocused.value = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        searchFocusNode.requestFocus();
      });
    }
  }

  /// Go back to home mode
  void goHome() {
    browseMode.value = BrowseMode.home;
    selectedChipIndex.value = 0;
    searchController.clear();
    searchQuery.value = '';
    selectedLevel.value = '';
    selectedTopic.value = '';
    browseTitle.value = '';
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
      arguments: {'id': collection.id, 'collection': collection},
    );
  }

  /// Load daily pick vocab - HYBRID (local first, API fallback)
  Future<void> loadDailyPick() async {
    isLoadingDailyPick.value = true;
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final cached = _storage.getDailyPick();

      // Check if we have a valid cache for today
      if (cached != null &&
          cached['date'] == today &&
          cached['vocab'] != null) {
        dailyPick.value = VocabModel.fromJson(
          cached['vocab'] as Map<String, dynamic>,
        );
        isLoadingDailyPick.value = false;
        return;
      }

      // Try 1: Local database (instant)
      VocabModel? vocab = await _vocabLocal.getDailyPick(today);

      // Try 2: API fallback if local is empty
      if (vocab == null && _vocabRepo != null) {
        Logger.d('ExploreController', 'Local daily pick empty, trying API');
        try {
          final result = await _vocabRepo!.getVocabs(
            page: 1,
            limit: 1,
            sort: 'random',
          );
          if (result.items.isNotEmpty) {
            vocab = result.items.first;
          }
        } catch (apiError) {
          Logger.w('ExploreController', 'API fallback failed: $apiError');
        }
      }

      if (vocab != null) {
        dailyPick.value = vocab;
        _storage.saveDailyPick({'date': today, 'vocab': vocab.toJson()});
      }
    } catch (e) {
      Logger.e('ExploreController', 'Error loading daily pick', e);
    } finally {
      isLoadingDailyPick.value = false;
    }
  }

  void _loadRecentItems() {
    try {
      final data = _storage.getRecentVocabs();
      if (data != null) {
        recentItems.value = data
            .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
            .take(10)
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
    recentItems.removeWhere((e) => e.id == vocab.id);
    recentItems.insert(
      0,
      RecentItem(
        id: vocab.id,
        hanzi: vocab.hanzi,
        pinyin: vocab.pinyin,
        meaning: vocab.meaningVi,
        viewedAt: DateTime.now(),
      ),
    );

    if (recentItems.length > 10) {
      recentItems.removeRange(10, recentItems.length);
    }
    _saveRecentItems();
  }

  /// Load vocabs for browsing (level or topic) - OFFLINE-FIRST
  Future<void> loadBrowseVocabs({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      isLoading.value = true;
    } else {
      if (!_hasMore || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      // OFFLINE-FIRST: Query local database instead of API
      final result = await _vocabLocal.getVocabs(
        page: _currentPage,
        limit: _pageLimit,
        level: selectedLevel.value.isNotEmpty ? selectedLevel.value : null,
        wordType: selectedWordType.value.isNotEmpty
            ? selectedWordType.value
            : null,
        topic: selectedTopic.value.isNotEmpty ? selectedTopic.value : null,
        sort: sortBy.value,
        order: sortOrder.value,
      );

      if (refresh) {
        browseVocabs.value = result.items;
      } else {
        browseVocabs.addAll(result.items);
      }

      _hasMore = result.hasNext;
      _currentPage++;
    } catch (e) {
      Logger.e('ExploreController', 'loadBrowseVocabs error', e);
      HMToast.error('Không thể tải từ vựng');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (browseMode.value == BrowseMode.search) {
      // Search doesn't support pagination in current API
      return;
    }
    await loadBrowseVocabs(refresh: false);
  }

  /// Load metadata (topics, word types) - OFFLINE-FIRST
  Future<void> loadMeta() async {
    try {
      // OFFLINE-FIRST: Query local database
      final topicsData = await _vocabLocal.getTopics();
      topics.value = topicsData;

      final typesData = await _vocabLocal.getWordTypes();
      wordTypes.value = typesData;
    } catch (e) {
      Logger.e('ExploreController', 'loadMeta error', e);
    }
  }

  /// Perform search - HYBRID (local first, API fallback)
  Future<void> _performSearch() async {
    if (searchQuery.value.isEmpty) {
      goHome();
      return;
    }

    isSearching.value = true;

    try {
      // Try 1: Local database (instant, no network)
      List<VocabModel> results = await _vocabLocal.searchVocabs(
        searchQuery.value,
        limit: 50,
      );

      // Try 2: API fallback if local is empty
      if (results.isEmpty && _vocabRepo != null) {
        Logger.d('ExploreController', 'Local search empty, trying API');
        try {
          results = await _vocabRepo!.searchVocabs(
            searchQuery.value,
            limit: 50,
          );
        } catch (apiError) {
          Logger.w(
            'ExploreController',
            'API search fallback failed: $apiError',
          );
        }
      }

      vocabs.value = results;
    } catch (e) {
      Logger.e('ExploreController', 'search error', e);
      HMToast.error('Không thể tìm kiếm');
    } finally {
      isSearching.value = false;
    }
  }

  /// Handle chip filter selection
  void setChipFilter(int index) {
    selectedChipIndex.value = index;

    switch (index) {
      case 0: // Khám phá - go home
        goHome();
        break;
      case 1: // HSK 1-2
        browseMode.value = BrowseMode.level;
        browseTitle.value = 'HSK 1-2';
        selectedLevel.value = 'HSK1,HSK2';
        selectedTopic.value = '';
        loadBrowseVocabs();
        break;
      case 2: // HSK 3-4
        browseMode.value = BrowseMode.level;
        browseTitle.value = 'HSK 3-4';
        selectedLevel.value = 'HSK3,HSK4';
        selectedTopic.value = '';
        loadBrowseVocabs();
        break;
      case 3: // HSK 5-6
        browseMode.value = BrowseMode.level;
        browseTitle.value = 'HSK 5-6';
        selectedLevel.value = 'HSK5,HSK6';
        selectedTopic.value = '';
        loadBrowseVocabs();
        break;
      case 4: // Chủ đề - show topic selection
        browseMode.value = BrowseMode.topic;
        browseTitle.value = 'Chọn chủ đề';
        break;
    }
  }

  /// Select a topic to browse
  void selectTopic(String topic) {
    selectedTopic.value = topic;
    browseTitle.value = topic;
    loadBrowseVocabs();
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
    loadBrowseVocabs();
  }

  void clearFilters() {
    selectedWordType.value = '';
    sortBy.value = 'frequency_rank';
    sortOrder.value = 'asc';
  }

  void sortVocabs(String sort) {
    sortBy.value = sort;
    if (browseMode.value != BrowseMode.home &&
        browseMode.value != BrowseMode.search) {
      loadBrowseVocabs();
    }
  }

  void openVocabDetail(VocabModel vocab) {
    addToRecent(vocab);
    Get.toNamed(
      Routes.wordDetail,
      arguments: {'vocabId': vocab.id, 'vocab': vocab},
    );
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

      // Update in vocabs list
      final index = vocabs.indexWhere((v) => v.id == vocab.id);
      if (index != -1) {
        vocabs[index] = vocab.copyWith(isFavorite: !vocab.isFavorite);
      }

      // Update in browseVocabs list
      final browseIndex = browseVocabs.indexWhere((v) => v.id == vocab.id);
      if (browseIndex != -1) {
        browseVocabs[browseIndex] = vocab.copyWith(
          isFavorite: !vocab.isFavorite,
        );
      }
    } catch (e) {
      Logger.e('ExploreController', 'toggleFavorite error', e);
      HMToast.error(ToastMessages.favoritesUpdateError);
    }
  }

  /// Get current list based on browse mode
  List<VocabModel> get currentVocabs {
    if (browseMode.value == BrowseMode.search) {
      return vocabs;
    }
    return browseVocabs;
  }

  /// Check if showing home view
  bool get isHomeMode => browseMode.value == BrowseMode.home;

  /// Check if in any browse/search mode
  bool get isBrowsing => browseMode.value != BrowseMode.home;

  /// Check if showing topic selection
  bool get isTopicSelection =>
      browseMode.value == BrowseMode.topic && selectedTopic.value.isEmpty;
}

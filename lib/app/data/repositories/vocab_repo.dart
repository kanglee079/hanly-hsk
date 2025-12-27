import '../models/vocab_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Pagination response wrapper
class PaginatedVocabs {
  final List<VocabModel> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginatedVocabs({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedVocabs.fromJson(Map<String, dynamic> json, List<VocabModel> items) {
    final pagination = json['pagination'] ?? {};
    return PaginatedVocabs(
      items: items,
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? items.length,
      totalPages: pagination['totalPages'] as int? ?? 1,
      hasNext: pagination['hasNext'] as bool? ?? false,
      hasPrev: pagination['hasPrev'] as bool? ?? false,
    );
  }
}

/// Vocab repository - matches BE API exactly
class VocabRepo {
  final ApiClient _api;

  VocabRepo(this._api);

  /// Get vocabs with filters and pagination
  /// BE endpoint: GET /vocabs
  Future<PaginatedVocabs> getVocabs({
    int page = 1,
    int limit = 20,
    String? level, // HSK1, HSK2, etc.
    String? topic,
    String? wordType, // word_type in BE
    int? diffMin,
    int? diffMax,
    String sort = 'order_in_level',
    String order = 'asc',
  }) async {
    final response = await _api.get(
      ApiEndpoints.vocabs,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (level != null) 'level': level,
        if (topic != null) 'topic': topic,
        if (wordType != null) 'word_type': wordType,
        if (diffMin != null) 'diffMin': diffMin,
        if (diffMax != null) 'diffMax': diffMax,
        'sort': sort,
        'order': order,
      },
    );

    final responseData = response.data;
    final List<dynamic> data = responseData['data'] ?? [];
    final items = data.map((e) => VocabModel.fromJson(e as Map<String, dynamic>)).toList();
    
    return PaginatedVocabs.fromJson(responseData, items);
  }

  /// Search vocabs
  /// BE endpoint: GET /vocabs/search?q={query}&limit={n}
  Future<List<VocabModel>> searchVocabs(String query, {int limit = 20}) async {
    final response = await _api.get(
      ApiEndpoints.vocabsSearch,
      queryParameters: {
        'q': query,
        'limit': limit,
      },
    );
    
    final responseData = response.data;
    final List<dynamic> data = responseData['data'] ?? [];
    return data.map((e) => VocabModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get vocab by id
  /// BE endpoint: GET /vocabs/:id
  Future<VocabModel> getVocabById(String id) async {
    final response = await _api.get(ApiEndpoints.vocabById(id));
    final responseData = response.data;
    final data = responseData['data'] ?? responseData;
    return VocabModel.fromJson(data as Map<String, dynamic>);
  }

  /// Get available topics
  /// BE endpoint: GET /vocabs/meta/topics
  Future<List<String>> getTopics() async {
    final response = await _api.get(ApiEndpoints.vocabMetaTopics);
    final responseData = response.data;
    final List<dynamic> data = responseData['data'] ?? [];
    return data.cast<String>();
  }

  /// Get available word types
  /// BE endpoint: GET /vocabs/meta/types
  Future<List<String>> getWordTypes() async {
    final response = await _api.get(ApiEndpoints.vocabMetaTypes);
    final responseData = response.data;
    final List<dynamic> data = responseData['data'] ?? [];
    return data.cast<String>();
  }
}

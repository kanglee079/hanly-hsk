import '../models/collection_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../core/utils/logger.dart';

/// Collections repository - matches BE API exactly
class CollectionsRepo {
  final ApiClient _api;

  CollectionsRepo(this._api);

  /// Get all collections
  /// BE endpoint: GET /collections
  Future<List<CollectionModel>> getCollections() async {
    try {
      final response = await _api.get(ApiEndpoints.collections);
      
      if (response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data
            .map((e) => CollectionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      return [];
    } catch (e) {
      Logger.e('CollectionsRepo', 'Error fetching collections', e);
      rethrow;
    }
  }

  /// Get collection detail with vocabs
  /// BE endpoint: GET /collections/:id?page=&limit=
  Future<CollectionDetailResponse> getCollectionDetail(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '${ApiEndpoints.collections}/$id',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      return CollectionDetailResponse.fromJson(response.data);
    } catch (e) {
      Logger.e('CollectionsRepo', 'Error fetching collection detail', e);
      rethrow;
    }
  }
}


import '../models/vocab_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Favorites repository
class FavoritesRepo {
  final ApiClient _api;

  FavoritesRepo(this._api);

  /// Get favorites
  Future<List<VocabModel>> getFavorites() async {
    final response = await _api.get(ApiEndpoints.favorites);
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((e) => VocabModel.fromJson(e)).toList();
  }

  /// Add to favorites
  Future<void> addFavorite(String vocabId) async {
    await _api.post(ApiEndpoints.favoriteById(vocabId));
  }

  /// Remove from favorites
  Future<void> removeFavorite(String vocabId) async {
    await _api.delete(ApiEndpoints.favoriteById(vocabId));
  }
}


import '../models/deck_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Decks repository - matches BE API exactly
class DecksRepo {
  final ApiClient _api;

  DecksRepo(this._api);

  /// Get all decks
  /// BE endpoint: GET /decks
  Future<List<DeckModel>> getDecks() async {
    final response = await _api.get(ApiEndpoints.decks);
    final responseData = response.data;
    final List<dynamic> data = responseData['data'] ?? [];
    return data.map((e) => DeckModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get deck by id (with vocab details)
  /// BE endpoint: GET /decks/:id
  Future<DeckModel> getDeckById(String id) async {
    final response = await _api.get(ApiEndpoints.deckById(id));
    return DeckModel.fromJson(response.data);
  }

  /// Create deck
  /// BE endpoint: POST /decks
  /// Body: { name }
  Future<DeckModel> createDeck({required String name}) async {
    final response = await _api.post(
      ApiEndpoints.decks,
      data: {'name': name},
    );
    return DeckModel.fromJson(response.data);
  }

  /// Update deck name
  /// BE endpoint: PUT /decks/:id
  /// Body: { name }
  Future<DeckModel> updateDeck({
    required String id,
    required String name,
  }) async {
    final response = await _api.put(
      ApiEndpoints.deckById(id),
      data: {'name': name},
    );
    return DeckModel.fromJson(response.data);
  }

  /// Delete deck
  /// BE endpoint: DELETE /decks/:id
  Future<void> deleteDeck(String id) async {
    await _api.delete(ApiEndpoints.deckById(id));
  }

  /// Add vocab to deck
  /// BE endpoint: POST /decks/:id/add/:vocabId
  Future<DeckModel> addVocabToDeck(String deckId, String vocabId) async {
    final response = await _api.post(ApiEndpoints.deckAddVocab(deckId, vocabId));
    return DeckModel.fromJson(response.data);
  }

  /// Remove vocab from deck
  /// BE endpoint: POST /decks/:id/remove/:vocabId
  Future<DeckModel> removeVocabFromDeck(String deckId, String vocabId) async {
    final response = await _api.post(ApiEndpoints.deckRemoveVocab(deckId, vocabId));
    return DeckModel.fromJson(response.data);
  }
}

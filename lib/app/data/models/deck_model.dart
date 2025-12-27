import 'vocab_model.dart';

/// Custom deck model - matches BE API response
class DeckModel {
  final String id;
  final String name;
  final String? description;
  final int vocabCount;
  final List<String> vocabIds;
  final List<VocabModel> vocabs;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DeckModel({
    required this.id,
    required this.name,
    this.description,
    this.vocabCount = 0,
    this.vocabIds = const [],
    this.vocabs = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response
    final data = json['data'] ?? json;
    
    return DeckModel(
      id: (data['id'] ?? data['_id'] ?? '').toString(),
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      vocabCount: data['vocabCount'] as int? ?? 0,
      vocabIds: (data['vocabIds'] as List<dynamic>?)?.cast<String>() ?? [],
      vocabs: (data['vocabs'] as List<dynamic>?)
              ?.map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'vocabCount': vocabCount,
      'vocabIds': vocabIds,
      'vocabs': vocabs.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DeckModel copyWith({
    String? id,
    String? name,
    String? description,
    int? vocabCount,
    List<String>? vocabIds,
    List<VocabModel>? vocabs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeckModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      vocabCount: vocabCount ?? this.vocabCount,
      vocabIds: vocabIds ?? this.vocabIds,
      vocabs: vocabs ?? this.vocabs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

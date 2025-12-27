/// Vocabulary model - matches BE API response exactly
class VocabModel {
  final String id;
  final String hanzi; // 'word' in BE
  final String pinyin;
  final String meaningVi; // 'meaning_vi' in BE
  final String? meaningEn; // 'meaning_en' in BE
  final String level; // HSK1-6 string in BE
  final String? subLevel; // 'HSK1.1' format in BE
  final String? wordType; // 'word_type' in BE
  final List<String> topics;
  final List<String> images;
  final String? audioUrl; // 'audio_url' in BE
  final String? audioSlowUrl; // 'audio_slow_url' in BE
  final HanziDnaModel? hanziDna;
  final List<String> collocations; // Array of strings in BE
  final List<ExampleModel> examples;
  final String? mnemonic;
  final List<String> synonyms;
  final List<String> antonyms;
  final String? usageNotes; // 'usage_notes' in BE
  final String? grammarNotes; // 'grammar_notes' in BE
  final String? culturalNotes; // 'cultural_notes' in BE
  final String? hskTips; // 'hsk_tips' in BE
  final int frequencyRank; // 'frequency_rank' in BE
  final int difficultyScore; // 'difficulty_score' in BE
  final bool isCommon; // 'is_common' in BE
  final bool hskOfficial; // 'hsk_official' in BE
  final int orderInLevel; // 'order_in_level' in BE
  final bool isFavorite;
  
  // For review queue items - SRS progress data
  final DateTime? dueDate;
  final String? state; // new, learning, review, mastered
  final int? reps; // Number of reviews
  final int? intervalDays; // Current interval in days
  final String? lastResult; // again, hard, good, easy

  VocabModel({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.meaningVi,
    this.meaningEn,
    required this.level,
    this.subLevel,
    this.wordType,
    this.topics = const [],
    this.images = const [],
    this.audioUrl,
    this.audioSlowUrl,
    this.hanziDna,
    this.collocations = const [],
    this.examples = const [],
    this.mnemonic,
    this.synonyms = const [],
    this.antonyms = const [],
    this.usageNotes,
    this.grammarNotes,
    this.culturalNotes,
    this.hskTips,
    this.frequencyRank = 0,
    this.difficultyScore = 1,
    this.isCommon = true,
    this.hskOfficial = false,
    this.orderInLevel = 0,
    this.isFavorite = false,
    this.dueDate,
    this.state,
    this.reps,
    this.intervalDays,
    this.lastResult,
  });

  /// Get SRS state display text
  String get stateDisplay {
    switch (state) {
      case 'new':
        return 'Mới';
      case 'learning':
        return 'Đang học';
      case 'review':
        return 'Ôn tập';
      case 'mastered':
        return 'Đã thuộc';
      default:
        return 'Mới';
    }
  }

  /// Get interval display text
  String get intervalDisplay {
    if (intervalDays == null || intervalDays == 0) return 'Hôm nay';
    if (intervalDays == 1) return 'Ngày mai';
    return '$intervalDays ngày';
  }

  /// Parse level string like "HSK1" to int (1-6)
  int get levelInt {
    if (level.startsWith('HSK')) {
      return int.tryParse(level.substring(3)) ?? 1;
    }
    return int.tryParse(level) ?? 1;
  }

  factory VocabModel.fromJson(Map<String, dynamic> json) {
    // Handle wrapped response: { success: true, data: {...} }
    final data = json['data'] ?? json;

    // Parse collocations - can be list of strings or list of objects
    List<String> parseCollocations(dynamic collocs) {
      if (collocs == null) return [];
      if (collocs is List) {
        return collocs.map((e) {
          if (e is String) return e;
          if (e is Map) return e['hanzi']?.toString() ?? e.toString();
          return e.toString();
        }).toList();
      }
      return [];
    }

    // Parse level - can be string "HSK1" or int 1
    String parseLevel(dynamic level) {
      if (level is String) return level;
      if (level is int) return 'HSK$level';
      return 'HSK1';
    }

    // Build HanziDna from flat fields in response
    HanziDnaModel? buildHanziDna(Map<String, dynamic> json) {
      final hasData = json['radical'] != null || 
                      json['stroke_count'] != null || 
                      json['components'] != null;
      if (!hasData) return null;
      
      return HanziDnaModel(
        radical: json['radical'] as String?,
        radicalMeaning: json['radical_meaning'] as String?,
        components: (json['components'] as List<dynamic>?)?.cast<String>() ?? [],
        strokeCount: json['stroke_count'] as int? ?? 0,
        strokeOrder: json['stroke_order'] as String?,
      );
    }

    return VocabModel(
      id: (data['id'] ?? data['_id'] ?? '').toString(),
      hanzi: data['word'] as String? ?? data['hanzi'] as String? ?? '',
      pinyin: data['pinyin'] as String? ?? '',
      meaningVi: data['meaning_vi'] as String? ?? data['meaningVi'] as String? ?? '',
      meaningEn: data['meaning_en'] as String? ?? data['meaningEn'] as String?,
      level: parseLevel(data['level']),
      subLevel: data['subLevel'] as String? ?? data['sub_level'] as String?,
      wordType: data['word_type'] as String? ?? data['wordType'] as String?,
      topics: (data['topics'] as List<dynamic>?)?.cast<String>() ?? [],
      images: (data['images'] as List<dynamic>?)?.cast<String>() ?? [],
      audioUrl: data['audio_url'] as String? ?? data['audioUrl'] as String?,
      audioSlowUrl: data['audio_slow_url'] as String? ?? data['audioSlowUrl'] as String?,
      hanziDna: data['hanziDna'] != null
          ? HanziDnaModel.fromJson(data['hanziDna'] as Map<String, dynamic>)
          : buildHanziDna(data),
      collocations: parseCollocations(data['collocations']),
      examples: (data['examples'] as List<dynamic>?)
              ?.map((e) => ExampleModel.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      mnemonic: data['mnemonic'] as String?,
      synonyms: (data['synonyms'] as List<dynamic>?)?.cast<String>() ?? [],
      antonyms: (data['antonyms'] as List<dynamic>?)?.cast<String>() ?? [],
      usageNotes: data['usage_notes'] as String? ?? data['usageNotes'] as String?,
      grammarNotes: data['grammar_notes'] as String? ?? data['grammarNotes'] as String?,
      culturalNotes: data['cultural_notes'] as String? ?? data['culturalNotes'] as String?,
      hskTips: data['hsk_tips'] as String? ?? data['hskTips'] as String?,
      frequencyRank: data['frequency_rank'] as int? ?? data['frequencyRank'] as int? ?? 0,
      difficultyScore: data['difficulty_score'] as int? ?? data['difficultyScore'] as int? ?? 1,
      isCommon: data['is_common'] as bool? ?? data['isCommon'] as bool? ?? true,
      hskOfficial: data['hsk_official'] as bool? ?? data['hskOfficial'] as bool? ?? false,
      orderInLevel: data['order_in_level'] as int? ?? data['orderInLevel'] as int? ?? 0,
      isFavorite: data['isFavorite'] as bool? ?? data['is_favorite'] as bool? ?? false,
      dueDate: _parseDueDate(data),
      state: _parseState(data),
      reps: _parseReps(data),
      intervalDays: _parseIntervalDays(data),
      lastResult: _parseLastResult(data),
    );
  }

  static DateTime? _parseDueDate(Map<String, dynamic> data) {
    final progress = data['progress'] as Map<String, dynamic>?;
    final dateStr = progress?['dueDate'] ?? data['dueDate'];
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr.toString());
  }

  static String? _parseState(Map<String, dynamic> data) {
    final progress = data['progress'] as Map<String, dynamic>?;
    return progress?['state'] as String? ?? data['state'] as String?;
  }

  static int? _parseReps(Map<String, dynamic> data) {
    final progress = data['progress'] as Map<String, dynamic>?;
    return progress?['reps'] as int? ?? data['reps'] as int?;
  }

  static int? _parseIntervalDays(Map<String, dynamic> data) {
    final progress = data['progress'] as Map<String, dynamic>?;
    return progress?['intervalDays'] as int? ?? data['intervalDays'] as int?;
  }

  static String? _parseLastResult(Map<String, dynamic> data) {
    final progress = data['progress'] as Map<String, dynamic>?;
    return progress?['lastResult'] as String? ?? data['lastResult'] as String?;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': hanzi,
      'pinyin': pinyin,
      'meaning_vi': meaningVi,
      'meaning_en': meaningEn,
      'level': level,
      'subLevel': subLevel,
      'word_type': wordType,
      'topics': topics,
      'images': images,
      'audio_url': audioUrl,
      'audio_slow_url': audioSlowUrl,
      'radical': hanziDna?.radical,
      'stroke_count': hanziDna?.strokeCount,
      'components': hanziDna?.components,
      'mnemonic': mnemonic,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'collocations': collocations,
      'examples': examples.map((e) => e.toJson()).toList(),
      'usage_notes': usageNotes,
      'grammar_notes': grammarNotes,
      'cultural_notes': culturalNotes,
      'hsk_tips': hskTips,
      'frequency_rank': frequencyRank,
      'difficulty_score': difficultyScore,
      'is_common': isCommon,
      'hsk_official': hskOfficial,
      'order_in_level': orderInLevel,
    };
  }

  VocabModel copyWith({
    String? id,
    String? hanzi,
    String? pinyin,
    String? meaningVi,
    String? meaningEn,
    String? level,
    String? subLevel,
    String? wordType,
    List<String>? topics,
    List<String>? images,
    String? audioUrl,
    String? audioSlowUrl,
    HanziDnaModel? hanziDna,
    List<String>? collocations,
    List<ExampleModel>? examples,
    String? mnemonic,
    List<String>? synonyms,
    List<String>? antonyms,
    String? usageNotes,
    String? grammarNotes,
    String? culturalNotes,
    String? hskTips,
    int? frequencyRank,
    int? difficultyScore,
    bool? isCommon,
    bool? hskOfficial,
    int? orderInLevel,
    bool? isFavorite,
    DateTime? dueDate,
    String? state,
  }) {
    return VocabModel(
      id: id ?? this.id,
      hanzi: hanzi ?? this.hanzi,
      pinyin: pinyin ?? this.pinyin,
      meaningVi: meaningVi ?? this.meaningVi,
      meaningEn: meaningEn ?? this.meaningEn,
      level: level ?? this.level,
      subLevel: subLevel ?? this.subLevel,
      wordType: wordType ?? this.wordType,
      topics: topics ?? this.topics,
      images: images ?? this.images,
      audioUrl: audioUrl ?? this.audioUrl,
      audioSlowUrl: audioSlowUrl ?? this.audioSlowUrl,
      hanziDna: hanziDna ?? this.hanziDna,
      collocations: collocations ?? this.collocations,
      examples: examples ?? this.examples,
      mnemonic: mnemonic ?? this.mnemonic,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      usageNotes: usageNotes ?? this.usageNotes,
      grammarNotes: grammarNotes ?? this.grammarNotes,
      culturalNotes: culturalNotes ?? this.culturalNotes,
      hskTips: hskTips ?? this.hskTips,
      frequencyRank: frequencyRank ?? this.frequencyRank,
      difficultyScore: difficultyScore ?? this.difficultyScore,
      isCommon: isCommon ?? this.isCommon,
      hskOfficial: hskOfficial ?? this.hskOfficial,
      orderInLevel: orderInLevel ?? this.orderInLevel,
      isFavorite: isFavorite ?? this.isFavorite,
      dueDate: dueDate ?? this.dueDate,
      state: state ?? this.state,
    );
  }
}

/// Hanzi DNA - radical, components, strokes
class HanziDnaModel {
  final String? radical;
  final String? radicalMeaning;
  final List<String> components;
  final int strokeCount;
  final String? strokeOrder;

  HanziDnaModel({
    this.radical,
    this.radicalMeaning,
    this.components = const [],
    this.strokeCount = 0,
    this.strokeOrder,
  });

  factory HanziDnaModel.fromJson(Map<String, dynamic> json) {
    return HanziDnaModel(
      radical: json['radical'] as String?,
      radicalMeaning: json['radicalMeaning'] as String? ?? json['radical_meaning'] as String?,
      components: (json['components'] as List<dynamic>?)?.cast<String>() ?? [],
      strokeCount: json['strokeCount'] as int? ?? json['stroke_count'] as int? ?? 0,
      strokeOrder: json['strokeOrder'] as String? ?? json['stroke_order'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radical': radical,
      'radical_meaning': radicalMeaning,
      'components': components,
      'stroke_count': strokeCount,
      'stroke_order': strokeOrder,
    };
  }
}

/// Example sentence model - matches BE { cn, vi, _id }
class ExampleModel {
  final String id;
  final String hanzi; // 'cn' in BE
  final String pinyin; // Not in BE, may be empty
  final String meaningVi; // 'vi' in BE
  final String? audioUrl;

  ExampleModel({
    this.id = '',
    required this.hanzi,
    this.pinyin = '',
    required this.meaningVi,
    this.audioUrl,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      hanzi: json['cn'] as String? ?? json['hanzi'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      meaningVi: json['vi'] as String? ?? json['meaningVi'] as String? ?? json['meaning_vi'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cn': hanzi,
      'pinyin': pinyin,
      'vi': meaningVi,
      'audio_url': audioUrl,
    };
  }
}

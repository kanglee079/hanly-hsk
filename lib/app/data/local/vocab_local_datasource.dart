import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';

import '../models/vocab_model.dart'
    show VocabModel, ExampleModel, HanziDnaModel;
import 'database_service.dart';
import '../../core/utils/logger.dart';

/// Pagination result for local vocab queries
class LocalPaginatedVocabs {
  final List<VocabModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasNext;
  final bool hasPrev;

  LocalPaginatedVocabs({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });
}

/// Local data source for vocabulary - reads from SQLite
/// This is the PRIMARY source for vocab data (offline-first)
class VocabLocalDataSource {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Get vocabs with filters and pagination (LOCAL ONLY)
  Future<LocalPaginatedVocabs> getVocabs({
    int page = 1,
    int limit = 20,
    String? level,
    String? topic,
    String? wordType,
    String sort = 'order_in_level',
    String order = 'asc',
    bool onlyUnlocked = false,
  }) async {
    final offset = (page - 1) * limit;

    // Build WHERE clause
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (level != null && level.isNotEmpty) {
      // Handle comma-separated levels like "HSK1,HSK2"
      final levels = level.split(',');
      final placeholders = levels.map((_) => '?').join(',');
      whereClauses.add('v.level IN ($placeholders)');
      whereArgs.addAll(levels);
    }

    if (topic != null && topic.isNotEmpty) {
      whereClauses.add('v.topic = ?');
      whereArgs.add(topic);
    }

    if (wordType != null && wordType.isNotEmpty) {
      whereClauses.add('v.word_type = ?');
      whereArgs.add(wordType);
    }

    if (onlyUnlocked) {
      whereClauses.add('(p.is_locked = 0 OR p.is_locked IS NULL)');
    }

    final whereStr = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    // Validate sort column to prevent SQL injection
    final validSortColumns = [
      'order_in_level',
      'frequency_rank',
      'word',
      'pinyin',
      'difficulty',
    ];
    final sortColumn = validSortColumns.contains(sort)
        ? sort
        : 'order_in_level';
    final sortOrder = order.toUpperCase() == 'DESC' ? 'DESC' : 'ASC';

    // Count total
    final countResult = await _db.db.rawQuery('''
      SELECT COUNT(*) as count FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      $whereStr
    ''', whereArgs);
    final total = Sqflite.firstIntValue(countResult) ?? 0;

    // Get paginated results
    final results = await _db.db.rawQuery(
      '''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             COALESCE(p.is_favorite, 0) as is_favorite,
             COALESCE(p.is_locked, 1) as is_locked
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      $whereStr
      ORDER BY v.$sortColumn $sortOrder
      LIMIT ? OFFSET ?
    ''',
      [...whereArgs, limit, offset],
    );

    final items = results.map((row) => _rowToVocabModel(row)).toList();

    return LocalPaginatedVocabs(
      items: items,
      page: page,
      limit: limit,
      total: total,
      hasNext: offset + items.length < total,
      hasPrev: page > 1,
    );
  }

  /// Search vocabs locally (full-text search on word, pinyin, meaning)
  Future<List<VocabModel>> searchVocabs(String query, {int limit = 50}) async {
    if (query.isEmpty) return [];

    final searchPattern = '%$query%';

    final results = await _db.db.rawQuery(
      '''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             COALESCE(p.is_favorite, 0) as is_favorite,
             COALESCE(p.is_locked, 1) as is_locked
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE v.word LIKE ? 
         OR v.pinyin LIKE ? 
         OR v.meaning_vi LIKE ?
         OR v.meaning_en LIKE ?
      ORDER BY 
        CASE 
          WHEN v.word = ? THEN 1
          WHEN v.word LIKE ? THEN 2
          WHEN v.pinyin = ? THEN 3
          WHEN v.pinyin LIKE ? THEN 4
          ELSE 5
        END,
        v.frequency_rank ASC
      LIMIT ?
    ''',
      [
        searchPattern,
        searchPattern,
        searchPattern,
        searchPattern,
        query,
        '$query%',
        query,
        '$query%',
        limit,
      ],
    );

    return results.map((row) => _rowToVocabModel(row)).toList();
  }

  /// Get vocab by ID
  Future<VocabModel?> getVocabById(String id) async {
    final results = await _db.db.rawQuery(
      '''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             COALESCE(p.is_favorite, 0) as is_favorite,
             COALESCE(p.is_locked, 1) as is_locked
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE v.id = ?
    ''',
      [id],
    );

    if (results.isEmpty) return null;
    return _rowToVocabModel(results.first);
  }

  /// Get all unique topics
  Future<List<String>> getTopics() async {
    final results = await _db.db.rawQuery('''
      SELECT DISTINCT topic FROM vocabs 
      WHERE topic IS NOT NULL AND topic != ''
      ORDER BY topic
    ''');
    return results.map((r) => r['topic'] as String).toList();
  }

  /// Get all unique word types
  Future<List<String>> getWordTypes() async {
    final results = await _db.db.rawQuery('''
      SELECT DISTINCT word_type FROM vocabs 
      WHERE word_type IS NOT NULL AND word_type != ''
      ORDER BY word_type
    ''');
    return results.map((r) => r['word_type'] as String).toList();
  }

  /// Get vocab count by level
  Future<Map<String, int>> getVocabCountByLevel() async {
    final results = await _db.db.rawQuery('''
      SELECT level, COUNT(*) as count FROM vocabs GROUP BY level
    ''');
    return {for (final r in results) r['level'] as String: r['count'] as int};
  }

  /// Get random vocab for daily pick
  Future<VocabModel?> getDailyPick(String dateKey) async {
    // Use date as seed for consistent random per day
    final seed = dateKey.hashCode;

    final results = await _db.db.rawQuery('''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             COALESCE(p.is_favorite, 0) as is_favorite,
             COALESCE(p.is_locked, 1) as is_locked
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE v.frequency_rank IS NOT NULL
      ORDER BY (v.id * $seed) % 1000
      LIMIT 1
    ''');

    if (results.isEmpty) return null;
    return _rowToVocabModel(results.first);
  }

  /// Get new words for learning queue (unlocked, not yet learned)
  Future<List<VocabModel>> getNewQueue({
    required String level,
    int limit = 10,
  }) async {
    final results = await _db.db.rawQuery(
      '''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             COALESCE(p.is_favorite, 0) as is_favorite,
             COALESCE(p.is_locked, 0) as is_locked
      FROM vocabs v
      LEFT JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE v.level = ?
        AND (p.state IS NULL OR p.state = 'new')
        AND (p.is_locked = 0 OR p.is_locked IS NULL)
      ORDER BY v.order_in_level ASC
      LIMIT ?
    ''',
      [level, limit],
    );

    return results.map((row) => _rowToVocabModel(row)).toList();
  }

  /// Get review queue (words due for SRS review)
  Future<List<VocabModel>> getReviewQueue({
    int limit = 50,
    DateTime? beforeDate,
  }) async {
    final now = beforeDate ?? DateTime.now();
    final dateStr = now.toIso8601String().substring(0, 10);

    final results = await _db.db.rawQuery(
      '''
      SELECT v.*, 
             p.state as progress_state,
             p.is_favorite,
             p.is_locked,
             p.due_date,
             p.interval_days
      FROM vocabs v
      INNER JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE p.state IN ('learning', 'review')
        AND p.due_date <= ?
      ORDER BY p.due_date ASC
      LIMIT ?
    ''',
      [dateStr, limit],
    );

    return results.map((row) => _rowToVocabModel(row)).toList();
  }

  /// Update progress for a vocab
  Future<void> updateProgress({
    required String vocabId,
    required String state,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? dueDate,
    DateTime? lastReviewed,
  }) async {
    final now = DateTime.now().toIso8601String();

    await _db.db.insert('vocab_progress', {
      'vocab_id': vocabId,
      'state': state,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (dueDate != null)
        'due_date': dueDate.toIso8601String().substring(0, 10),
      if (lastReviewed != null) 'last_reviewed': lastReviewed.toIso8601String(),
      'updated_at': now,
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String vocabId, bool isFavorite) async {
    await _db.db.insert('vocab_progress', {
      'vocab_id': vocabId,
      'is_favorite': isFavorite ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
      'synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all favorites
  Future<List<VocabModel>> getFavorites() async {
    final results = await _db.db.rawQuery('''
      SELECT v.*, 
             COALESCE(p.state, 'new') as progress_state,
             1 as is_favorite,
             COALESCE(p.is_locked, 1) as is_locked
      FROM vocabs v
      INNER JOIN vocab_progress p ON v.id = p.vocab_id
      WHERE p.is_favorite = 1
      ORDER BY p.updated_at DESC
    ''');

    return results.map((row) => _rowToVocabModel(row)).toList();
  }

  /// Unlock vocabs in a batch (for progressive unlocking)
  Future<void> unlockVocabs(List<String> vocabIds) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.db.batch();

    for (final id in vocabIds) {
      batch.insert('vocab_progress', {
        'vocab_id': id,
        'is_locked': 0,
        'unlocked_at': now,
        'updated_at': now,
        'synced': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    Logger.d('VocabLocalDataSource', 'Unlocked ${vocabIds.length} vocabs');
  }

  /// Get unsynced progress entries (for background sync)
  Future<List<Map<String, dynamic>>> getUnsyncedProgress() async {
    return _db.db.query('vocab_progress', where: 'synced = 0');
  }

  /// Mark progress as synced
  Future<void> markSynced(List<String> vocabIds) async {
    if (vocabIds.isEmpty) return;

    final placeholders = vocabIds.map((_) => '?').join(',');
    await _db.db.rawUpdate('''
      UPDATE vocab_progress SET synced = 1 WHERE vocab_id IN ($placeholders)
    ''', vocabIds);
  }

  /// Get forecast counts for next 7 days (for local forecast)
  /// Returns a map of date string (YYYY-MM-DD) to count
  Future<Map<String, int>> getForecastCounts({int days = 7}) async {
    final now = DateTime.now();
    final result = <String, int>{};

    for (int i = 1; i <= days; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);

      // Count words due on exactly this date
      // (dueDate == dateStr means they become due on that day)
      final countResult = await _db.db.rawQuery(
        '''
        SELECT COUNT(*) as count FROM vocab_progress
        WHERE state IN ('learning', 'review')
          AND due_date = ?
      ''',
        [dateStr],
      );

      result[dateStr] = Sqflite.firstIntValue(countResult) ?? 0;
    }

    return result;
  }

  /// Replace local vocab dataset from a remote payload
  Future<void> replaceDataset({
    required List<Map<String, dynamic>> vocabs,
    required String version,
    required String checksum,
    required String updatedAt,
  }) async {
    if (vocabs.isEmpty) return;

    await _db.db.transaction((txn) async {
      await txn.delete('vocabs');

      const batchSize = 400;
      var batch = txn.batch();
      var count = 0;

      for (final vocab in vocabs) {
        batch.insert(
          'vocabs',
          _mapRemoteVocabToRow(vocab),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
        if (count % batchSize == 0) {
          await batch.commit(noResult: true);
          batch = txn.batch();
        }
      }

      await batch.commit(noResult: true);
    });

    await _db.setSetting('dataset_version', version);
    await _db.setSetting('dataset_checksum', checksum);
    await _db.setSetting('dataset_updated_at', updatedAt);
    await _db.setSetting(
      'dataset_downloaded_at',
      DateTime.now().toIso8601String(),
    );

    Logger.i(
      'VocabLocalDataSource',
      '📦 Dataset replaced: ${vocabs.length} items (v$version)',
    );
  }

  /// Convert database row to VocabModel
  VocabModel _rowToVocabModel(Map<String, dynamic> row) {
    // Parse JSON fields
    List<ExampleModel> examples = [];
    if (row['examples'] != null && row['examples'].toString().isNotEmpty) {
      try {
        final List<dynamic> exData = jsonDecode(row['examples']);
        examples = exData
            .map((e) => ExampleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<String> collocations = [];
    if (row['collocations'] != null &&
        row['collocations'].toString().isNotEmpty) {
      try {
        collocations = List<String>.from(jsonDecode(row['collocations']));
      } catch (_) {}
    }

    // Build HanziDna if we have stroke data
    final strokeCount = row['stroke_count'] as int?;
    final hanziDna = strokeCount != null
        ? HanziDnaModel(strokeCount: strokeCount, components: [])
        : null;

    return VocabModel(
      id: row['id'] as String,
      hanzi: row['word'] as String,
      pinyin: row['pinyin'] as String,
      meaningVi: row['meaning_vi'] as String,
      meaningEn: row['meaning_en'] as String? ?? '',
      level: row['level'] as String,
      orderInLevel: row['order_in_level'] as int? ?? 0,
      topics: row['topic'] != null ? [row['topic'] as String] : [],
      wordType: row['word_type'] as String?,
      frequencyRank: row['frequency_rank'] as int? ?? 0,
      difficultyScore: row['difficulty'] as int? ?? 3,
      audioUrl: row['audio_url'] as String?,
      images: row['image_url'] != null ? [row['image_url'] as String] : [],
      examples: examples
          .map(
            (e) => ExampleModel(
              hanzi: e.hanzi,
              pinyin: e.pinyin,
              meaningVi: e.meaningVi,
              audioUrl: e.audioUrl,
            ),
          )
          .toList(),
      collocations: collocations,
      hanziDna: hanziDna,
      mnemonic: row['mnemonic'] as String?,
      isFavorite: (row['is_favorite'] as int?) == 1,
      isLocked: (row['is_locked'] as int?) == 1,
      progressState: row['progress_state'] as String?,
    );
  }

  Map<String, dynamic> _mapRemoteVocabToRow(Map<String, dynamic> vocab) {
    final topics =
        (vocab['topics'] as List<dynamic>?)?.cast<String>() ?? [];
    final images =
        (vocab['images'] as List<dynamic>?)?.cast<String>() ?? [];
    final examplesRaw = vocab['examples'] as List<dynamic>? ?? [];
    final collocations =
        (vocab['collocations'] as List<dynamic>?)?.cast<String>() ?? [];
    final components =
        (vocab['components'] as List<dynamic>?)?.cast<String>() ?? [];

    final examples = examplesRaw.map((e) {
      final map = e as Map;
      return {
        'hanzi': map['cn']?.toString() ?? '',
        'pinyin': map['pinyin']?.toString(),
        'meaningVi': map['vi']?.toString() ?? '',
        'audioUrl': map['audio_url']?.toString() ?? map['audioUrl']?.toString(),
      };
    }).toList();

    return {
      'id': (vocab['id'] ?? vocab['_id'] ?? '').toString(),
      'word': vocab['word'] as String? ?? '',
      'pinyin': vocab['pinyin'] as String? ?? '',
      'meaning_vi': vocab['meaning_vi'] as String? ?? '',
      'meaning_en': vocab['meaning_en'] as String? ?? '',
      'level': _normalizeLevel(vocab['level']),
      'order_in_level': vocab['order_in_level'] as int? ?? 0,
      'topic': topics.isNotEmpty ? topics.first : null,
      'word_type': vocab['word_type'] as String?,
      'frequency_rank': vocab['frequency_rank'] as int? ?? 0,
      'difficulty': vocab['difficulty_score'] as int? ?? 3,
      'audio_url': vocab['audio_url'] as String?,
      'image_url': images.isNotEmpty ? images.first : null,
      'examples': jsonEncode(examples),
      'collocations': jsonEncode(collocations),
      'radicals': vocab['radical'] as String?,
      'components': jsonEncode(components),
      'stroke_count': vocab['stroke_count'] as int?,
      'mnemonic': vocab['mnemonic'] as String?,
      'created_at': vocab['createdAt']?.toString(),
      'updated_at': vocab['updatedAt']?.toString(),
    };
  }

  String _normalizeLevel(dynamic level) {
    if (level is String) return level;
    if (level is int) return 'HSK$level';
    return 'HSK1';
  }
}

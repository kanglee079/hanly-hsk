// ignore_for_file: avoid_print

/// Script to generate SQLite database from backend API
/// Usage: dart run scripts/generate_vocab_db.dart
///
/// This script:
/// 1. Fetches all vocab from backend API
/// 2. Creates a SQLite database with proper schema
/// 3. Saves to assets/database/hanly_vocab.db
/// 4. The app will copy this DB on first launch
///
/// Run this whenever vocab data changes on backend

import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'https://hanzi-memory-api.onrender.com';
const String outputPath = 'assets/database/hanly_vocab.db';

Future<void> main() async {
  print('📚 Starting vocab database generation...\n');
  
  try {
    // Step 1: Fetch all vocab from API
    print('1️⃣ Fetching vocabulary from API...');
    final vocabs = await fetchAllVocabs();
    print('   ✅ Fetched ${vocabs.length} vocabulary items\n');
    
    // Step 2: Create SQLite database
    // Note: This requires sqlite3 CLI tool installed
    print('2️⃣ Creating SQLite database...');
    await createDatabase(vocabs);
    print('   ✅ Database created at $outputPath\n');
    
    print('🎉 Done! The database will be bundled with the app.');
    print('   Users will have all ${vocabs.length} words available offline.');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<List<Map<String, dynamic>>> fetchAllVocabs() async {
  final allVocabs = <Map<String, dynamic>>[];
  
  // Fetch by level to get all vocabs
  final levels = ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];
  
  for (final level in levels) {
    var page = 1;
    var hasMore = true;
    
    while (hasMore) {
      final url = Uri.parse('$apiBaseUrl/vocabs?level=$level&page=$page&limit=100');
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        throw Exception('API returned ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      final items = data['data'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      
      allVocabs.addAll(items.cast<Map<String, dynamic>>());
      
      hasMore = pagination['hasNext'] as bool? ?? false;
      page++;
      
      // Rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('   - $level: ${allVocabs.length} total');
  }
  
  return allVocabs;
}

Future<void> createDatabase(List<Map<String, dynamic>> vocabs) async {
  // Create SQL file
  final sqlFile = File('assets/database/init.sql');
  await sqlFile.parent.create(recursive: true);
  
  final sql = StringBuffer();
  
  // Create tables
  sql.writeln('''
-- Vocabulary table
CREATE TABLE IF NOT EXISTS vocabs (
  id TEXT PRIMARY KEY,
  word TEXT NOT NULL,
  pinyin TEXT NOT NULL,
  meaning_vi TEXT NOT NULL,
  meaning_en TEXT,
  level TEXT NOT NULL,
  order_in_level INTEGER DEFAULT 0,
  topic TEXT,
  word_type TEXT,
  frequency_rank INTEGER,
  difficulty INTEGER DEFAULT 3,
  audio_url TEXT,
  image_url TEXT,
  examples TEXT,
  collocations TEXT,
  radicals TEXT,
  components TEXT,
  stroke_count INTEGER,
  mnemonic TEXT,
  created_at TEXT,
  updated_at TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vocabs_level ON vocabs(level);
CREATE INDEX IF NOT EXISTS idx_vocabs_topic ON vocabs(topic);
CREATE INDEX IF NOT EXISTS idx_vocabs_word ON vocabs(word);
CREATE INDEX IF NOT EXISTS idx_vocabs_pinyin ON vocabs(pinyin);
CREATE INDEX IF NOT EXISTS idx_vocabs_order ON vocabs(level, order_in_level);

-- Progress table
CREATE TABLE IF NOT EXISTS vocab_progress (
  vocab_id TEXT PRIMARY KEY,
  state TEXT DEFAULT 'new',
  ease_factor REAL DEFAULT 2.5,
  interval_days INTEGER DEFAULT 0,
  repetitions INTEGER DEFAULT 0,
  due_date TEXT,
  last_reviewed TEXT,
  times_reviewed INTEGER DEFAULT 0,
  times_correct INTEGER DEFAULT 0,
  is_favorite INTEGER DEFAULT 0,
  is_locked INTEGER DEFAULT 1,
  unlocked_at TEXT,
  synced INTEGER DEFAULT 0,
  updated_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_progress_state ON vocab_progress(state);
CREATE INDEX IF NOT EXISTS idx_progress_due ON vocab_progress(due_date);
CREATE INDEX IF NOT EXISTS idx_progress_locked ON vocab_progress(is_locked);

-- Settings table
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

INSERT INTO settings (key, value) VALUES ('dataset_version', '2026.01.18');

''');
  
  // Insert vocabs
  for (final vocab in vocabs) {
    final id = _escape(vocab['_id'] ?? vocab['id'] ?? '');
    final word = _escape(vocab['word'] ?? '');
    final pinyin = _escape(vocab['pinyin'] ?? '');
    final meaningVi = _escape(vocab['meaning_vi'] ?? '');
    final meaningEn = _escape(vocab['meaning_en'] ?? '');
    final level = _escape(vocab['level'] ?? 'HSK1');
    final orderInLevel = vocab['order_in_level'] ?? 0;
    final topic = _escape((vocab['topics'] as List?)?.firstOrNull ?? '');
    final wordType = _escape(vocab['word_type'] ?? '');
    final frequencyRank = vocab['frequency_rank'] ?? 0;
    final difficulty = vocab['difficulty_score'] ?? 3;
    final audioUrl = _escape(vocab['audio_url'] ?? '');
    final imageUrl = _escape((vocab['images'] as List?)?.firstOrNull ?? '');
    final examples = _escape(jsonEncode(vocab['examples'] ?? []));
    final collocations = _escape(jsonEncode(vocab['collocations'] ?? []));
    final strokeCount = vocab['stroke_count'] ?? 0;
    final mnemonic = _escape(vocab['mnemonic'] ?? '');
    
    sql.writeln('''
INSERT INTO vocabs (id, word, pinyin, meaning_vi, meaning_en, level, order_in_level, topic, word_type, frequency_rank, difficulty, audio_url, image_url, examples, collocations, stroke_count, mnemonic)
VALUES ('$id', '$word', '$pinyin', '$meaningVi', '$meaningEn', '$level', $orderInLevel, '$topic', '$wordType', $frequencyRank, $difficulty, '$audioUrl', '$imageUrl', '$examples', '$collocations', $strokeCount, '$mnemonic');
''');
  }
  
  // Unlock first 20 words of HSK1
  sql.writeln('''
-- Unlock first 20 words of HSK1 by default
INSERT INTO vocab_progress (vocab_id, is_locked)
SELECT id, 0 FROM vocabs WHERE level = 'HSK1' ORDER BY order_in_level LIMIT 20;
''');
  
  await sqlFile.writeAsString(sql.toString());
  
  // Create SQLite database using sqlite3 CLI
  final dbFile = File(outputPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
  }
  
  final result = await Process.run('sqlite3', [
    outputPath,
    '.read ${sqlFile.path}'
  ]);
  
  if (result.exitCode != 0) {
    print('   ⚠️ sqlite3 CLI not available. SQL file created at ${sqlFile.path}');
    print('   Run manually: sqlite3 $outputPath ".read ${sqlFile.path}"');
  } else {
    print('   ✅ SQLite database created');
    // Cleanup SQL file
    await sqlFile.delete();
  }
}

String _escape(String value) {
  return value.replaceAll("'", "''");
}

extension FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

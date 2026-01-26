import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';

import '../../core/utils/logger.dart';

/// Singleton service for managing local SQLite database
/// Implements offline-first strategy for vocabulary data
class DatabaseService extends GetxService {
  static const String _dbName = 'hanly_vocab.db';
  static const int _dbVersion = 2;

  // Fallback version for bundled DB (if present)
  static const String bundledDatasetVersion = '2026.01.18';
  
  Database? _database;
  
  Database get db {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }
  
  bool get isInitialized => _database != null;

  /// Initialize database - copies from assets if first launch
  Future<DatabaseService> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, _dbName);
    
    // Check if database exists
    final dbExists = await File(dbPath).exists();
    
    if (!dbExists) {
      Logger.i('DatabaseService', '📦 First launch - copying vocab database from assets...');
      await _copyDatabaseFromAssets(dbPath);
    }
    
    // Open database
    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        await _ensureProgressEventTables(db);
      },
      onOpen: (db) {
        Logger.i('DatabaseService', '✅ Database opened: $dbPath');
      },
    );

    // Ensure new tables exist (safe for older bundled DBs)
    await _createTables(_database!);
    await _ensureProgressEventTables(_database!);
    await _ensureDatasetMetadata();
    
    // Log stats
    final count = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM vocabs'),
    );
    Logger.i('DatabaseService', '📚 Loaded $count vocabulary items');
    
    return this;
  }
  
  /// Copy pre-built database from assets
  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    try {
      // Load from assets
      final data = await rootBundle.load('assets/database/$_dbName');
      final bytes = data.buffer.asUint8List();
      
      // Write to documents directory
      await File(dbPath).writeAsBytes(bytes, flush: true);
      Logger.i('DatabaseService', '✅ Database copied to $dbPath');
    } catch (e) {
      Logger.e('DatabaseService', 'Failed to copy database from assets', e);
      // If asset doesn't exist, create empty database with schema
      await _createEmptyDatabase(dbPath);
    }
  }
  
  /// Create empty database with schema (fallback if no asset)
  Future<void> _createEmptyDatabase(String dbPath) async {
    Logger.w('DatabaseService', '⚠️ No bundled database found, creating empty schema...');
    
    final db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
    await db.close();
  }
  
  /// Create all tables
  Future<void> _createTables(Database db) async {
    // Vocabulary table
    await db.execute('''
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
      )
    ''');
    
    // Create indexes for fast queries
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocabs_level ON vocabs(level)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocabs_topic ON vocabs(topic)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocabs_word ON vocabs(word)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocabs_pinyin ON vocabs(pinyin)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vocabs_order ON vocabs(level, order_in_level)');
    
    // User progress table (local-first, synced to server)
    await db.execute('''
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
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_state ON vocab_progress(state)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_due ON vocab_progress(due_date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_locked ON vocab_progress(is_locked)');
    
    // Settings/metadata table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    Logger.i('DatabaseService', '✅ Database schema created');
  }

  Future<void> _ensureProgressEventTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progress_events (
        event_id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        attempts INTEGER DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_events_synced ON progress_events(synced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_events_retry ON progress_events(next_retry_at)',
    );
  }
  
  /// Get current dataset version
  Future<String?> getDatasetVersion() async {
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['dataset_version'],
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  Future<String?> getSetting(String key) async {
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _ensureDatasetMetadata() async {
    final existing = await getSetting('dataset_version');
    if (existing != null && existing.isNotEmpty) return;

    final countResult = await _database!.rawQuery('SELECT COUNT(*) as count FROM vocabs');
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    final fallback = count > 0 ? bundledDatasetVersion : '0';

    await setSetting('dataset_version', fallback);
    if (count > 0) {
      await setSetting('dataset_downloaded_at', DateTime.now().toIso8601String());
    }
  }
  
  /// Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Clear user-specific progress and sync queue
  Future<void> clearUserProgress() async {
    if (_database == null) return;
    await _database!.delete('vocab_progress');
    await _database!.delete('progress_events');
    await _database!.delete(
      'settings',
      where: 'key LIKE ?',
      whereArgs: ['daily_stats_%'],
    );
  }
  
  @override
  void onClose() {
    _database?.close();
    super.onClose();
  }
}

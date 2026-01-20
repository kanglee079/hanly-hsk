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
  static const int _dbVersion = 1;
  
  // Dataset version for delta updates
  static const String datasetVersion = '2026.01.18';
  
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
    } else {
      // Check if we need to update (version mismatch)
      final needsUpdate = await _checkNeedsUpdate(dbPath);
      if (needsUpdate) {
        Logger.i('DatabaseService', '🔄 Dataset update available - updating...');
        await File(dbPath).delete();
        await _copyDatabaseFromAssets(dbPath);
      }
    }
    
    // Open database
    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onOpen: (db) {
        Logger.i('DatabaseService', '✅ Database opened: $dbPath');
      },
    );
    
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
    
    // Insert dataset version
    await db.insert('settings', {
      'key': 'dataset_version',
      'value': datasetVersion,
    });
    
    Logger.i('DatabaseService', '✅ Database schema created');
  }
  
  /// Check if dataset needs update
  Future<bool> _checkNeedsUpdate(String dbPath) async {
    try {
      final db = await openDatabase(dbPath, readOnly: true);
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['dataset_version'],
      );
      await db.close();
      
      if (result.isEmpty) return true;
      
      final currentVersion = result.first['value'] as String?;
      return currentVersion != datasetVersion;
    } catch (e) {
      Logger.w('DatabaseService', 'Could not check version: $e');
      return true;
    }
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
  
  /// Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
  
  @override
  void onClose() {
    _database?.close();
    super.onClose();
  }
}

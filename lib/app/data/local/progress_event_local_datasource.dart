import 'dart:convert';
import 'dart:math';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';
import '../../services/storage_service.dart';

class ProgressEvent {
  final String eventId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  ProgressEvent({
    required this.eventId,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toRow() {
    return {
      'event_id': eventId,
      'event_type': eventType,
      'payload': jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
      'synced': 0,
      'attempts': 0,
      'next_retry_at': null,
      'last_error': null,
    };
  }
}

class ProgressEventLocalDataSource extends GetxService {
  final DatabaseService _db = Get.find<DatabaseService>();
  StorageService? _storage;
  final Random _random = Random();

  @override
  void onInit() {
    super.onInit();
    try {
      _storage = Get.find<StorageService>();
    } catch (_) {
      _storage = null;
    }
  }

  String _generateEventId() {
    final deviceId = _storage?.deviceId ?? 'device';
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = _random.nextInt(1 << 20);
    return '$deviceId-$now-$rand';
  }

  Future<String> enqueueEvent({
    required String eventType,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
  }) async {
    final event = ProgressEvent(
      eventId: _generateEventId(),
      eventType: eventType,
      payload: payload,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _db.db.insert('progress_events', event.toRow());
    return event.eventId;
  }

  Future<List<Map<String, dynamic>>> getPendingEvents({int limit = 20}) async {
    return _db.db.query(
      'progress_events',
      where: 'synced = 0 AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  Future<int> getPendingCount() async {
    final result = await _db.db.rawQuery(
      'SELECT COUNT(*) as count FROM progress_events WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    final placeholders = eventIds.map((_) => '?').join(',');
    await _db.db.rawUpdate(
      '''
      UPDATE progress_events
      SET synced = 1, last_error = NULL
      WHERE event_id IN ($placeholders)
    ''',
      eventIds,
    );
  }

  Future<void> markFailed({
    required String eventId,
    required int attempts,
    required DateTime nextRetryAt,
    required String error,
  }) async {
    await _db.db.update(
      'progress_events',
      {
        'attempts': attempts,
        'next_retry_at': nextRetryAt.toIso8601String(),
        'last_error': error,
      },
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  Map<String, dynamic> decodePayload(String payloadJson) {
    try {
      return jsonDecode(payloadJson) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}

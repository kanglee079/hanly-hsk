import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/local/progress_event_local_datasource.dart';
import '../data/repositories/learning_repo.dart';
import 'auth_session_service.dart';
import 'connectivity_service.dart';

enum ProgressSyncState { idle, syncing, synced, failed }

/// Service to sync local progress events with backend
/// Implements background batch sync + retry with backoff
class ProgressSyncService extends GetxService {
  ProgressEventLocalDataSource? _eventStore;
  LearningRepo? _learningRepo;
  ConnectivityService? _connectivity;
  AuthSessionService? _auth;

  Timer? _syncTimer;
  Timer? _debounceTimer;

  static const Duration _syncInterval = Duration(minutes: 3);
  static const Duration _debounceDelay = Duration(seconds: 20);
  static const int _batchSize = 20;

  final Rx<ProgressSyncState> state = ProgressSyncState.idle.obs;
  final RxInt pendingCount = 0.obs;
  final RxString lastError = ''.obs;
  final Rx<DateTime?> lastSyncedAt = Rx<DateTime?>(null);
  final RxInt lastSyncLatencyMs = 0.obs;
  final RxInt syncSuccessCount = 0.obs;
  final RxInt syncFailureCount = 0.obs;

  bool _isSyncing = false;

  @override
  void onInit() {
    super.onInit();

    Future.delayed(const Duration(seconds: 2), () {
      _initDependencies();
      _startPeriodicSync();
      refreshPendingCount();
    });
  }

  void _initDependencies() {
    try {
      _eventStore = Get.find<ProgressEventLocalDataSource>();
    } catch (_) {
      Logger.w('ProgressSyncService', 'ProgressEventLocalDataSource not available');
    }

    try {
      _learningRepo = Get.find<LearningRepo>();
    } catch (_) {
      Logger.w('ProgressSyncService', 'LearningRepo not available');
    }

    try {
      _connectivity = Get.find<ConnectivityService>();
    } catch (_) {
      Logger.w('ProgressSyncService', 'ConnectivityService not available');
    }

    if (_connectivity != null) {
      ever<bool>(_connectivity!.isOnline, (online) {
        if (online) {
          scheduleSync(immediate: true);
        }
      });
    }

    try {
      _auth = Get.find<AuthSessionService>();
    } catch (_) {
      _auth = null;
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => syncPendingEvents());
  }

  void scheduleSync({bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      unawaited(syncPendingEvents());
      return;
    }
    _debounceTimer = Timer(_debounceDelay, () => syncPendingEvents());
  }

  Future<void> refreshPendingCount() async {
    if (_eventStore == null) return;
    pendingCount.value = await _eventStore!.getPendingCount();
  }

  Future<void> syncPendingEvents() async {
    if (_eventStore == null || _learningRepo == null) return;
    if (_isSyncing) return;

    if (_connectivity != null && !_connectivity!.isOnline.value) {
      Logger.d('ProgressSyncService', 'Offline - skipping sync');
      state.value = ProgressSyncState.idle;
      return;
    }

    if (_auth != null && !_auth!.isLoggedIn) {
      Logger.d('ProgressSyncService', 'Not logged in - skipping sync');
      state.value = ProgressSyncState.idle;
      return;
    }

    _isSyncing = true;
    state.value = ProgressSyncState.syncing;
    lastError.value = '';

    final pending = <Map<String, dynamic>>[];

    try {
      pending.addAll(await _eventStore!.getPendingEvents(limit: _batchSize));
      pendingCount.value = await _eventStore!.getPendingCount();

      if (pending.isEmpty) {
        state.value = ProgressSyncState.synced;
        return;
      }

      final eventsPayload = pending.map((row) {
        final payload = _eventStore!.decodePayload(row['payload'] as String);
        return {
          'eventId': row['event_id'],
          'eventType': row['event_type'],
          'payload': payload,
          'occurredAt': row['created_at'],
        };
      }).toList();

      final start = DateTime.now();
      final response =
          await _learningRepo!.syncProgressBatch(events: eventsPayload);
      lastSyncLatencyMs.value =
          DateTime.now().difference(start).inMilliseconds;

      if (response.acked.isNotEmpty) {
        await _eventStore!.markSynced(response.acked);
      }

      if (response.failed.isNotEmpty) {
        for (final failure in response.failed) {
          final row = pending.firstWhere(
            (r) => r['event_id'] == failure.eventId,
            orElse: () => <String, dynamic>{},
          );
          final attempts = (row['attempts'] as int? ?? 0) + 1;
          final nextRetryAt =
              DateTime.now().add(_calculateBackoff(attempts));
          await _eventStore!.markFailed(
            eventId: failure.eventId,
            attempts: attempts,
            nextRetryAt: nextRetryAt,
            error: failure.error,
          );
        }
        lastError.value = 'Partial sync failure';
        state.value = ProgressSyncState.failed;
        syncFailureCount.value++;
      } else {
        state.value = ProgressSyncState.synced;
        syncSuccessCount.value++;
      }

      lastSyncedAt.value = DateTime.now();
      pendingCount.value = await _eventStore!.getPendingCount();
      Logger.i(
        'ProgressSyncService',
        'Sync done: acked=${response.acked.length}, failed=${response.failed.length}, '
            'latencyMs=${lastSyncLatencyMs.value}, pending=${pendingCount.value}',
      );
    } catch (e) {
      lastError.value = e.toString();
      state.value = ProgressSyncState.failed;
      syncFailureCount.value++;
      await _markBatchFailed(pending);
      Logger.e('ProgressSyncService', 'Sync failed', e);
    } finally {
      _isSyncing = false;
    }
  }

  Duration _calculateBackoff(int attempts) {
    final seconds = min(900, pow(2, attempts).toInt() * 15);
    return Duration(seconds: seconds);
  }

  Future<void> _markBatchFailed(List<Map<String, dynamic>> pending) async {
    for (final row in pending) {
      final attempts = (row['attempts'] as int? ?? 0) + 1;
      final nextRetryAt = DateTime.now().add(_calculateBackoff(attempts));
      await _eventStore!.markFailed(
        eventId: row['event_id'] as String,
        attempts: attempts,
        nextRetryAt: nextRetryAt,
        error: 'sync_failed',
      );
    }
  }

  Future<void> syncNow() async {
    await syncPendingEvents();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _debounceTimer?.cancel();
    super.onClose();
  }
}

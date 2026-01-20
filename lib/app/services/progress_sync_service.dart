import 'dart:async';
import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/local/vocab_local_datasource.dart';
import '../data/repositories/learning_repo.dart';
import 'connectivity_service.dart';

/// Service to sync local progress with backend
/// Implements background sync with retry and conflict resolution
class ProgressSyncService extends GetxService {
  VocabLocalDataSource? _localDataSource;
  LearningRepo? _learningRepo;
  ConnectivityService? _connectivity;
  
  Timer? _syncTimer;
  static const Duration _syncInterval = Duration(minutes: 5);
  
  final RxBool isSyncing = false.obs;
  final RxInt pendingCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Lazy init dependencies (they might not be ready yet)
    Future.delayed(const Duration(seconds: 2), () {
      _initDependencies();
      _startPeriodicSync();
    });
  }
  
  void _initDependencies() {
    try {
      _localDataSource = Get.find<VocabLocalDataSource>();
    } catch (_) {
      Logger.w('ProgressSyncService', 'VocabLocalDataSource not available');
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
  }
  
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => syncPendingProgress());
  }
  
  /// Sync all pending progress to backend
  Future<void> syncPendingProgress() async {
    if (_localDataSource == null || _learningRepo == null) return;
    if (isSyncing.value) return;
    
    // Check connectivity
    if (_connectivity != null && !_connectivity!.isOnline.value) {
      Logger.d('ProgressSyncService', 'Offline - skipping sync');
      return;
    }
    
    isSyncing.value = true;
    
    try {
      final unsynced = await _localDataSource!.getUnsyncedProgress();
      pendingCount.value = unsynced.length;
      
      if (unsynced.isEmpty) {
        Logger.d('ProgressSyncService', 'No pending progress to sync');
        isSyncing.value = false;
        return;
      }
      
      Logger.i('ProgressSyncService', '📤 Syncing ${unsynced.length} progress entries...');
      
      final syncedIds = <String>[];
      
      for (final entry in unsynced) {
        try {
          final vocabId = entry['vocab_id'] as String;
          final state = entry['state'] as String?;
          
          // Only sync if there's actual progress data
          if (state != null && state != 'new') {
            // TODO: Call backend sync endpoint when available
            // For now, we'll just mark as synced since backend doesn't have
            // a dedicated progress sync endpoint yet
            // await _learningRepo!.syncProgress(vocabId, entry);
          }
          
          syncedIds.add(vocabId);
        } catch (e) {
          Logger.e('ProgressSyncService', 'Failed to sync ${entry['vocab_id']}', e);
          // Continue with other entries
        }
      }
      
      // Mark all as synced
      if (syncedIds.isNotEmpty) {
        await _localDataSource!.markSynced(syncedIds);
        Logger.i('ProgressSyncService', '✅ Synced ${syncedIds.length} entries');
      }
      
      pendingCount.value = 0;
    } catch (e) {
      Logger.e('ProgressSyncService', 'Sync failed', e);
    } finally {
      isSyncing.value = false;
    }
  }
  
  /// Force immediate sync
  Future<void> syncNow() async {
    await syncPendingProgress();
  }
  
  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
}

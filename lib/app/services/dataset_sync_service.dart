import 'dart:async';
import 'package:get/get.dart';

import '../core/utils/logger.dart';
import '../data/local/database_service.dart';
import '../data/local/vocab_local_datasource.dart';
import '../data/repositories/dataset_repo.dart';
import 'connectivity_service.dart';

enum DatasetSyncState {
  idle,
  checking,
  downloading,
  applying,
  synced,
  offline,
  failed,
}

class DatasetSyncService extends GetxService {
  final DatasetRepo _datasetRepo = Get.find<DatasetRepo>();
  final VocabLocalDataSource _vocabLocal = Get.find<VocabLocalDataSource>();
  final DatabaseService _db = Get.find<DatabaseService>();
  ConnectivityService? _connectivity;

  final Rx<DatasetSyncState> state = DatasetSyncState.idle.obs;
  final RxDouble progress = 0.0.obs;
  final RxString lastError = ''.obs;
  final RxString localVersion = ''.obs;
  final RxString remoteVersion = ''.obs;
  final RxString remoteUpdatedAt = ''.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      _connectivity = Get.find<ConnectivityService>();
    } catch (_) {
      _connectivity = null;
    }
    _loadLocalMeta();
  }

  Future<void> _loadLocalMeta() async {
    final version = await _db.getDatasetVersion();
    localVersion.value = version ?? '0';
  }

  bool get hasDataset => localVersion.value != '0' && localVersion.value.isNotEmpty;

  Future<void> checkAndSync({bool force = false}) async {
    if (_connectivity != null && !_connectivity!.isOnline.value) {
      state.value = DatasetSyncState.offline;
      return;
    }

    state.value = DatasetSyncState.checking;
    lastError.value = '';

    try {
      await _loadLocalMeta();
      final meta = await _datasetRepo.getDatasetMeta();
      remoteVersion.value = meta.version;
      remoteUpdatedAt.value = meta.updatedAt;

      final shouldDownload = force || localVersion.value != meta.version;
      if (!shouldDownload) {
        state.value = DatasetSyncState.synced;
        return;
      }

      await _downloadAndApply(meta);
    } catch (e) {
      lastError.value = e.toString();
      state.value = DatasetSyncState.failed;
      Logger.e('DatasetSyncService', 'Dataset sync failed', e);
    }
  }

  Future<void> _downloadAndApply(DatasetMeta meta) async {
    progress.value = 0.0;
    state.value = DatasetSyncState.downloading;

    final payload = await _datasetRepo.downloadDataset(
      onProgress: (received, total) {
        if (total > 0) {
          progress.value = received / total;
        }
      },
    );

    state.value = DatasetSyncState.applying;
    await _vocabLocal.replaceDataset(
      vocabs: payload.vocabs,
      version: meta.version,
      checksum: meta.checksum,
      updatedAt: meta.updatedAt,
    );

    localVersion.value = meta.version;
    progress.value = 1.0;
    state.value = DatasetSyncState.synced;
  }
}

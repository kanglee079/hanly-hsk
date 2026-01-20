import 'package:get/get.dart';

import '../../core/widgets/hm_toast.dart';
import '../../core/utils/logger.dart';

class OfflineBundleModel {
  final String level;
  final String name;
  final int vocabCount;
  final double sizeInMB;
  final bool isDownloaded;

  OfflineBundleModel({
    required this.level,
    required this.name,
    required this.vocabCount,
    required this.sizeInMB,
    this.isDownloaded = false,
  });
}

class OfflineDownloadController extends GetxController {
  final RxList<OfflineBundleModel> bundles = <OfflineBundleModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBundles();
  }

  void _loadBundles() {
    // Mock data - trong thực tế sẽ call API GET /offline/bundles
    bundles.value = [
      OfflineBundleModel(
        level: 'HSK1',
        name: 'HSK 1 - Cơ bản',
        vocabCount: 150,
        sizeInMB: 25.5,
        isDownloaded: true, // Already have in SQLite
      ),
      OfflineBundleModel(
        level: 'HSK2',
        name: 'HSK 2 - Cơ bản',
        vocabCount: 150,
        sizeInMB: 28.3,
        isDownloaded: true, // Already have in SQLite
      ),
      OfflineBundleModel(
        level: 'HSK3',
        name: 'HSK 3 - Sơ cấp',
        vocabCount: 300,
        sizeInMB: 45.2,
        isDownloaded: true, // Already have in SQLite
      ),
      OfflineBundleModel(
        level: 'HSK4',
        name: 'HSK 4 - Trung cấp',
        vocabCount: 600,
        sizeInMB: 78.1,
        isDownloaded: true, // Already have in SQLite
      ),
      OfflineBundleModel(
        level: 'HSK5',
        name: 'HSK 5 - Trung cao cấp',
        vocabCount: 1300,
        sizeInMB: 142.5,
        isDownloaded: true, // Already have in SQLite
      ),
      OfflineBundleModel(
        level: 'HSK6',
        name: 'HSK 6 - Cao cấp',
        vocabCount: 2500,
        sizeInMB: 245.8,
        isDownloaded: true, // Already have in SQLite
      ),
    ];
    isLoading.value = false;
  }

  Future<void> downloadBundle(OfflineBundleModel bundle) async {
    // With offline-first SQLite, all data is already bundled in the app
    // This is now just for show/consistency
    HMToast.info('Tất cả từ vựng đã có sẵn trong app! 📦');
    Logger.d('OfflineDownloadController', 'All vocabs already bundled with app');
  }

  Future<void> deleteBundle(OfflineBundleModel bundle) async {
    HMToast.info('Không thể xóa dữ liệu nền tảng');
  }

  double getTotalSize() {
    return bundles.fold(0.0, (sum, b) => sum + (b.isDownloaded ? b.sizeInMB : 0));
  }

  int getTotalVocabs() {
    return bundles.fold(0, (sum, b) => sum + (b.isDownloaded ? b.vocabCount : 0));
  }
}

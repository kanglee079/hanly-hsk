import 'package:get/get.dart';

import '../../data/repositories/me_repo.dart';
import '../../services/auth_session_service.dart';
import '../../services/storage_service.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/utils/logger.dart';

class SoundSettingsController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final StorageService _storage = Get.find<StorageService>();

  final RxBool soundEnabled = true.obs;
  final RxBool hapticsEnabled = true.obs;
  final RxBool vietnameseSupport = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  void _loadSettings() {
    // Load from local storage (primary source)
    soundEnabled.value = _storage.soundEnabled;
    hapticsEnabled.value = _storage.hapticsEnabled;
    // Vietnamese support is always on for now
    vietnameseSupport.value = true;
  }

  Future<void> toggleSound(bool value) async {
    soundEnabled.value = value;
    _storage.soundEnabled = value;
    await _saveToServer({'soundEnabled': value});
  }

  Future<void> toggleHaptics(bool value) async {
    hapticsEnabled.value = value;
    _storage.hapticsEnabled = value;
    await _saveToServer({'hapticsEnabled': value});
  }

  Future<void> toggleVietnamese(bool value) async {
    vietnameseSupport.value = value;
    await _saveToServer({'vietnameseSupport': value});
  }

  Future<void> _saveToServer(Map<String, dynamic> data) async {
    isSaving.value = true;

    try {
      await _meRepo.updateProfile(data);
      await _authService.fetchCurrentUser();
    } catch (e) {
      Logger.e('SoundSettingsController', 'Error saving settings', e);
      HMToast.error('Không thể lưu cài đặt');
    } finally {
      isSaving.value = false;
    }
  }
}

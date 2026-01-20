import 'package:get/get.dart';
import 'sound_settings_controller.dart';

class SoundSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SoundSettingsController());
  }
}

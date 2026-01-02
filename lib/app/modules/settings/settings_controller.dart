import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  // Observables
  final RxString currentThemeMode = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    currentThemeMode.value = _storage.themeMode;
  }

  /// Change theme mode
  void changeTheme(String mode) {
    if (currentThemeMode.value == mode) return;

    currentThemeMode.value = mode;
    _storage.themeMode = mode;

    ThemeMode themeMode;
    switch (mode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
        break;
    }

    // Immediate update
    Get.changeThemeMode(themeMode);
  }

  /// Get display text for theme mode
  String getThemeModeText(String mode) {
    switch (mode) {
      case 'light':
        return 'Sáng';
      case 'dark':
        return 'Tối';
      default:
        return 'Hệ thống';
    }
  }
}

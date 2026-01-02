import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

/// Theme modes available in the app
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Service to manage app theme (light/dark/system)
class ThemeService extends GetxController {
  static ThemeService get to => Get.find();

  final _storageService = Get.find<StorageService>();

  /// Current theme mode - default is LIGHT
  final Rx<AppThemeMode> themeMode = AppThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  /// Load saved theme from storage
  /// Default is LIGHT if user hasn't chosen anything yet
  void _loadSavedTheme() {
    final saved = _storageService.themeMode;
    switch (saved) {
      case 'dark':
        themeMode.value = AppThemeMode.dark;
        break;
      case 'system':
        themeMode.value = AppThemeMode.system;
        break;
      case 'light':
      default:
        // Default to light theme
        themeMode.value = AppThemeMode.light;
    }
  }

  /// Get the current ThemeMode for GetMaterialApp
  ThemeMode get currentThemeMode {
    switch (themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if current mode is dark
  bool get isDark {
    if (themeMode.value == AppThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return themeMode.value == AppThemeMode.dark;
  }

  /// Change theme mode
  void setThemeMode(AppThemeMode mode) {
    themeMode.value = mode;
    
    // Save to storage
    switch (mode) {
      case AppThemeMode.light:
        _storageService.themeMode = 'light';
        break;
      case AppThemeMode.dark:
        _storageService.themeMode = 'dark';
        break;
      case AppThemeMode.system:
        _storageService.themeMode = 'system';
    }

    // Update GetMaterialApp theme
    Get.changeThemeMode(currentThemeMode);

    // Update status bar style
    _updateSystemUI();
  }

  /// Update system UI based on current theme
  void _updateSystemUI() {
    final isDarkMode = isDark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Toggle between light and dark
  void toggleTheme() {
    if (themeMode.value == AppThemeMode.light) {
      setThemeMode(AppThemeMode.dark);
    } else {
      setThemeMode(AppThemeMode.light);
    }
  }

  /// Get display name for theme mode
  String getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Sáng';
      case AppThemeMode.dark:
        return 'Tối';
      case AppThemeMode.system:
        return 'Theo hệ thống';
    }
  }

  /// Get icon for theme mode
  IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.system:
        return Icons.settings_brightness_rounded;
    }
  }
}


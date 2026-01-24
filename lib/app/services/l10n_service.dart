import 'dart:ui';
import 'package:get/get.dart';
import 'storage_service.dart';

/// Localization service for managing app language
/// Supports Vietnamese (vi) and English (en)
class L10nService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();

  /// Current locale code: 'vi' or 'en'
  final RxString currentLocale = 'vi'.obs;

  /// Supported locales
  static const List<String> supportedLocales = ['vi', 'en'];

  @override
  void onInit() {
    super.onInit();
    // Load saved locale preference
    final savedLocale = _storage.appLocale;
    if (supportedLocales.contains(savedLocale)) {
      currentLocale.value = savedLocale;
    }
  }

  /// Change app language
  void changeLocale(String locale) {
    if (!supportedLocales.contains(locale)) return;
    if (currentLocale.value == locale) return;

    currentLocale.value = locale;
    _storage.appLocale = locale;

    // Trigger UI rebuild by updating Get locale
    Get.updateLocale(
      locale == 'en' ? const Locale('en', 'US') : const Locale('vi', 'VN'),
    );
  }

  /// Check if current locale is English
  bool get isEnglish => currentLocale.value == 'en';

  /// Get display name for locale
  String getLocaleDisplayName(String locale) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'vi':
      default:
        return 'Tiếng Việt';
    }
  }
}

/// Application configuration with environment variables
class AppConfig {
  AppConfig._();

  /// API base URL from --dart-define or fallback
  /// Backend: https://hanzi-memory-api.onrender.com (NO /api/v1 prefix)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hanzi-memory-api.onrender.com',
  );

  /// App name
  static const String appName = 'Từ Vựng - Từ Điển HSK Chuyên Nghiệp XiKang';

  /// App version
  static const String appVersion = '1.0.0';

  /// Request timeout in seconds
  static const int requestTimeout = 30;

  /// Send timeout in seconds
  static const int sendTimeout = 30;

  /// Enable debug logging
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: true,
  );
}

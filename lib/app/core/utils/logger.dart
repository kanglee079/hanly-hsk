import 'dart:developer' as developer;
import '../config/app_config.dart';

/// Simple logger utility
class Logger {
  Logger._();

  static void d(String tag, String message) {
    if (AppConfig.enableLogging) {
      developer.log('[$tag] $message', name: 'DEBUG');
    }
  }

  static void i(String tag, String message) {
    if (AppConfig.enableLogging) {
      developer.log('[$tag] $message', name: 'INFO');
    }
  }

  static void w(String tag, String message) {
    if (AppConfig.enableLogging) {
      developer.log('[$tag] ⚠️ $message', name: 'WARN');
    }
  }

  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    if (AppConfig.enableLogging) {
      developer.log(
        '[$tag] ❌ $message',
        name: 'ERROR',
        error: error,
        stackTrace: stack,
      );
    }
  }
}


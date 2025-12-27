import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/app_routes.dart';
import '../api_endpoints.dart';

/// Result of a token refresh operation
class _RefreshResult {
  final String accessToken;
  final String refreshToken;
  _RefreshResult(this.accessToken, this.refreshToken);
}

/// Refresh token interceptor - handles 401 and refreshes tokens
/// 
/// Features:
/// - Mutex to prevent multiple concurrent refresh requests
/// - __retry flag to prevent infinite loops
/// - __skipRefresh flag to skip this interceptor for refresh request itself
/// - Handles both status code 401 and body error code UNAUTHORIZED
class RefreshInterceptor extends Interceptor {
  final Dio dio;
  
  /// Mutex: completer for ongoing refresh operation
  Completer<_RefreshResult?>? _refreshCompleter;
  
  RefreshInterceptor(this.dio);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Check if response body indicates unauthorized
    if (_isUnauthorizedResponse(response)) {
      Logger.d('RefreshInterceptor', 'Got UNAUTHORIZED in response body');
      
      final options = response.requestOptions;
      
      // Skip if marked to skip refresh
      if (options.extra['__skipRefresh'] == true) {
        return handler.next(response);
      }
      
      // Skip if already retried
      if (options.extra['__retry'] == true) {
        Logger.w('RefreshInterceptor', 'Already retried, redirecting to login');
        _handleAuthFailure();
        return handler.next(response);
      }
      
      // Try to refresh token
      final refreshed = await _tryRefreshAndRetry(options, handler);
      if (refreshed) return;
      
      // Refresh failed, redirect to login
      _handleAuthFailure();
    }
    
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 status code
    if (err.response?.statusCode == 401) {
      Logger.d('RefreshInterceptor', 'Got 401 status code');
      
      final options = err.requestOptions;
      
      // Skip if marked to skip refresh
      if (options.extra['__skipRefresh'] == true) {
        return handler.next(err);
      }
      
      // Skip if already retried
      if (options.extra['__retry'] == true) {
        Logger.w('RefreshInterceptor', 'Already retried, redirecting to login');
        _handleAuthFailure();
        return handler.next(err);
      }
      
      // Try to refresh token
      try {
        final result = await _performRefresh();
        if (result != null) {
          final retryResponse = await _retryRequest(options, result.accessToken);
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        Logger.e('RefreshInterceptor', 'Refresh failed', e);
      }
      
      // Refresh failed, redirect to login
      _handleAuthFailure();
    }
    
    return handler.next(err);
  }

  /// Check if response body indicates unauthorized
  bool _isUnauthorizedResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Check for success: false with UNAUTHORIZED code
      if (data['success'] == false) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final code = error['code']?.toString().toUpperCase();
          final message = error['message']?.toString().toLowerCase();
          return code == 'UNAUTHORIZED' || 
                 message?.contains('token expired') == true ||
                 message?.contains('invalid token') == true;
        }
      }
    }
    return false;
  }

  /// Try to refresh token and retry the request
  Future<bool> _tryRefreshAndRetry(
    RequestOptions options,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      final result = await _performRefresh();
      if (result != null) {
        final retryResponse = await _retryRequest(options, result.accessToken);
        handler.resolve(retryResponse);
        return true;
      }
    } catch (e) {
      Logger.e('RefreshInterceptor', 'Refresh failed', e);
    }
    return false;
  }

  /// Perform token refresh with mutex to prevent concurrent refreshes
  Future<_RefreshResult?> _performRefresh() async {
    // Get storage service
    StorageService storage;
    try {
      storage = Get.find<StorageService>();
    } catch (e) {
      Logger.e('RefreshInterceptor', 'StorageService not found');
      return null;
    }

    final refreshToken = storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      Logger.w('RefreshInterceptor', 'No refresh token available');
      return null;
    }

    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      Logger.d('RefreshInterceptor', 'Waiting for ongoing refresh...');
      return await _refreshCompleter!.future;
    }

    // Start new refresh
    _refreshCompleter = Completer<_RefreshResult?>();

    try {
      Logger.d('RefreshInterceptor', 'Calling /auth/refresh...');
      
      final response = await dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          extra: {
            '__skipRefresh': true,
            '__skipAuth': true,
          },
        ),
      );

      // Check for successful refresh
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final success = data['success'];
        
        if (success == true || response.statusCode == 200 || response.statusCode == 201) {
          final payload = data['data'] ?? data;
          final newAccessToken = payload['accessToken'] as String?;
          final newRefreshToken = payload['refreshToken'] as String?;

          if (newAccessToken != null && newRefreshToken != null) {
            storage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );
            
            Logger.d('RefreshInterceptor', '✅ Tokens refreshed successfully');
            
            final result = _RefreshResult(newAccessToken, newRefreshToken);
            _refreshCompleter!.complete(result);
            return result;
          }
        }
      }

      Logger.w('RefreshInterceptor', 'Refresh response invalid or failed');
      _refreshCompleter!.complete(null);
      return null;
    } catch (e) {
      Logger.e('RefreshInterceptor', 'Refresh request failed', e);
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Retry the original request with new access token
  Future<Response<dynamic>> _retryRequest(
    RequestOptions originalOptions,
    String newAccessToken,
  ) async {
    Logger.d('RefreshInterceptor', 'Retrying request: ${originalOptions.path}');

    final retryOptions = Options(
      method: originalOptions.method,
      headers: {
        ...originalOptions.headers,
        'Authorization': 'Bearer $newAccessToken',
      },
      extra: {
        ...originalOptions.extra,
        '__retry': true,
      },
    );

    return dio.request(
      originalOptions.path,
      data: originalOptions.data,
      queryParameters: originalOptions.queryParameters,
      options: retryOptions,
    );
  }

  /// Handle authentication failure - clear session and redirect to login
  void _handleAuthFailure() {
    Logger.w('RefreshInterceptor', '🔒 Auth failed, redirecting to login...');
    
    try {
      final storage = Get.find<StorageService>();
      storage.clearAuth();
    } catch (e) {
      Logger.e('RefreshInterceptor', 'Error clearing auth', e);
    }
    
    // Navigate to auth screen
    // Use a slight delay to avoid navigation conflicts
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.currentRoute != Routes.auth) {
        Get.offAllNamed(Routes.auth);
      }
    });
  }
}

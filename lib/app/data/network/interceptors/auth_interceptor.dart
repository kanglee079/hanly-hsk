import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../services/storage_service.dart';

/// Auth interceptor - adds Authorization header per-request
class AuthInterceptor extends Interceptor {
  /// Public endpoints that should NOT have Authorization header
  static const List<String> _publicPaths = [
    '/auth/request-link',
    '/auth/verify-link',
    '/auth/refresh',
    '/health',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    
    // Check if this is a public endpoint (use startsWith for exact matching)
    final isPublic = _publicPaths.any((p) => path.startsWith(p));

    // Skip auth header for public endpoints or if explicitly marked
    if (isPublic || options.extra['__skipAuth'] == true) {
      return handler.next(options);
    }

    // Get access token from storage
    try {
      final storage = Get.find<StorageService>();
      final accessToken = storage.accessToken;

      if (accessToken != null && accessToken.isNotEmpty) {
        // Set Authorization header per-request (don't mutate global headers)
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (e) {
      // StorageService not registered yet, skip
    }

    handler.next(options);
  }
}

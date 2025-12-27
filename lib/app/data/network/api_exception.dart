import 'package:dio/dio.dart';

/// API exception codes matching BE error format
enum ApiErrorCode {
  validationError,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  internalError,
  networkError,
  timeout,
  unknown,
}

/// API exception for unified error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final ApiErrorCode errorCode;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errorCode = ApiErrorCode.unknown,
    this.details,
  });

  /// Create from DioException
  factory ApiException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Kết nối tới server quá lâu. Vui lòng thử lại.',
          statusCode: null,
          errorCode: ApiErrorCode.timeout,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Không thể kết nối tới server. Kiểm tra kết nối mạng.',
          statusCode: null,
          errorCode: ApiErrorCode.networkError,
        );

      case DioExceptionType.badResponse:
        return _parseResponseError(e.response);

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Yêu cầu đã bị hủy',
          statusCode: null,
          errorCode: ApiErrorCode.unknown,
        );

      default:
        return ApiException(
          message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
          statusCode: null,
          errorCode: ApiErrorCode.unknown,
        );
    }
  }

  /// Create from BE response error
  factory ApiException.fromResponse(Map<String, dynamic> json, int? statusCode) {
    final error = json['error'] as Map<String, dynamic>?;
    final code = error?['code'] as String? ?? '';
    final message = error?['message'] as String? ?? 'Đã xảy ra lỗi';
    final details = error?['details'];

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      errorCode: _parseErrorCode(code, statusCode),
      details: details,
    );
  }

  static ApiException _parseResponseError(Response? response) {
    if (response == null) {
      return ApiException(
        message: 'Không nhận được phản hồi từ server',
        errorCode: ApiErrorCode.unknown,
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic> && data['error'] != null) {
      return ApiException.fromResponse(data, response.statusCode);
    }

    // Default messages based on status code
    final statusCode = response.statusCode;
    switch (statusCode) {
      case 400:
        return ApiException(
          message: 'Dữ liệu không hợp lệ',
          statusCode: statusCode,
          errorCode: ApiErrorCode.validationError,
        );
      case 401:
        return ApiException(
          message: 'Phiên đăng nhập đã hết hạn',
          statusCode: statusCode,
          errorCode: ApiErrorCode.unauthorized,
        );
      case 403:
        return ApiException(
          message: 'Bạn không có quyền thực hiện hành động này',
          statusCode: statusCode,
          errorCode: ApiErrorCode.forbidden,
        );
      case 404:
        return ApiException(
          message: 'Không tìm thấy dữ liệu',
          statusCode: statusCode,
          errorCode: ApiErrorCode.notFound,
        );
      case 429:
        return ApiException(
          message: 'Quá nhiều yêu cầu. Vui lòng đợi một lát.',
          statusCode: statusCode,
          errorCode: ApiErrorCode.rateLimited,
        );
      case 500:
      case 502:
      case 503:
        return ApiException(
          message: 'Lỗi server. Vui lòng thử lại sau.',
          statusCode: statusCode,
          errorCode: ApiErrorCode.internalError,
        );
      default:
        return ApiException(
          message: 'Đã xảy ra lỗi. Vui lòng thử lại.',
          statusCode: statusCode,
          errorCode: ApiErrorCode.unknown,
        );
    }
  }

  static ApiErrorCode _parseErrorCode(String code, int? statusCode) {
    switch (code.toUpperCase()) {
      case 'VALIDATION_ERROR':
        return ApiErrorCode.validationError;
      case 'UNAUTHORIZED':
        return ApiErrorCode.unauthorized;
      case 'FORBIDDEN':
        return ApiErrorCode.forbidden;
      case 'NOTFOUND':
      case 'NOT_FOUND':
        return ApiErrorCode.notFound;
      case 'RATE_LIMITED':
        return ApiErrorCode.rateLimited;
      case 'INTERNAL_ERROR':
        return ApiErrorCode.internalError;
      default:
        // Fallback to status code
        switch (statusCode) {
          case 401:
            return ApiErrorCode.unauthorized;
          case 403:
            return ApiErrorCode.forbidden;
          case 404:
            return ApiErrorCode.notFound;
          case 429:
            return ApiErrorCode.rateLimited;
          case 500:
          case 502:
          case 503:
            return ApiErrorCode.internalError;
          default:
            return ApiErrorCode.unknown;
        }
    }
  }

  /// Check if this error should trigger a logout
  bool get shouldLogout => errorCode == ApiErrorCode.unauthorized;

  /// Check if this error is a network issue
  bool get isNetworkError =>
      errorCode == ApiErrorCode.networkError || errorCode == ApiErrorCode.timeout;

  /// Check if this error means rate limiting
  bool get isRateLimited => errorCode == ApiErrorCode.rateLimited;

  @override
  String toString() => 'ApiException: $message (code: $code, status: $statusCode)';
}

/// Extension for DioException to easily convert to ApiException
extension DioExceptionX on DioException {
  ApiException toApiException() => ApiException.fromDioError(this);
}


/// Generic API Response wrapper
/// All BE endpoints return: { success: true, data: T, message?: string }
/// Error: { success: false, error: { code, message, details? } }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;
    
    if (success) {
      return ApiResponse(
        success: true,
        data: fromJsonT != null && json['data'] != null 
            ? fromJsonT(json['data']) 
            : json['data'] as T?,
        message: json['message'] as String?,
      );
    } else {
      return ApiResponse(
        success: false,
        error: json['error'] != null 
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : ApiError(code: 'UNKNOWN', message: json['message'] as String? ?? 'Unknown error'),
      );
    }
  }

  /// Check if response is successful and has data
  bool get hasData => success && data != null;

  /// Get data or throw error
  T get dataOrThrow {
    if (!success) {
      throw ApiException(error?.code ?? 'ERROR', error?.message ?? 'Request failed');
    }
    if (data == null) {
      throw ApiException('NO_DATA', 'Response has no data');
    }
    return data as T;
  }

  /// Get data or default value
  T dataOr(T defaultValue) => data ?? defaultValue;
}

/// API Error structure
class ApiError {
  final String code;
  final String message;
  final List<dynamic>? details;

  ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Unknown error',
      details: json['details'] as List<dynamic>?,
    );
  }

  @override
  String toString() => '[$code] $message';
}

/// API Exception for throwing
class ApiException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  ApiException(this.code, this.message, [this.details]);

  @override
  String toString() => '[$code] $message';
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final Pagination pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return PaginatedResponse(
      items: itemsList
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  bool get hasMore => pagination.hasNext;
  bool get isEmpty => items.isEmpty;
  int get total => pagination.total;
}

/// Pagination info
class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as int? ?? 1;
    final limit = json['limit'] as int? ?? 20;
    final total = json['total'] as int? ?? 0;
    final totalPages = json['totalPages'] as int? ?? 1;
    
    return Pagination(
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: json['hasNext'] as bool? ?? (page < totalPages),
      hasPrev: json['hasPrev'] as bool? ?? (page > 1),
    );
  }
}


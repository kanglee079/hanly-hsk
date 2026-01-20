import 'dart:async';

/// Utility to prevent duplicate/spam API requests
/// Implements deduplication, throttling, and memoization
class RequestGuard {
  static final Map<String, Future<dynamic>> _pendingRequests = {};
  static final Map<String, DateTime> _lastRequestTimes = {};
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheExpiry = {};
  
  /// Deduplicate: If same request is already in-flight, return that future
  /// instead of making a new request
  static Future<T> dedupe<T>(
    String key,
    Future<T> Function() request,
  ) async {
    // If request already in flight, await it
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key] as Future<T>;
    }
    
    // Create new request
    final future = request();
    _pendingRequests[key] = future;
    
    try {
      final result = await future;
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }
  
  /// Throttle: Prevent request if called within minInterval of last request
  static Future<T?> throttle<T>(
    String key,
    Future<T> Function() request, {
    Duration minInterval = const Duration(seconds: 5),
  }) async {
    final now = DateTime.now();
    final lastTime = _lastRequestTimes[key];
    
    if (lastTime != null && now.difference(lastTime) < minInterval) {
      // Too soon, skip this request
      return null;
    }
    
    _lastRequestTimes[key] = now;
    return request();
  }
  
  /// Memoize: Return cached result if not expired
  static Future<T> memoize<T>(
    String key,
    Future<T> Function() request, {
    Duration ttl = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final expiry = _cacheExpiry[key];
    
    // Return cache if valid and not forcing refresh
    if (!forceRefresh && expiry != null && now.isBefore(expiry)) {
      final cached = _cache[key];
      if (cached is T) return cached;
    }
    
    // Dedupe + fetch
    final result = await dedupe(key, request);
    
    // Cache result
    _cache[key] = result;
    _cacheExpiry[key] = now.add(ttl);
    
    return result;
  }
  
  /// Combined: dedupe + throttle + optional cache
  static Future<T?> guard<T>(
    String key,
    Future<T> Function() request, {
    Duration throttleInterval = const Duration(seconds: 2),
    Duration? cacheTtl,
  }) async {
    final now = DateTime.now();
    
    // Check throttle
    final lastTime = _lastRequestTimes[key];
    if (lastTime != null && now.difference(lastTime) < throttleInterval) {
      // Return cached if available
      if (cacheTtl != null) {
        final expiry = _cacheExpiry[key];
        if (expiry != null && now.isBefore(expiry)) {
          final cached = _cache[key];
          if (cached is T) return cached;
        }
      }
      return null;
    }
    
    _lastRequestTimes[key] = now;
    
    // Dedupe
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key] as Future<T>;
    }
    
    final future = request();
    _pendingRequests[key] = future;
    
    try {
      final result = await future;
      
      // Cache if ttl specified
      if (cacheTtl != null) {
        _cache[key] = result;
        _cacheExpiry[key] = now.add(cacheTtl);
      }
      
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }
  
  /// Clear all caches and pending requests
  static void clearAll() {
    _pendingRequests.clear();
    _lastRequestTimes.clear();
    _cache.clear();
    _cacheExpiry.clear();
  }
  
  /// Clear specific key
  static void clear(String key) {
    _pendingRequests.remove(key);
    _lastRequestTimes.remove(key);
    _cache.remove(key);
    _cacheExpiry.remove(key);
  }
  
  /// Check if request is currently pending
  static bool isPending(String key) => _pendingRequests.containsKey(key);
  
  /// Check if cache is valid for key
  static bool hasValidCache(String key) {
    final expiry = _cacheExpiry[key];
    return expiry != null && DateTime.now().isBefore(expiry);
  }
}

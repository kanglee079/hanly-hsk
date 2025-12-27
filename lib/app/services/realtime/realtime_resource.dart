import 'dart:async';
import 'package:get/get.dart';

typedef RealtimeFetcher<T> = Future<T> Function();
typedef RealtimeFingerprinter<T> = String Function(T value);

/// Generic realtime resource that polls on an interval and only updates Rx when data changes.
///
/// - Single source of truth: `data`
/// - Diff-based updates: via `fingerprinter`
/// - Concurrency-safe: no overlapping fetches
class RealtimeResource<T> {
  final String key;
  final Duration interval;
  final RealtimeFetcher<T> fetcher;
  final RealtimeFingerprinter<T> fingerprinter;

  final Rxn<T> data = Rxn<T>();
  final RxBool isBootstrapping = true.obs;
  final RxBool isSyncing = false.obs;
  final RxString lastError = ''.obs;
  final Rx<DateTime?> lastUpdatedAt = Rx<DateTime?>(null);

  Timer? _timer;
  bool _isFetching = false;
  String? _lastFingerprint;

  RealtimeResource({
    required this.key,
    required this.interval,
    required this.fetcher,
    required this.fingerprinter,
  });

  bool get isPolling => _timer != null;

  /// Start polling. Optionally run an immediate sync.
  void startPolling({bool immediate = true}) {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => syncNow());
    if (immediate) {
      // Fire-and-forget; no await in timer setup.
      unawaited(syncNow());
    }
  }

  /// Stop polling (keeps current data).
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Force-set data (useful for optimistic updates).
  void setData(T value) {
    data.value = value;
    _lastFingerprint = fingerprinter(value);
    lastUpdatedAt.value = DateTime.now();
    if (isBootstrapping.value) isBootstrapping.value = false;
    lastError.value = '';
  }

  /// Fetch + diff + update Rx if changed.
  Future<void> syncNow({bool force = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    isSyncing.value = true;
    lastError.value = '';

    try {
      final result = await fetcher();
      final fp = fingerprinter(result);

      final shouldUpdate = force || _lastFingerprint == null || fp != _lastFingerprint;
      if (shouldUpdate) {
        data.value = result;
        _lastFingerprint = fp;
        lastUpdatedAt.value = DateTime.now();
      }
    } catch (e) {
      lastError.value = e.toString();
    } finally {
      isSyncing.value = false;
      if (isBootstrapping.value) isBootstrapping.value = false;
      _isFetching = false;
    }
  }

  void dispose() {
    stopPolling();
  }
}



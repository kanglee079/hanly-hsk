import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/utils/logger.dart';
import '../auth_session_service.dart';
import '../connectivity_service.dart';
import 'realtime_resource.dart';

/// Central scheduler that makes the app feel "streaming":
/// - Starts polling only when: logged-in + foreground + online
/// - Stops polling in background/offline/logged-out
/// - Provides syncNow() for targeted refresh after user actions
class RealtimeSyncService extends GetxService with WidgetsBindingObserver {
  final AuthSessionService _auth = Get.find<AuthSessionService>();

  ConnectivityService? _connectivity;

  final RxBool isForeground = true.obs;
  final RxBool isOnline = true.obs;
  final RxBool isRunning = false.obs;

  final Map<String, RealtimeResource<dynamic>> _resources = <String, RealtimeResource<dynamic>>{};

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Connectivity is optional (service might not be registered).
    try {
      _connectivity = Get.find<ConnectivityService>();
      isOnline.value = _connectivity!.isOnline.value;
      ever<bool>(_connectivity!.isOnline, (v) {
        isOnline.value = v;
        _evaluate();
      });
    } catch (_) {
      // Default to online if we don't have a connectivity watcher.
      isOnline.value = true;
    }

    // Auth changes
    ever(_auth.currentUser, (_) => _evaluate());

    _evaluate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fg = state == AppLifecycleState.resumed;
    if (isForeground.value != fg) {
      isForeground.value = fg;
      _evaluate();
    }
  }

  bool get _shouldRun => _auth.isLoggedIn && isForeground.value && isOnline.value;

  void register<T>(RealtimeResource<T> resource) {
    _resources[resource.key] = resource;
    
    // If already running, start this resource immediately
    if (isRunning.value && _shouldRun) {
      final delay = Duration(milliseconds: 120 * _resources.length);
      resource.startPolling(immediate: false);
      unawaited(Future.delayed(delay, () => resource.syncNow()));
    } else {
      _evaluate();
    }
  }

  void unregister(String key) {
    final r = _resources.remove(key);
    r?.dispose();
  }

  Future<void> syncNowAll({bool force = false}) async {
    final resources = _resources.values.toList(growable: false);
    await Future.wait(resources.map((r) => r.syncNow(force: force)));
  }

  Future<void> syncNowKeys(Iterable<String> keys, {bool force = false}) async {
    final futures = <Future<void>>[];
    for (final k in keys) {
      final r = _resources[k];
      if (r != null) futures.add(r.syncNow(force: force));
    }
    await Future.wait(futures);
  }

  /// Clear all cached data in all resources (called on logout)
  void clearAllCachedData() {
    for (final r in _resources.values) {
      r.data.value = null;
    }
    Logger.i('RealtimeSyncService', '🗑️ cleared all cached data');
  }

  void _evaluate() {
    if (_shouldRun) {
      _startAll();
    } else {
      _stopAll();
    }
  }

  void _startAll() {
    if (isRunning.value) return;
    isRunning.value = true;

    // Stagger initial sync slightly to avoid a request burst.
    int i = 0;
    for (final r in _resources.values) {
      r.startPolling(immediate: false);
      final delay = Duration(milliseconds: 120 * i);
      unawaited(Future.delayed(delay, () => r.syncNow()));
      i++;
    }

    Logger.i('RealtimeSyncService', '✅ started (${_resources.length} resources)');
  }

  void _stopAll() {
    if (!isRunning.value) return;
    isRunning.value = false;

    for (final r in _resources.values) {
      r.stopPolling();
    }

    Logger.i('RealtimeSyncService', '⏸ stopped');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final r in _resources.values) {
      r.dispose();
    }
    _resources.clear();
    super.onClose();
  }
}



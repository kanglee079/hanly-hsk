import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import '../core/widgets/hm_toast.dart';

/// Service to monitor network connectivity
class ConnectivityService extends GetxService {
  final RxBool isOnline = true.obs;
  Timer? _checkTimer;

  /// Initialize and start monitoring connectivity
  Future<ConnectivityService> init() async {
    await _checkConnectivity();
    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
    return this;
  }

  /// Check if device has internet access
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      // Notify if connectivity changed
      if (isOnline.value != hasConnection) {
        isOnline.value = hasConnection;
        
        if (!hasConnection) {
          // Avoid calling Get.snackbar before GetMaterialApp is ready
          if (Get.context != null) {
            HMToast.offline();
          }
          Logger.w('ConnectivityService', 'Device is offline');
        } else {
          if (Get.context != null) {
            HMToast.info('Đã kết nối lại');
          }
          Logger.i('ConnectivityService', 'Device is back online');
        }
      }
      
      return hasConnection;
    } catch (_) {
      if (isOnline.value) {
        isOnline.value = false;
        if (Get.context != null) {
          HMToast.offline();
        }
        Logger.w('ConnectivityService', 'Device is offline');
      }
      return false;
    }
  }

  /// Force check connectivity
  Future<bool> checkNow() async {
    return await _checkConnectivity();
  }

  @override
  void onClose() {
    _checkTimer?.cancel();
    super.onClose();
  }
}


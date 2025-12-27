import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import '../core/utils/logger.dart';
import '../core/widgets/hm_toast.dart';
import '../routes/app_routes.dart';

/// Deep Link Service for handling app deep links
/// 
/// Handles:
/// - Custom scheme: hanly://word/xxx
/// - Universal links: https://hanly.com/word/xxx
/// - Cold start + warm start + resumed state
/// 
/// NOTE: Magic link auth has been deprecated in favor of Email + Password + 2FA
class DeepLinkService extends GetxService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  final RxBool isProcessingLink = false.obs;
  
  /// Initialize the service
  Future<DeepLinkService> init() async {
    _appLinks = AppLinks();
    
    // Handle initial link (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        Logger.i('DeepLinkService', 'Initial link: $initialUri');
        await _handleDeepLink(initialUri);
      }
    } catch (e) {
      Logger.e('DeepLinkService', 'Failed to get initial link', e);
    }
    
    // Handle subsequent links (warm start / resumed)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        Logger.i('DeepLinkService', 'Received link: $uri');
        _handleDeepLink(uri);
      },
      onError: (e) {
        Logger.e('DeepLinkService', 'Link stream error', e);
      },
    );
    
    return this;
  }
  
  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    // Prevent double processing
    if (isProcessingLink.value) {
      Logger.w('DeepLinkService', 'Already processing a link, ignoring');
      return;
    }
    
    isProcessingLink.value = true;
    
    try {
      if (_isWordDetailLink(uri)) {
        _handleWordDetailLink(uri);
      } else {
        Logger.w('DeepLinkService', 'Unknown deep link: $uri');
      }
    } catch (e) {
      Logger.e('DeepLinkService', 'Error handling deep link', e);
      HMToast.error('Không thể xử lý link');
    } finally {
      isProcessingLink.value = false;
    }
  }
  
  /// Check if URI is a word detail link
  bool _isWordDetailLink(Uri uri) {
    // hanly://word/xxx or https://hanly.com/word/xxx
    return uri.pathSegments.isNotEmpty && 
           (uri.pathSegments.first == 'word' || uri.pathSegments.first == 'vocab');
  }
  
  /// Handle word detail link
  void _handleWordDetailLink(Uri uri) {
    if (uri.pathSegments.length < 2) return;
    
    final vocabId = uri.pathSegments[1];
    Get.toNamed(Routes.wordDetail, arguments: {'vocabId': vocabId});
  }
  
  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}

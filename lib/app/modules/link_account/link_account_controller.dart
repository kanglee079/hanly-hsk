import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_session_service.dart';
import '../../core/utils/logger.dart';

enum LinkAccountStep { email, verify, success, error }

class LinkAccountController extends GetxController {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  
  final currentStep = LinkAccountStep.email.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final emailValid = false.obs;
  final tokenValid = false.obs;
  final pendingLinkId = ''.obs;
  final wasMerged = false.obs;
  final mergeMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_validateEmail);
    tokenController.addListener(_validateToken);
  }

  void _validateEmail() {
    final email = emailController.text.trim();
    emailValid.value = GetUtils.isEmail(email);
  }

  void _validateToken() {
    tokenValid.value = tokenController.text.trim().length >= 6;
  }

  Future<void> requestLink() async {
    if (!emailValid.value || isLoading.value) return;
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _authService.requestLinkAccount(
        emailController.text.trim(),
      );
      
      if (response != null && response.success) {
        pendingLinkId.value = response.linkId;
        currentStep.value = LinkAccountStep.verify;
        Get.snackbar(
          'Đã gửi email',
          'Kiểm tra hộp thư và nhập mã xác nhận',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Logger.e('LinkAccountController', 'requestLink error', e);
      errorMessage.value = 'Không thể gửi email. Vui lòng thử lại.';
      Get.snackbar(
        'Lỗi',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyToken() async {
    if (!tokenValid.value || isLoading.value) return;
    
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _authService.verifyLinkAccount(
        linkId: pendingLinkId.value,
        token: tokenController.text.trim(),
      );
      
      if (response != null && response.success) {
        wasMerged.value = response.merged;
        if (response.mergeResult != null) {
          mergeMessage.value = response.mergeResult!.message ?? 
            'Đã merge ${response.mergeResult!.vocabsLearned} từ vựng';
        }
        currentStep.value = LinkAccountStep.success;
      }
    } catch (e) {
      Logger.e('LinkAccountController', 'verifyToken error', e);
      errorMessage.value = 'Mã xác nhận không đúng hoặc đã hết hạn.';
      Get.snackbar(
        'Lỗi',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resendCode() {
    currentStep.value = LinkAccountStep.email;
    tokenController.clear();
  }

  void done() {
    Get.back(result: true);
  }

  @override
  void onClose() {
    emailController.dispose();
    tokenController.dispose();
    super.onClose();
  }
}

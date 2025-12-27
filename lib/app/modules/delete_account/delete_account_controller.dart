import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/decks_repo.dart';
import '../../data/repositories/learning_repo.dart';
import '../../data/repositories/me_repo.dart';
import '../../services/auth_session_service.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/strings_vi.dart';

/// Delete Account controller
class DeleteAccountController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final DecksRepo _decksRepo = Get.find<DecksRepo>();
  final MeRepo _meRepo = Get.find<MeRepo>();

  final TextEditingController confirmTextController = TextEditingController();

  // Stats
  final RxInt reviewCount = 0.obs;
  final RxInt deckCount = 0.obs;
  final RxBool isPremium = false.obs;

  // State
  final RxBool canDelete = false.obs;
  final RxBool isDeleting = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserStats();
  }

  @override
  void onClose() {
    confirmTextController.dispose();
    super.onClose();
  }

  Future<void> _loadUserStats() async {
    try {
      // Load review count from today data
      final today = await _learningRepo.getToday();
      reviewCount.value = (today.masteredCount) + (today.reviewCount);

      // Load deck count
      final decks = await _decksRepo.getDecks();
      deckCount.value = decks.length;

      // Check premium status
      isPremium.value = _authService.currentUser.value?.isPremium ?? false;
    } catch (e) {
      // Silent fail, use default values
    }
  }

  void validateInput() {
    final text = confirmTextController.text.trim().toUpperCase();
    canDelete.value = text == 'DELETE';
  }

  /// Request soft deletion (7 days grace period)
  Future<void> confirmDelete() async {
    if (!canDelete.value) return;

    isDeleting.value = true;
    try {
      // Use soft delete API
      final response = await _meRepo.requestDeletion(
        reason: 'User requested deletion',
      );
      
      // Show success message with scheduled date
      HMToast.success(response.message);
      
      // Refresh user data to get updated status
      await _authService.fetchCurrentUser();
      
      // Navigate back
      Get.back();
      
    } catch (e) {
      // Fallback to hard delete if soft delete fails
      final success = await _authService.deleteAccount();
      if (success) {
        HMToast.success(S.deleteAccountSuccess);
      } else {
        HMToast.error(S.errorUnknown);
      }
    } finally {
      isDeleting.value = false;
    }
  }
  
  /// Cancel pending deletion
  Future<void> cancelDeletion() async {
    try {
      await _meRepo.cancelDeletion();
      await _authService.fetchCurrentUser();
      HMToast.success('Đã hủy yêu cầu xóa tài khoản');
    } catch (e) {
      HMToast.error(S.errorUnknown);
    }
  }
}

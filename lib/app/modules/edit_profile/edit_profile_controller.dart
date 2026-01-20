import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/me_repo.dart';
import '../../services/auth_session_service.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/utils/logger.dart';

class EditProfileController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  final ImagePicker _picker = ImagePicker();

  final displayNameController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final Rx<File?> selectedImage = Rx<File?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final user = _authService.currentUser.value;
    displayNameController.text = user?.displayName ?? user?.profile?.displayName ?? '';
  }

  @override
  void onClose() {
    displayNameController.dispose();
    super.onClose();
  }

  /// Pick image from gallery
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        // Auto-upload
        await uploadAvatar();
      }
    } catch (e) {
      Logger.e('EditProfileController', 'Error picking image', e);
      HMToast.error('Không thể chọn ảnh');
    }
  }

  /// Upload avatar to server
  Future<void> uploadAvatar() async {
    if (selectedImage.value == null) return;

    isUploadingAvatar.value = true;

    try {
      final avatarUrl = await _meRepo.uploadAvatar(selectedImage.value!);
      
      // Update local user data
      await _authService.fetchCurrentUser();
      
      HMToast.success('Cập nhật ảnh đại diện thành công!');
      Logger.d('EditProfileController', 'Avatar uploaded: $avatarUrl');
    } catch (e) {
      Logger.e('EditProfileController', 'Error uploading avatar', e);
      HMToast.error('Không thể tải ảnh lên. Vui lòng thử lại.');
      selectedImage.value = null;
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  /// Save profile changes
  Future<void> saveProfile() async {
    final displayName = displayNameController.text.trim();

    if (displayName.isEmpty) {
      HMToast.error('Vui lòng nhập tên hiển thị');
      return;
    }

    isLoading.value = true;

    try {
      await _meRepo.updateProfile({'displayName': displayName});
      
      // Refresh user data
      await _authService.fetchCurrentUser();
      
      HMToast.success('Cập nhật thông tin thành công!');
      Get.back();
    } catch (e) {
      Logger.e('EditProfileController', 'Error saving profile', e);
      HMToast.error('Không thể cập nhật thông tin');
    } finally {
      isLoading.value = false;
    }
  }
}

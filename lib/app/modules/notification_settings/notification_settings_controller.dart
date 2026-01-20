import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/notification_settings_model.dart';
import '../../data/repositories/me_repo.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/utils/logger.dart';

class NotificationSettingsController extends GetxController {
  final MeRepo _meRepo = Get.find<MeRepo>();

  final Rxn<NotificationSettingsModel> settings = Rxn<NotificationSettingsModel>();
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      settings.value = await _meRepo.getNotificationSettings();
    } catch (e) {
      Logger.e('NotificationSettingsController', 'Error loading settings', e);
      // Use defaults if loading fails
      settings.value = NotificationSettingsModel();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleEnabled(bool value) async {
    if (settings.value == null) return;
    
    final updated = settings.value!.copyWith(enabled: value);
    await _saveSettings(updated);
  }

  Future<void> toggleType(String type, bool value) async {
    if (settings.value == null) return;

    NotificationTypesModel types;
    switch (type) {
      case 'dailyReminder':
        types = settings.value!.types.copyWith(dailyReminder: value);
        break;
      case 'streakReminder':
        types = settings.value!.types.copyWith(streakReminder: value);
        break;
      case 'newContent':
        types = settings.value!.types.copyWith(newContent: value);
        break;
      case 'achievements':
        types = settings.value!.types.copyWith(achievements: value);
        break;
      default:
        return;
    }

    final updated = settings.value!.copyWith(types: types);
    await _saveSettings(updated);
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    if (settings.value == null) return;

    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final updated = settings.value!.copyWith(reminderTime: timeStr);
    await _saveSettings(updated);
  }

  Future<void> _saveSettings(NotificationSettingsModel updated) async {
    isSaving.value = true;

    try {
      final saved = await _meRepo.updateNotificationSettings(updated);
      settings.value = saved;
      HMToast.success('Đã cập nhật cài đặt');
    } catch (e) {
      Logger.e('NotificationSettingsController', 'Error saving settings', e);
      HMToast.error('Không thể lưu cài đặt');
      // Revert to previous
      loadSettings();
    } finally {
      isSaving.value = false;
    }
  }

  TimeOfDay? get reminderTime {
    if (settings.value == null) return null;
    try {
      final parts = settings.value!.reminderTime.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  String get reminderTimeDisplay {
    final time = reminderTime;
    if (time == null) return '20:00';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import '../models/notification_settings_model.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// User/Me repository
class MeRepo {
  final ApiClient _api;

  MeRepo(this._api);

  /// Get current user with profile
  Future<UserModel> getMe() async {
    final response = await _api.get(ApiEndpoints.me);
    final data = response.data['data'] ?? response.data;
    return UserModel.fromJson(data);
  }

  /// Submit onboarding data (new endpoint)
  Future<ProfileModel> submitOnboarding({
    required String displayName,
    required String goalType,
    required String currentLevel,
    required int dailyMinutesTarget,
    required int dailyNewLimit,
    required Map<String, double> focusWeights,
    bool notificationsEnabled = false,
    String? reminderTime,
  }) async {
    final response = await _api.post(
      ApiEndpoints.meOnboarding,
      data: {
        'displayName': displayName,
        'goalType': goalType,
        'currentLevel': currentLevel,
        'dailyMinutesTarget': dailyMinutesTarget,
        'dailyNewLimit': dailyNewLimit,
        'focusWeights': focusWeights,
        'notificationsEnabled': notificationsEnabled,
        if (reminderTime != null) 'reminderTime': reminderTime,
      },
    );
    final data = response.data['data'] ?? response.data;
    return ProfileModel.fromJson(data);
  }

  /// Update profile (partial update)
  Future<ProfileModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _api.put(ApiEndpoints.meProfile, data: profileData);
    final data = response.data['data'] ?? response.data;
    return ProfileModel.fromJson(data);
  }

  /// Get user stats
  Future<UserStats> getStats() async {
    final response = await _api.get(ApiEndpoints.meStats);
    final data = response.data['data'] ?? response.data;
    return UserStats.fromJson(data);
  }

  /// Get achievements
  Future<List<Achievement>> getAchievements() async {
    final response = await _api.get(ApiEndpoints.meAchievements);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((e) => Achievement.fromJson(e)).toList();
  }

  /// Get learning calendar (3 months)
  Future<List<CalendarDay>> getCalendar() async {
    final response = await _api.get(ApiEndpoints.meCalendar);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((e) => CalendarDay.fromJson(e)).toList();
  }

  /// Delete account (immediate - hard delete)
  Future<void> deleteAccount() async {
    await _api.delete(ApiEndpoints.me);
  }

  /// Request account deletion (soft delete - 7 days)
  Future<DeletionResponse> requestDeletion({String? reason}) async {
    final response = await _api.post(
      ApiEndpoints.meRequestDeletion,
      data: {if (reason != null) 'reason': reason},
    );
    final data = response.data['data'] ?? response.data;
    return DeletionResponse.fromJson(data);
  }

  /// Cancel account deletion request
  Future<void> cancelDeletion() async {
    await _api.post(ApiEndpoints.meCancelDeletion);
  }

  /// Get notification settings
  Future<NotificationSettingsModel> getNotificationSettings() async {
    final response = await _api.get(ApiEndpoints.meNotifications);
    return NotificationSettingsModel.fromJson(response.data);
  }

  /// Update notification settings
  Future<NotificationSettingsModel> updateNotificationSettings(
    NotificationSettingsModel settings,
  ) async {
    final response = await _api.post(
      ApiEndpoints.meNotifications,
      data: settings.toJson(),
    );
    return NotificationSettingsModel.fromJson(response.data);
  }

  /// Upload avatar with progress tracking
  /// [onProgress] callback receives value from 0.0 to 1.0
  Future<String> uploadAvatar(
    File imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final response = await _api.dio.post(
      ApiEndpoints.meAvatar,
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );

    final data = response.data['data'] ?? response.data;
    final avatarUrl = data['avatarUrl'];

    if (avatarUrl == null || avatarUrl.toString().isEmpty) {
      throw Exception('Upload failed: No avatar URL returned');
    }

    return avatarUrl as String;
  }
}

/// Deletion response model
class DeletionResponse {
  final String message;
  final DateTime deletionScheduledAt;
  final int daysRemaining;

  DeletionResponse({
    required this.message,
    required this.deletionScheduledAt,
    required this.daysRemaining,
  });

  factory DeletionResponse.fromJson(Map<String, dynamic> json) {
    return DeletionResponse(
      message: json['message'] as String? ?? '',
      deletionScheduledAt: DateTime.parse(
        json['deletionScheduledAt'] as String,
      ),
      daysRemaining: json['daysRemaining'] as int? ?? 7,
    );
  }
}

/// User stats model
class UserStats {
  final int totalWords;
  final int masteredWords;
  final int learningWords;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final double averageAccuracy;
  final int totalReviews;
  final int perfectSessions;

  UserStats({
    this.totalWords = 0,
    this.masteredWords = 0,
    this.learningWords = 0,
    this.totalMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalSessions = 0,
    this.averageAccuracy = 0,
    this.totalReviews = 0,
    this.perfectSessions = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalWords: json['totalWords'] as int? ?? 0,
      masteredWords: json['masteredWords'] as int? ?? 0,
      learningWords: json['learningWords'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      perfectSessions: json['perfectSessions'] as int? ?? 0,
    );
  }
}

/// Achievement model
class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int? progress;
  final int? target;

  Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
    this.progress,
    this.target,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏆',
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int?,
      target: json['target'] as int?,
    );
  }

  double get progressPercent {
    if (target == null || target == 0) return unlocked ? 1.0 : 0.0;
    return (progress ?? 0) / target!;
  }
}

/// Calendar day model
class CalendarDay {
  final DateTime date;
  final int minutes;
  final int newCount;
  final int reviewCount;
  final double accuracy;
  final bool completed; // Met daily goal

  CalendarDay({
    required this.date,
    this.minutes = 0,
    this.newCount = 0,
    this.reviewCount = 0,
    this.accuracy = 0,
    this.completed = false,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: DateTime.parse(json['date'] as String),
      minutes: json['minutes'] as int? ?? 0,
      newCount: json['newCount'] as int? ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

/// Notification settings model
class NotificationSettingsModel {
  final bool enabled;
  final String reminderTime;
  final String timezone;
  final NotificationTypesModel types;

  NotificationSettingsModel({
    this.enabled = true,
    this.reminderTime = '20:00',
    this.timezone = 'Asia/Ho_Chi_Minh',
    NotificationTypesModel? types,
  }) : types = types ?? NotificationTypesModel();

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return NotificationSettingsModel(
      enabled: data['enabled'] as bool? ?? true,
      reminderTime: data['reminderTime'] as String? ?? '20:00',
      timezone: data['timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
      types: data['types'] != null
          ? NotificationTypesModel.fromJson(
              data['types'] as Map<String, dynamic>,
            )
          : NotificationTypesModel(),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'reminderTime': reminderTime,
    'timezone': timezone,
    'types': types.toJson(),
  };

  NotificationSettingsModel copyWith({
    bool? enabled,
    String? reminderTime,
    String? timezone,
    NotificationTypesModel? types,
  }) {
    return NotificationSettingsModel(
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
      timezone: timezone ?? this.timezone,
      types: types ?? this.types,
    );
  }
}

/// Notification types settings
class NotificationTypesModel {
  final bool dailyReminder;
  final bool streakReminder;
  final bool newContent;
  final bool achievements;

  NotificationTypesModel({
    this.dailyReminder = true,
    this.streakReminder = true,
    this.newContent = false,
    this.achievements = true,
  });

  factory NotificationTypesModel.fromJson(Map<String, dynamic> json) {
    return NotificationTypesModel(
      dailyReminder: json['dailyReminder'] as bool? ?? true,
      streakReminder: json['streakReminder'] as bool? ?? true,
      newContent: json['newContent'] as bool? ?? false,
      achievements: json['achievements'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'dailyReminder': dailyReminder,
    'streakReminder': streakReminder,
    'newContent': newContent,
    'achievements': achievements,
  };

  NotificationTypesModel copyWith({
    bool? dailyReminder,
    bool? streakReminder,
    bool? newContent,
    bool? achievements,
  }) {
    return NotificationTypesModel(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      streakReminder: streakReminder ?? this.streakReminder,
      newContent: newContent ?? this.newContent,
      achievements: achievements ?? this.achievements,
    );
  }
}

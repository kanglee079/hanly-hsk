/// User model
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String status;
  final bool isPremium;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final ProfileModel? profile;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.status = 'active',
    this.isPremium = false,
    this.twoFactorEnabled = false,
    required this.createdAt,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested response format from /me endpoint
    final userData = json['user'] as Map<String, dynamic>? ?? json;
    final profileData = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: userData['id'] as String? ?? userData['_id'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      displayName: userData['displayName'] as String?,
      avatarUrl: userData['avatarUrl'] as String?,
      status: userData['status'] as String? ?? 'active',
      isPremium: userData['isPremium'] as bool? ?? false,
      twoFactorEnabled: userData['twoFactorEnabled'] as bool? ?? false,
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'] as String)
          : DateTime.now(),
      profile: profileData != null ? ProfileModel.fromJson(profileData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'status': status,
      'isPremium': isPremium,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }

  bool get hasProfile => profile != null && profile!.onboardingCompleted;

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? status,
    bool? isPremium,
    bool? twoFactorEnabled,
    DateTime? createdAt,
    ProfileModel? profile,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      createdAt: createdAt ?? this.createdAt,
      profile: profile ?? this.profile,
    );
  }
}

/// User profile model - matches BE schema
class ProfileModel {
  // Onboarding info
  final String? displayName;
  final bool onboardingCompleted;

  // Learning path
  final GoalType? goalType;
  final String? currentLevel; // HSK1-6 (level user already knows)
  final String? targetLevel; // HSK1-6 (target level)

  // Daily settings
  final int? dailyMinutesTarget;
  final int? dailyNewLimit;
  final String? reviewIntensity; // light, normal, intensive

  // Focus weights
  final FocusWeights? focusWeights;

  // Timezone
  final String? timezone;

  // Notifications
  final bool notificationsEnabled;
  final String? reminderTime; // "HH:mm"

  // Premium status
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int streakProtectionRemaining; // Premium feature: protect streak

  ProfileModel({
    this.displayName,
    this.onboardingCompleted = false,
    this.goalType,
    this.currentLevel,
    this.targetLevel,
    this.dailyMinutesTarget,
    this.dailyNewLimit,
    this.reviewIntensity,
    this.focusWeights,
    this.timezone,
    this.notificationsEnabled = false,
    this.reminderTime,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.streakProtectionRemaining = 0,
  });

  /// Check if premium is active (not expired)
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiresAt == null) return isPremium; // Lifetime
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      displayName: json['displayName'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      goalType: json['goalType'] != null
          ? _parseGoalType(json['goalType'] as String)
          : null,
      currentLevel: json['currentLevel'] as String?,
      targetLevel: json['targetLevel'] as String?,
      dailyMinutesTarget: json['dailyMinutesTarget'] as int?,
      dailyNewLimit: json['dailyNewLimit'] as int?,
      reviewIntensity: json['reviewIntensity'] as String?,
      focusWeights: json['focusWeights'] != null
          ? FocusWeights.fromJson(json['focusWeights'] as Map<String, dynamic>)
          : null,
      timezone: json['timezone'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      premiumExpiresAt: json['premiumExpiresAt'] != null 
          ? DateTime.tryParse(json['premiumExpiresAt'] as String) 
          : null,
      streakProtectionRemaining: json['streakProtectionRemaining'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (displayName != null) 'displayName': displayName,
      'onboardingCompleted': onboardingCompleted,
      if (goalType != null) 'goalType': goalType!.apiValue,
      if (currentLevel != null) 'currentLevel': currentLevel,
      if (targetLevel != null) 'targetLevel': targetLevel,
      if (dailyMinutesTarget != null) 'dailyMinutesTarget': dailyMinutesTarget,
      if (dailyNewLimit != null) 'dailyNewLimit': dailyNewLimit,
      if (reviewIntensity != null) 'reviewIntensity': reviewIntensity,
      if (focusWeights != null) 'focusWeights': focusWeights!.toJson(),
      if (timezone != null) 'timezone': timezone,
      'notificationsEnabled': notificationsEnabled,
      if (reminderTime != null) 'reminderTime': reminderTime,
      'isPremium': isPremium,
      if (premiumExpiresAt != null) 'premiumExpiresAt': premiumExpiresAt!.toIso8601String(),
      'streakProtectionRemaining': streakProtectionRemaining,
    };
  }

  static GoalType? _parseGoalType(String value) {
    switch (value) {
      case 'hsk_exam':
        return GoalType.hskExam;
      case 'conversation':
        return GoalType.conversation;
      case 'both':
        return GoalType.both;
      default:
        return null;
    }
  }

  int get currentLevelInt {
    if (currentLevel == null) return 1;
    return int.tryParse(currentLevel!.replaceAll('HSK', '')) ?? 1;
  }

  ProfileModel copyWith({
    String? displayName,
    bool? onboardingCompleted,
    GoalType? goalType,
    String? currentLevel,
    String? targetLevel,
    int? dailyMinutesTarget,
    int? dailyNewLimit,
    String? reviewIntensity,
    FocusWeights? focusWeights,
    String? timezone,
    bool? notificationsEnabled,
    String? reminderTime,
  }) {
    return ProfileModel(
      displayName: displayName ?? this.displayName,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      goalType: goalType ?? this.goalType,
      currentLevel: currentLevel ?? this.currentLevel,
      targetLevel: targetLevel ?? this.targetLevel,
      dailyMinutesTarget: dailyMinutesTarget ?? this.dailyMinutesTarget,
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      reviewIntensity: reviewIntensity ?? this.reviewIntensity,
      focusWeights: focusWeights ?? this.focusWeights,
      timezone: timezone ?? this.timezone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

/// Focus weights for learning path
class FocusWeights {
  final double listening;
  final double hanzi;
  final double meaning;

  FocusWeights({
    this.listening = 0.33,
    this.hanzi = 0.34,
    this.meaning = 0.33,
  });

  factory FocusWeights.fromJson(Map<String, dynamic> json) {
    return FocusWeights(
      listening: (json['listening'] as num?)?.toDouble() ?? 0.33,
      hanzi: (json['hanzi'] as num?)?.toDouble() ?? 0.34,
      meaning: (json['meaning'] as num?)?.toDouble() ?? 0.33,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listening': listening,
      'hanzi': hanzi,
      'meaning': meaning,
    };
  }

  FocusWeights copyWith({
    double? listening,
    double? hanzi,
    double? meaning,
  }) {
    return FocusWeights(
      listening: listening ?? this.listening,
      hanzi: hanzi ?? this.hanzi,
      meaning: meaning ?? this.meaning,
    );
  }
}

/// Goal type enum - matches BE values
enum GoalType {
  hskExam,
  conversation,
  both;

  String get apiValue {
    switch (this) {
      case GoalType.hskExam:
        return 'hsk_exam';
      case GoalType.conversation:
        return 'conversation';
      case GoalType.both:
        return 'both';
    }
  }

  String get displayName {
    switch (this) {
      case GoalType.hskExam:
        return 'Thi HSK';
      case GoalType.conversation:
        return 'Giao tiếp';
      case GoalType.both:
        return 'Cả hai';
    }
  }
}

/// Focus skill enum (for backward compatibility)
enum FocusSkill { listening, hanzi }

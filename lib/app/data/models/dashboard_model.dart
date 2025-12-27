import 'today_model.dart';
import 'study_modes_model.dart';
import 'user_model.dart';

/// Dashboard response from GET /dashboard
/// Aggregates: me, today, studyModes in one request
class DashboardModel {
  final DashboardMeData me;
  final TodayModel today;
  final StudyModesData? studyModes;

  DashboardModel({
    required this.me,
    required this.today,
    this.studyModes,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      me: DashboardMeData.fromJson(json['me'] as Map<String, dynamic>? ?? {}),
      today: TodayModel.fromJson(json['today'] as Map<String, dynamic>? ?? {}),
      studyModes: json['studyModes'] != null
          ? StudyModesData.fromJson(json['studyModes'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Me data embedded in dashboard
class DashboardMeData {
  final UserModel? user;
  final ProfileModel? profile;
  final UserStatsModel? stats;

  DashboardMeData({
    this.user,
    this.profile,
    this.stats,
  });

  factory DashboardMeData.fromJson(Map<String, dynamic> json) {
    return DashboardMeData(
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      profile: json['profile'] != null
          ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] != null
          ? UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// User stats model
class UserStatsModel {
  final int totalLearned;
  final int totalMastered;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutes;
  final double averageAccuracy;
  final Map<String, int>? levelBreakdown;

  UserStatsModel({
    this.totalLearned = 0,
    this.totalMastered = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutes = 0,
    this.averageAccuracy = 0,
    this.levelBreakdown,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      totalLearned: json['totalLearned'] as int? ?? 0,
      totalMastered: json['totalMastered'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0,
      levelBreakdown: json['levelBreakdown'] != null
          ? Map<String, int>.from(json['levelBreakdown'] as Map)
          : null,
    );
  }
}

/// Study modes data from dashboard
class StudyModesData {
  final String date;
  final int streak;
  final bool isPremium;
  final QuickReviewModel? quickReview;
  final List<StudyModeModel> modes;

  StudyModesData({
    required this.date,
    this.streak = 0,
    this.isPremium = false,
    this.quickReview,
    this.modes = const [],
  });

  factory StudyModesData.fromJson(Map<String, dynamic> json) {
    final modesList = json['studyModes'] as List<dynamic>? ?? [];
    return StudyModesData(
      date: json['date'] as String? ?? '',
      streak: json['streak'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      quickReview: json['quickReview'] != null
          ? QuickReviewModel.fromJson(json['quickReview'] as Map<String, dynamic>)
          : null,
      modes: modesList
          .map((e) => StudyModeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Forecast response from GET /today/forecast
class ForecastModel {
  final String dateKey;
  final List<ForecastDay> days;
  final int tomorrowReviewCount;

  ForecastModel({
    required this.dateKey,
    this.days = const [],
    this.tomorrowReviewCount = 0,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final daysList = json['days'] as List<dynamic>? ?? [];
    final days = daysList
        .map((e) => ForecastDay.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return ForecastModel(
      dateKey: json['dateKey'] as String? ?? '',
      days: days,
      tomorrowReviewCount: days.isNotEmpty ? days.first.reviewCount : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'days': days.map((e) => e.toJson()).toList(),
      'tomorrowReviewCount': tomorrowReviewCount,
    };
  }
}

/// Single forecast day
class ForecastDay {
  final String dateKey;
  final int reviewCount;

  ForecastDay({
    required this.dateKey,
    this.reviewCount = 0,
  });

  factory ForecastDay.fromJson(Map<String, dynamic> json) {
    return ForecastDay(
      dateKey: json['dateKey'] as String? ?? '',
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'reviewCount': reviewCount,
    };
  }
}

/// Learned today response from GET /today/learned-today
class LearnedTodayModel {
  final String dateKey;
  final int count;
  final List<LearnedTodayItem> items;

  LearnedTodayModel({
    required this.dateKey,
    this.count = 0,
    this.items = const [],
  });

  factory LearnedTodayModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return LearnedTodayModel(
      dateKey: json['dateKey'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      items: itemsList
          .map((e) => LearnedTodayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'count': count,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

/// Single learned today item (lightweight vocab)
class LearnedTodayItem {
  final String id;
  final String word;
  final String pinyin;
  final String meaningVi;
  final String? level;
  final String? audioUrl;
  final List<String>? images;

  LearnedTodayItem({
    required this.id,
    required this.word,
    required this.pinyin,
    required this.meaningVi,
    this.level,
    this.audioUrl,
    this.images,
  });

  factory LearnedTodayItem.fromJson(Map<String, dynamic> json) {
    return LearnedTodayItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      meaningVi: json['meaning_vi'] as String? ?? json['meaningVi'] as String? ?? '',
      level: json['level'] as String?,
      audioUrl: json['audio_url'] as String? ?? json['audioUrl'] as String?,
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'pinyin': pinyin,
      'meaningVi': meaningVi,
      'level': level,
      'audioUrl': audioUrl,
      'images': images,
    };
  }
}

/// Daily pick response from GET /vocabs/daily-pick
class DailyPickModel {
  final String dateKey;
  final LearnedTodayItem vocab;

  DailyPickModel({
    required this.dateKey,
    required this.vocab,
  });

  factory DailyPickModel.fromJson(Map<String, dynamic> json) {
    return DailyPickModel(
      dateKey: json['dateKey'] as String? ?? '',
      vocab: LearnedTodayItem.fromJson(json['vocab'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'vocab': vocab.toJson(),
    };
  }
}


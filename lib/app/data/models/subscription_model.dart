/// Subscription model for Premium system
class SubscriptionModel {
  final bool isPremium;
  final String plan; // "free" | "monthly" | "yearly" | "lifetime"
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
  final List<String> features;
  final SubscriptionLimits limits;

  SubscriptionModel({
    this.isPremium = false,
    this.plan = 'free',
    this.startedAt,
    this.expiresAt,
    this.autoRenew = false,
    this.features = const [],
    SubscriptionLimits? limits,
  }) : limits = limits ?? SubscriptionLimits();

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      isPremium: json['isPremium'] as bool? ?? false,
      plan: json['plan'] as String? ?? 'free',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      autoRenew: json['autoRenew'] as bool? ?? false,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      limits: json['limits'] != null
          ? SubscriptionLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : SubscriptionLimits(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isPremium': isPremium,
        'plan': plan,
        'startedAt': startedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'autoRenew': autoRenew,
        'features': features,
        'limits': limits.toJson(),
      };

  /// Check if subscription is active
  bool get isActive {
    if (!isPremium) return false;
    if (plan == 'lifetime') return true;
    if (expiresAt == null) return isPremium;
    return expiresAt!.isAfter(DateTime.now());
  }

  /// Days remaining in subscription
  int get daysRemaining {
    if (!isActive) return 0;
    if (plan == 'lifetime') return -1; // Unlimited
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }
}

/// Subscription limits
class SubscriptionLimits {
  final int flashcardsPerDay; // -1 = unlimited
  final int comprehensivePerDay;
  final int examAttemptsPerDay;
  final int gamePerDay;

  SubscriptionLimits({
    this.flashcardsPerDay = 10,
    this.comprehensivePerDay = 0,
    this.examAttemptsPerDay = 1,
    this.gamePerDay = 3,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) {
    return SubscriptionLimits(
      flashcardsPerDay: json['flashcardsPerDay'] as int? ?? 10,
      comprehensivePerDay: json['comprehensivePerDay'] as int? ?? 0,
      examAttemptsPerDay: json['examAttemptsPerDay'] as int? ?? 1,
      gamePerDay: json['gamePerDay'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
        'flashcardsPerDay': flashcardsPerDay,
        'comprehensivePerDay': comprehensivePerDay,
        'examAttemptsPerDay': examAttemptsPerDay,
        'gamePerDay': gamePerDay,
      };

  bool get hasUnlimitedFlashcards => flashcardsPerDay == -1;
  bool get hasComprehensive => comprehensivePerDay != 0;
}

/// Premium plan model
class PremiumPlanModel {
  final String id;
  final String name;
  final int price;
  final String currency;
  final String period;
  final int periodCount;
  final int? discount;
  final int? originalPrice;
  final List<String> features;
  final bool popular;

  PremiumPlanModel({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'VND',
    required this.period,
    this.periodCount = 1,
    this.discount,
    this.originalPrice,
    this.features = const [],
    this.popular = false,
  });

  factory PremiumPlanModel.fromJson(Map<String, dynamic> json) {
    return PremiumPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      period: json['period'] as String? ?? 'month',
      periodCount: json['periodCount'] as int? ?? 1,
      discount: json['discount'] as int?,
      originalPrice: json['originalPrice'] as int?,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      popular: json['popular'] as bool? ?? false,
    );
  }

  /// Format price with currency
  String get formattedPrice {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }

  /// Format original price with strikethrough
  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    final formatted = originalPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}


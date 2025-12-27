/// App limits for Free vs Premium tiers
class AppLimits {
  AppLimits._();

  // ==================== FREE TIER ====================
  /// Từ mới tối đa/ngày cho Free users (đủ để học tốt)
  static const int freeDailyNewWords = 30;
  
  /// Số lần luyện phát âm/ngày cho Free users
  static const int freePronunciationDaily = 10;
  
  /// HSK levels có thể tải offline cho Free users
  static const List<String> freeOfflineLevels = ['HSK1', 'HSK2'];
  
  /// Game modes cho Free users
  static const List<String> freeGameModes = ['speed30s', 'matching'];
  
  /// Số ngày thống kê hiển thị cho Free users
  static const int freeStatsDays = 7;
  
  /// Số achievements cơ bản cho Free users
  static const int freeAchievementsCount = 20;
  
  /// Số devices cho Free users
  static const int freeDevices = 2;
  
  /// Số themes cho Free users
  static const int freeThemes = 2;

  // ==================== PREMIUM TIER ====================
  /// Từ mới tối đa/ngày cho Premium users (không giới hạn thực tế)
  static const int premiumDailyNewWords = 999;
  
  /// Số lần luyện phát âm/ngày cho Premium users (không giới hạn)
  static const int premiumPronunciationDaily = 999;
  
  /// HSK levels có thể tải offline cho Premium users
  static const List<String> premiumOfflineLevels = [
    'HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'
  ];
  
  /// Game modes cho Premium users
  static const List<String> premiumGameModes = [
    'speed30s', 'matching', 'listening', 'writing', 'pronunciation'
  ];
  
  /// Số ngày thống kê hiển thị cho Premium users (không giới hạn)
  static const int premiumStatsDays = 365;
  
  /// Số achievements cho Premium users (bao gồm exclusive)
  static const int premiumAchievementsCount = 50;
  
  /// Số devices cho Premium users (không giới hạn)
  static const int premiumDevices = 999;
  
  /// Số themes cho Premium users
  static const int premiumThemes = 10;
  
  /// Streak protection cho Premium users (lần/tháng)
  static const int premiumStreakProtection = 3;

  // ==================== HELPER METHODS ====================
  /// Get daily new words limit based on premium status
  static int getDailyNewWordsLimit(bool isPremium) {
    return isPremium ? premiumDailyNewWords : freeDailyNewWords;
  }
  
  /// Get pronunciation daily limit based on premium status
  static int getPronunciationLimit(bool isPremium) {
    return isPremium ? premiumPronunciationDaily : freePronunciationDaily;
  }
  
  /// Get available offline levels based on premium status
  static List<String> getOfflineLevels(bool isPremium) {
    return isPremium ? premiumOfflineLevels : freeOfflineLevels;
  }
  
  /// Get available game modes based on premium status
  static List<String> getGameModes(bool isPremium) {
    return isPremium ? premiumGameModes : freeGameModes;
  }
  
  /// Check if a specific HSK level can be downloaded offline
  static bool canDownloadLevel(String level, bool isPremium) {
    if (isPremium) return true;
    return freeOfflineLevels.contains(level);
  }
  
  /// Check if a specific game mode is available
  static bool canPlayGameMode(String mode, bool isPremium) {
    if (isPremium) return true;
    return freeGameModes.contains(mode);
  }
}

/// Premium pricing (VND)
class PremiumPricing {
  PremiumPricing._();
  
  static const int weekly = 29000;      // ~4,100₫/ngày
  static const int monthly = 79000;     // ~2,600₫/ngày
  static const int yearly = 499000;     // ~1,400₫/ngày ⭐ Best value
  static const int lifetime = 999000;   // Mua 1 lần
  
  /// Format price with currency
  static String formatPrice(int price) {
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}₫';
  }
}


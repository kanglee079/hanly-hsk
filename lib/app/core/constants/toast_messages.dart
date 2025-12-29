/// Standardized toast messages for the entire app
/// All user-facing messages should be defined here for consistency
class ToastMessages {
  ToastMessages._();

  // ==================== FLASHCARD ====================
  static const String flashcardNoNewWords = 
      'Bạn chưa có từ mới để học. Hãy học từ mới trước để sử dụng Flashcard!';
  static const String flashcardNoVocabsAvailable = 
      'Hiện tại không có từ nào khả dụng. Hãy học thêm từ mới hoặc đợi đến hạn ôn tập!';
  static const String flashcardLoadError = 
      'Không thể tải từ vựng. Vui lòng kiểm tra kết nối mạng và thử lại.';
  static const String flashcardNoAudio = 
      'Không có audio cho từ này.';
  static const String flashcardNoSlowAudio = 
      'Không có audio chậm cho từ này.';

  // ==================== LEARNING / PRACTICE ====================
  static const String practiceNoVocabsToReview = 
      'Không có từ nào cần ôn tập lúc này. Hãy học thêm từ mới!';
  static const String practiceNoNewWordsToday = 
      'Bạn đã đạt giới hạn từ mới hôm nay. Hãy quay lại vào ngày mai hoặc nâng cấp Premium!';
  static const String practiceNoNewWordsAvailable = 
      'Không còn từ mới để học hôm nay. Hãy quay lại vào ngày mai!';
  static const String practiceLoadMoreError = 
      'Không thể tải thêm từ. Vui lòng kiểm tra kết nối và thử lại.';
  static const String practiceAudioUnavailable = 
      'Audio không khả dụng cho từ này.';
  static const String practiceExampleAudioUpdating = 
      'Audio câu ví dụ đang được cập nhật.';
  static const String practiceTtsNotReady = 
      'Tính năng đọc chưa sẵn sàng. Vui lòng thử lại sau.';
  static const String practiceNoWritingVocabs = 
      'Không có từ vựng để luyện viết. Hãy học thêm từ mới!';

  // ==================== REVIEW OVERLOAD / LOCKS ====================
  static String reviewOverload(int count) => 
      'Có $count từ cần ôn tập! Hãy ôn tập để tiếp tục học từ mới.';
  static String masteryRequired(int wordsToMaster) => 
      'Cần master $wordsToMaster từ đã học trước khi học từ mới. Hãy ôn tập để master các từ này!';
  static const String newWordsLocked = 
      'Chưa thể học từ mới. Hãy hoàn thành ôn tập trước.';

  // ==================== HSK EXAM ====================
  static const String examSubmitError = 
      'Không thể nộp bài. Vui lòng kiểm tra kết nối và thử lại.';
  static const String examHistoryLoadError = 
      'Không thể tải lịch sử thi. Vui lòng thử lại.';
  static const String examTestsLoadError = 
      'Không thể tải danh sách đề thi. Vui lòng thử lại.';

  // ==================== PREMIUM ====================
  static const String premiumAlreadyMember = 
      'Bạn đã là thành viên Premium!';
  static const String premiumSelectPlan = 
      'Vui lòng chọn gói đăng ký.';
  static const String premiumPurchaseError = 
      'Không thể hoàn tất thanh toán. Vui lòng thử lại sau.';
  static const String premiumRestoreError = 
      'Không thể khôi phục giao dịch. Vui lòng thử lại sau.';
  static const String premiumFeatureLocked = 
      'Tính năng này cần Premium. Nâng cấp để mở khóa!';
  static const String premiumPaymentComingSoon = 
      'Tính năng thanh toán đang phát triển.';
  static const String premiumRestoreComingSoon = 
      'Tính năng khôi phục đang phát triển.';

  // ==================== SETTINGS ====================
  static const String settingsClearCacheSuccess = 
      'Đã xóa bộ nhớ đệm thành công.';
  static const String settingsClearCacheError = 
      'Không thể xóa bộ nhớ đệm. Vui lòng thử lại.';
  static const String settingsResetTutorialSuccess = 
      'Đã đặt lại hướng dẫn.';
  static const String settingsFeatureComingSoon = 
      'Tính năng đang phát triển.';

  // ==================== FAVORITES ====================
  static const String favoritesAddSuccess = 
      'Đã thêm vào yêu thích.';
  static const String favoritesRemoveSuccess = 
      'Đã xóa khỏi yêu thích.';
  static const String favoritesUpdateError = 
      'Không thể cập nhật. Vui lòng thử lại.';
  static const String favoritesRemoveError = 
      'Không thể xóa. Vui lòng thử lại.';

  // ==================== NETWORK / GENERAL ====================
  static const String networkError = 
      'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
  static const String unknownError = 
      'Đã xảy ra lỗi không xác định. Vui lòng thử lại sau.';
  static const String timeoutError = 
      'Yêu cầu quá thời gian chờ. Vui lòng thử lại.';
  static const String unauthorizedError = 
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  static const String notFoundError = 
      'Không tìm thấy dữ liệu.';
  static const String rateLimitError = 
      'Quá nhiều yêu cầu. Vui lòng đợi một lát rồi thử lại.';

  // ==================== SUCCESS MESSAGES ====================
  static const String saveSuccess = 
      'Đã lưu thành công.';
  static const String updateSuccess = 
      'Đã cập nhật thành công.';
  static const String deleteSuccess = 
      'Đã xóa thành công.';
  static const String operationSuccess = 
      'Thao tác thành công.';
}


/// Vietnamese strings for the app
/// All UI text should be defined here for easy localization
class S {
  S._();

  // App
  static const String appName = 'Học Tiếng Trung HSK – HanLy';

  // Common
  static const String ok = 'OK';
  static const String cancel = 'Hủy';
  static const String save = 'Lưu';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String done = 'Xong';
  static const String next = 'Tiếp';
  static const String back = 'Quay lại';
  static const String close = 'Đóng';
  static const String search = 'Tìm kiếm';
  static const String loading = 'Đang tải...';
  static const String error = 'Lỗi';
  static const String retry = 'Thử lại';
  static const String comingSoon = 'Sắp ra mắt';

  // Auth - Email + Password + 2FA
  static const String enterEmail = 'Nhập email của bạn';
  static const String emailHint = 'email@example.com';
  static const String password = 'Mật khẩu';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String createAccount = 'Tạo tài khoản';
  static const String alreadyHaveAccount = 'Đã có tài khoản?';
  static const String dontHaveAccount = 'Chưa có tài khoản?';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String verify2FA = 'Xác thực 2 bước';
  static const String enter2FACode = 'Nhập mã xác thực';
  static const String codeSentToEmail = 'Mã 6 số đã được gửi đến email của bạn';
  static const String resendCode = 'Gửi lại mã';
  static const String codeExpired = 'Mã đã hết hạn';
  static const String invalidCode = 'Mã xác thực không đúng';
  static const String invalidEmail = 'Email không hợp lệ';
  static const String invalidPassword = 'Mật khẩu không hợp lệ';
  static const String passwordTooWeak = 'Mật khẩu không đủ mạnh';
  static const String passwordMismatch = 'Mật khẩu xác nhận không khớp';
  static const String accountLocked = 'Tài khoản tạm khóa';
  static const String continueWithApple = 'Tiếp tục với Apple';
  static const String continueWithGoogle = 'Tiếp tục với Google';
  static const String orContinueWith = 'Hoặc tiếp tục với';
  static const String signIn = 'Đăng nhập';
  static const String signOut = 'Đăng xuất';
  static const String signOutConfirm = 'Bạn có chắc muốn đăng xuất?';
  static const String changePassword = 'Đổi mật khẩu';
  static const String enable2FA = 'Bật xác thực 2 bước';
  static const String disable2FA = 'Tắt xác thực 2 bước';

  // Onboarding
  static const String welcome = 'Chào mừng đến với HanLy!';
  static const String whatIsYourName = 'Bạn tên gì?';
  static const String displayNameHint = 'Tên hiển thị';
  static const String whatIsYourGoal = 'Mục tiêu của bạn?';
  static const String goalExam = 'Thi HSK';
  static const String goalConversation = 'Giao tiếp';
  static const String goalBoth = 'Cả hai';
  static const String currentLevel = 'Trình độ hiện tại';
  static const String dailyMinutes = 'Thời gian học mỗi ngày';
  static const String minutes = 'phút';
  static const String focusSkills = 'Kỹ năng muốn tập trung';
  static const String skillListening = 'Nghe hiểu';
  static const String skillHanzi = 'Phân tích chữ Hán';
  static const String createProfile = 'Tạo hồ sơ';

  // Navigation tabs
  static const String tabToday = 'Hôm nay';
  static const String tabLearn = 'Học';
  static const String tabExplore = 'Khám phá';
  static const String tabMe = 'Tôi';

  // Today
  static const String today = 'Hôm nay';
  static const String goodMorning = 'Chào buổi sáng';
  static const String goodAfternoon = 'Chào buổi chiều';
  static const String goodEvening = 'Chào buổi tối';
  static const String streak = 'Chuỗi ngày';
  static const String streakDays = 'ngày';
  static const String dailyProgress = 'Tiến độ hôm nay';
  static const String learnNewWords = 'Học từ mới';
  static const String review = 'Ôn tập';
  static const String game30s = 'Game 30s';
  static const String dueToday = 'Cần ôn hôm nay';
  static const String noWordsDue = 'Không có từ cần ôn';
  static const String wordsToReview = 'từ cần ôn';
  static const String newWords = 'từ mới';
  static const String completed = 'đã hoàn thành';

  // Learn
  static const String learn = 'Học tập';
  static const String modeMixed = 'Tổng hợp';
  static const String modeFlashcards = 'Flashcards';
  static const String modeListening = 'Nghe';
  static const String modeHanziBuilder = 'Ghép chữ Hán';
  static const String modeCollocations = 'Cụm từ';
  static const String modeReview = 'Ôn tập';
  static const String modeGame30s = 'Game 30s';

  // Session
  static const String step = 'Bước';
  static const String guess = 'Đoán';
  static const String reveal = 'Xem đáp án';
  static const String audio = 'Âm thanh';
  static const String normalSpeed = 'Tốc độ thường';
  static const String slowSpeed = 'Chậm';
  static const String hanziDna = 'Phân tích chữ';
  static const String radical = 'Bộ thủ';
  static const String components = 'Thành phần';
  static const String strokeCount = 'Số nét';
  static const String mnemonic = 'Mẹo nhớ';
  static const String context = 'Ngữ cảnh';
  static const String collocations = 'Cụm từ';
  static const String examples = 'Ví dụ';
  static const String quiz = 'Kiểm tra';
  static const String correct = 'Đúng!';
  static const String incorrect = 'Sai!';
  static const String sessionComplete = 'Hoàn thành!';
  static const String minutesLearned = 'phút học';
  static const String accuracy = 'Độ chính xác';

  // Rating
  static const String rateAgain = 'Lại';
  static const String rateHard = 'Khó';
  static const String rateGood = 'Tốt';
  static const String rateEasy = 'Dễ';

  // Explore
  static const String explore = 'Khám phá';
  static const String searchVocab = 'Tìm từ vựng...';
  static const String all = 'Tất cả';
  static const String filter = 'Lọc';
  static const String sort = 'Sắp xếp';
  static const String sortByFrequency = 'Tần suất';
  static const String sortByDifficulty = 'Độ khó';
  static const String sortByOrder = 'Thứ tự';
  static const String level = 'Cấp độ';
  static const String wordType = 'Loại từ';
  static const String topics = 'Chủ đề';
  static const String applyFilter = 'Áp dụng';
  static const String clearFilter = 'Xóa bộ lọc';
  static const String noResults = 'Không tìm thấy kết quả';

  // Word Detail
  static const String meanings = 'Nghĩa';
  static const String notes = 'Ghi chú';
  static const String metadata = 'Thông tin';
  static const String frequency = 'Tần suất';
  static const String difficulty = 'Độ khó';
  static const String addToDeck = 'Thêm vào bộ';
  static const String addToFavorites = 'Thêm yêu thích';
  static const String removeFromFavorites = 'Bỏ yêu thích';

  // Favorites
  static const String favorites = 'Yêu thích';
  static const String noFavorites = 'Chưa có từ yêu thích';
  static const String noFavoritesDesc = 'Nhấn ♡ để thêm từ vào danh sách yêu thích';

  // Decks
  static const String decks = 'Bộ từ vựng';
  static const String createDeck = 'Tạo bộ mới';
  static const String deckName = 'Tên bộ từ';
  static const String deckNameHint = 'VD: Từ vựng chủ đề du lịch';
  static const String deckDescription = 'Mô tả (tuỳ chọn)';
  static const String noDecks = 'Chưa có bộ từ vựng';
  static const String noDecksDesc = 'Tạo bộ từ vựng riêng để học hiệu quả hơn';
  static const String deleteDeck = 'Xóa bộ từ';
  static const String deleteDeckConfirm = 'Bạn có chắc muốn xóa bộ từ này?';
  static const String wordCount = 'từ';
  static const String removeFromDeck = 'Xóa khỏi bộ';

  // Me / Account
  static const String account = 'Tài khoản';
  static const String profile = 'Hồ sơ';
  static const String editProfile = 'Sửa hồ sơ';
  static const String settings = 'Cài đặt';
  static const String premium = 'Premium';
  static const String premiumMember = 'Thành viên Premium';
  static const String upgradeToPremium = 'Nâng cấp Premium';
  static const String privacyPolicy = 'Chính sách bảo mật';
  static const String termsOfService = 'Điều khoản sử dụng';
  static const String deleteAccount = 'Xóa tài khoản';
  static const String deleteAccountConfirm =
      'Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác.';
  static const String deleteAccountSuccess = 'Tài khoản đã được xóa';

  // Delete Account Screen
  static const String deleteAccountTitle = 'Bạn chắc chắn chứ?';
  static const String deleteAccountDescription =
      'Hành động này không thể hoàn tác. Bạn sẽ mất tất cả dữ liệu học tập vĩnh viễn.';
  static const String whatYouWillLose = 'NHỮNG GÌ BẠN SẼ MẤT';
  static const String srsProgress = 'Tiến độ SRS';
  static String srsProgressDesc(int count) =>
      '$count bài ôn tập và lịch sử sẽ bị xóa.';
  static const String savedCollections = 'Bộ sưu tập đã lưu';
  static String savedCollectionsDesc(int count) =>
      '$count danh sách Hanzi sẽ bị xóa.';
  static const String premiumStatus = 'Trạng thái Premium';
  static const String premiumStatusDesc =
      'Thời gian đăng ký còn lại sẽ bị mất.';
  static const String noPremiumStatus = 'Chưa đăng ký Premium.';
  static const String typeDeleteToConfirm = 'Gõ "DELETE" để xác nhận';
  static const String permanentlyDelete = 'Xóa vĩnh viễn';
  static const String keepMyAccount = 'Giữ tài khoản của tôi';

  // Me screen specific
  static const String me = 'Tôi';
  static const String dailyGoal = 'Mục tiêu hôm nay';
  static const String words = 'từ';
  static const String dayStreak = 'Chuỗi ngày';
  static const String mastered = 'Đã thuộc';
  static const String quickActions = 'Thao tác nhanh';
  static const String adjustGoal = 'Điều chỉnh';
  static const String offline = 'Ngoại tuyến';
  static const String upgrade = 'Nâng cấp';
  static const String preferences = 'Tùy chọn';
  static const String notifications = 'Thông báo';
  static const String soundHaptics = 'Âm thanh & Rung';
  static const String vietnameseSupport = 'Hỗ trợ tiếng Việt';
  static const String appVersion = 'Phiên bản';
  static const String adjustDailyGoal = 'Điều chỉnh mục tiêu';
  static const String dailyNewWordsGoal = 'Số từ mới mỗi ngày';
  static const String goalUpdated = 'Đã cập nhật mục tiêu';
  static const String proMember = 'THÀNH VIÊN PRO';

  // Premium
  static const String premiumTitle = 'HanLy Premium';
  static const String premiumSubtitle = 'Nâng cao trải nghiệm học tập';
  static const String premiumBenefit1 = 'Học không giới hạn từ vựng mỗi ngày';
  static const String premiumBenefit2 = 'Truy cập tất cả HSK 1-6';
  static const String premiumBenefit3 = 'Tải về học offline';
  static const String premiumBenefit4 = 'Không quảng cáo';
  static const String premiumBenefit5 = 'Thống kê chi tiết';
  static const String premiumCta = 'Đăng ký Premium';
  static const String restorePurchase = 'Khôi phục giao dịch';

  // Errors
  static const String errorNetwork = 'Lỗi kết nối mạng';
  static const String errorServer = 'Lỗi máy chủ';
  static const String errorUnknown = 'Đã xảy ra lỗi';
  static const String errorSessionExpired = 'Phiên đăng nhập hết hạn';

  // Empty states
  static const String emptyVocabs = 'Không có từ vựng';
  static const String emptyDecks = 'Không có bộ từ';
}


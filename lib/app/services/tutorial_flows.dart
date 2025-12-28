import 'tutorial_service.dart';

/// Predefined tutorial flows for the app
class TutorialFlows {
  TutorialFlows._();

  /// Today screen tutorial for new users
  static const todayScreenTutorial = TutorialFlow(
    id: 'today_screen_v1',
    screenRoute: '/shell',
    steps: [
      TutorialStep(
        id: 'welcome',
        title: 'Chào mừng đến HanLy! 🎉',
        description: 'Đây là màn hình chính của bạn. Tại đây bạn sẽ thấy mục tiêu học tập hàng ngày và các hoạt động được đề xuất.',
        emoji: '👋',
        targetKey: 'today_header',
        position: TutorialPosition.bottom,
        needsScroll: false, // Header is always visible
      ),
      TutorialStep(
        id: 'next_action',
        title: 'Bắt đầu học ngay',
        description: 'Thẻ này hiển thị hành động được đề xuất tiếp theo. Nhấn vào để bắt đầu học từ mới hoặc ôn tập.',
        emoji: '✨',
        targetKey: 'next_action_card',
        position: TutorialPosition.bottom,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'progress_ring',
        title: 'Theo dõi tiến độ',
        description: 'Đây là thống kê học tập hôm nay. Số từ mới, từ ôn tập và thời gian học được cập nhật realtime.',
        emoji: '📊',
        targetKey: 'progress_ring',
        position: TutorialPosition.bottom,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'quick_actions',
        title: 'Truy cập nhanh',
        description: 'Các nút này giúp bạn nhanh chóng truy cập Ôn tập SRS, Game 30s, Yêu thích và Bộ thẻ.',
        emoji: '⚡',
        targetKey: 'quick_actions',
        position: TutorialPosition.top,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'due_today',
        title: 'Cần ôn hôm nay',
        description: 'Mục này hiển thị các từ cần ôn tập theo thuật toán SRS. Ôn đều đặn để nhớ lâu hơn!',
        emoji: '📅',
        targetKey: 'due_today_section',
        position: TutorialPosition.top,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'weekly_chart',
        title: 'Thống kê tuần',
        description: 'Xem tiến độ học tập trong tuần. Duy trì streak để tạo thói quen học tập tốt!',
        emoji: '📈',
        targetKey: 'weekly_chart',
        position: TutorialPosition.top,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'bottom_nav',
        title: 'Điều hướng chính',
        description: 'Sử dụng thanh điều hướng để chuyển giữa các màn hình: Hôm nay, Học, Khám phá và Tài khoản.',
        emoji: '🧭',
        targetKey: 'bottom_nav',
        position: TutorialPosition.top,
        needsScroll: false, // Bottom nav is fixed
        isLast: true,
      ),
    ],
  );

  /// Learn tab tutorial
  static const learnTabTutorial = TutorialFlow(
    id: 'learn_tab_v1',
    screenRoute: '/shell',
    steps: [
      TutorialStep(
        id: 'quick_review',
        title: 'Ôn tập nhanh',
        description: 'Kiểm tra xem bạn có từ nào cần ôn tập không. Nếu có, hãy ôn tập ngay để nhớ lâu hơn!',
        emoji: '⚡',
        targetKey: 'learn_quick_review',
        position: TutorialPosition.bottom,
        needsScroll: false,
      ),
      TutorialStep(
        id: 'study_modes',
        title: 'Chế độ học',
        description: 'Có 4 chế độ học:\n• Flashcards - Học với thẻ ghi nhớ\n• Luyện Nghe - Nghe và chọn nghĩa\n• Phát âm - Luyện nói\n• Ghép Từ - Ghép từ với nghĩa',
        emoji: '📚',
        targetKey: 'study_modes_grid',
        position: TutorialPosition.bottom,
        needsScroll: true,
      ),
      TutorialStep(
        id: 'comprehensive_review',
        title: 'Ôn tập tổng hợp',
        description: 'Chế độ ôn tập kết hợp nhiều dạng bài tập. Đây là cách hiệu quả nhất để ghi nhớ từ vựng!',
        emoji: '🎯',
        targetKey: 'learn_comprehensive',
        position: TutorialPosition.top,
        needsScroll: true,
        isLast: true,
      ),
    ],
  );

  /// Practice session tutorial
  static const practiceSessionTutorial = TutorialFlow(
    id: 'practice_session_v1',
    screenRoute: '/practice',
    steps: [
      TutorialStep(
        id: 'word_card',
        title: 'Thẻ từ vựng',
        description: 'Đây là thẻ từ vựng. Bạn sẽ học từ mới qua nhiều bước: nghĩa, âm thanh, chữ Hán và ví dụ.',
        emoji: '🀄',
        targetKey: 'word_card',
        position: TutorialPosition.bottom,
        needsScroll: false,
      ),
      TutorialStep(
        id: 'audio_button',
        title: 'Nghe phát âm',
        description: 'Nhấn vào biểu tượng loa để nghe phát âm chuẩn của từ.',
        emoji: '🔊',
        targetKey: 'audio_button',
        position: TutorialPosition.bottom,
        needsScroll: false,
      ),
      TutorialStep(
        id: 'next_step',
        title: 'Chuyển bước tiếp theo',
        description: 'Nhấn nút này để chuyển sang bước tiếp theo trong quá trình học.',
        emoji: '➡️',
        targetKey: 'next_button',
        position: TutorialPosition.top,
        needsScroll: false,
        isLast: true,
      ),
    ],
  );
}

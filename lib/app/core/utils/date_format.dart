import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatUtil {
  DateFormatUtil._();

  /// Format: "Thứ Hai, 15 Tháng 12"
  static String formatDayFull(DateTime date) {
    final dayOfWeek = _getVietnameseDayOfWeek(date.weekday);
    final day = date.day;
    final month = _getVietnameseMonth(date.month);
    return '$dayOfWeek, $day $month';
  }

  /// Format: "15/12/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format: "15/12"
  static String formatDateCompact(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  /// Format: "Ngày 15 Tháng 12" (Day Month)
  static String formatMonthDay(DateTime date) {
    final month = _getVietnameseMonth(date.month);
    return 'Ngày ${date.day} $month';
  }

  /// Format: "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format relative time: "Vừa xong", "5 phút trước", "Hôm qua"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return formatDateShort(date);
    }
  }

  /// Format duration: "5 phút", "1 giờ 30 phút"
  static String formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} phút';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }

  static String _getVietnameseDayOfWeek(int weekday) {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return days[weekday - 1];
  }

  static String _getVietnameseMonth(int month) {
    const months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return months[month - 1];
  }
}


import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/logger.dart';

class DonationOption {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final int amount;

  DonationOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.amount,
  });
}

class DonationController extends GetxController {
  final selectedOption = ''.obs;
  final isLoading = false.obs;

  final options = [
    DonationOption(
      id: 'coffee',
      title: 'Mời 1 ly cà phê',
      subtitle: '☕ Cảm ơn bạn!',
      icon: '☕',
      amount: 25000,
    ),
    DonationOption(
      id: 'meal',
      title: 'Mời 1 bữa ăn',
      subtitle: '🍜 Ngon lắm nè!',
      icon: '🍜',
      amount: 50000,
    ),
    DonationOption(
      id: 'support',
      title: 'Ủng hộ phát triển',
      subtitle: '💪 Động lực lớn!',
      icon: '💪',
      amount: 100000,
    ),
    DonationOption(
      id: 'sponsor',
      title: 'Nhà tài trợ',
      subtitle: '⭐ Bạn tuyệt vời!',
      icon: '⭐',
      amount: 200000,
    ),
  ];

  void selectOption(String optionId) {
    selectedOption.value = optionId;
  }

  Future<void> donate() async {
    if (selectedOption.value.isEmpty) return;
    
    final option = options.firstWhereOrNull((o) => o.id == selectedOption.value);
    if (option == null) return;

    try {
      isLoading.value = true;
      
      // TODO: Integrate with payment provider (MoMo, Bank Transfer, etc.)
      // For now, open donation link
      final uri = Uri.parse('https://buymeacoffee.com/hanly');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      Logger.d('DonationController', 'Donation initiated: ${option.id} - ${option.amount}');
    } catch (e) {
      Logger.e('DonationController', 'Donation error', e);
      Get.snackbar(
        'Lỗi',
        'Không thể mở trang donate. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toString();
  }
}

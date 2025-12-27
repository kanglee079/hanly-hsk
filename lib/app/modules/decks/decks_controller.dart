import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/deck_model.dart';
import '../../data/repositories/decks_repo.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/widgets/hm_bottom_sheet.dart';
import '../../core/constants/strings_vi.dart';
import '../../routes/app_routes.dart';

/// Decks controller - uses real BE API
class DecksController extends GetxController {
  final DecksRepo _decksRepo = Get.find<DecksRepo>();

  final RxList<DeckModel> decks = <DeckModel>[].obs;
  final RxBool isLoading = false.obs;

  final nameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadDecks();
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> loadDecks() async {
    isLoading.value = true;

    try {
      final data = await _decksRepo.getDecks();
      decks.value = data;
    } catch (e) {
      Logger.e('DecksController', 'loadDecks error', e);
      HMToast.error('Không thể tải danh sách bộ từ');
    } finally {
      isLoading.value = false;
    }
  }

  void openDeckDetail(DeckModel deck) {
    Get.toNamed(Routes.deckDetail, arguments: {'deckId': deck.id, 'deck': deck});
  }

  Future<void> createDeck() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      HMToast.error('Vui lòng nhập tên bộ từ');
      return;
    }

    try {
      final deck = await _decksRepo.createDeck(name: name);
      decks.add(deck);
      nameController.clear();
      Get.back();
      HMToast.success('Đã tạo bộ từ');
    } catch (e) {
      Logger.e('DecksController', 'createDeck error', e);
      HMToast.error('Không thể tạo bộ từ');
    }
  }

  Future<void> deleteDeck(DeckModel deck) async {
    final confirmed = await HMBottomSheet.showConfirm(
      title: S.deleteDeck,
      message: S.deleteDeckConfirm,
      confirmText: S.delete,
      isDanger: true,
    );

    if (confirmed == true) {
      try {
        await _decksRepo.deleteDeck(deck.id);
        decks.removeWhere((d) => d.id == deck.id);
        HMToast.info('Đã xóa bộ từ');
      } catch (e) {
        Logger.e('DecksController', 'deleteDeck error', e);
        HMToast.error('Không thể xóa');
      }
    }
  }
}

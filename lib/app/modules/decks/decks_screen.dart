import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import 'decks_controller.dart';

/// Decks screen
class DecksScreen extends GetView<DecksController> {
  const DecksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(
        title: S.decks,
        actions: [
          IconButton(
            onPressed: () => _showCreateSheet(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            padding: AppSpacing.screenPadding,
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: HMSkeletonCard(height: 80),
            ),
          );
        }

        if (controller.decks.isEmpty) {
          return HMEmptyState(
            icon: Icons.folder_outlined,
            title: S.noDecks,
            description: S.noDecksDesc,
            actionLabel: S.createDeck,
            onAction: () => _showCreateSheet(context),
          );
        }

        return ListView.builder(
          padding: AppSpacing.screenPadding,
          itemCount: controller.decks.length,
          itemBuilder: (context, index) {
            final deck = controller.decks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HMCard(
                onTap: () => controller.openDeckDetail(deck),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${deck.vocabCount} ${S.wordCount}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          controller.deleteDeck(deck);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(S.delete,
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showCreateSheet(BuildContext context) {
    HMBottomSheet.show(
      title: S.createDeck,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HMTextField(
            controller: controller.nameController,
            labelText: S.deckName,
            hintText: S.deckNameHint,
          ),
          const SizedBox(height: 24),
          HMButton(
            text: S.createDeck,
            onPressed: controller.createDeck,
          ),
        ],
      ),
    );
  }
}


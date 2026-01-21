import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/deck_model.dart';
import '../../data/models/vocab_model.dart';
import '../../data/repositories/decks_repo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/logger.dart';
import '../../routes/app_routes.dart';

/// Deck detail screen
class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late DeckModel deck;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['deck'] != null) {
      deck = args['deck'] as DeckModel;
      _loadDeckDetail();
    }
  }

  Future<void> _loadDeckDetail() async {
    try {
      final decksRepo = Get.find<DecksRepo>();
      final loaded = await decksRepo.getDeckById(deck.id);
      setState(() {
        deck = loaded;
        isLoading = false;
      });
    } catch (e) {
      Logger.e('DeckDetailScreen', 'loadDeckDetail error', e);
      setState(() => isLoading = false);
    }
  }

  void _startStudy() {
    if (deck.vocabs.isEmpty) {
      HMToast.error('Bộ từ chưa có từ vựng');
      return;
    }
    Get.toNamed(
      Routes.practice,
      arguments: {'mode': 'learnNew', 'deckId': deck.id, 'vocabs': deck.vocabs},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(title: deck.name),
      body: isLoading
          ? const HMLoadingContent(icon: Icons.folder_rounded)
          : Column(
              children: [
                // Header with stats
                _buildHeader(isDark),

                // Vocab list
                Expanded(
                  child: deck.vocabs.isEmpty
                      ? HMEmptyState(
                          icon: Icons.folder_open_outlined,
                          title: S.emptyVocabs,
                          description: 'Thêm từ vựng từ mục Khám phá',
                        )
                      : ListView.builder(
                          padding: AppSpacing.screenPadding,
                          itemCount: deck.vocabs.length,
                          itemBuilder: (context, index) {
                            final vocab = deck.vocabs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildVocabCard(vocab, isDark),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.library_books_outlined,
                value: '${deck.vocabCount}',
                label: 'từ vựng',
                isDark: isDark,
              ),
              _buildStatItem(
                icon: Icons.calendar_today_outlined,
                value: _formatDate(deck.createdAt),
                label: 'ngày tạo',
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Study button
          SizedBox(
            width: double.infinity,
            child: HMButton(
              text: 'Học bộ từ này',
              icon: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: deck.vocabs.isNotEmpty ? _startStudy : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildVocabCard(VocabModel vocab, bool isDark) {
    return HMCard(
      onTap: () => Get.toNamed(Routes.wordDetail, arguments: {'vocab': vocab}),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.getHskColor(vocab.levelInt).withAlpha(25),
              borderRadius: AppSpacing.borderRadiusMd,
            ),
            child: Center(
              child: Text(
                vocab.hanzi,
                style: AppTypography.hanziSmall.copyWith(
                  fontSize: 20,
                  color: AppColors.getHskColor(vocab.levelInt),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vocab.pinyin,
                  style: AppTypography.pinyinSmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  vocab.meaningViCapitalized,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // SRS state if available
          if (vocab.state != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStateColor(vocab.state).withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                vocab.stateDisplay,
                style: AppTypography.labelSmall.copyWith(
                  color: _getStateColor(vocab.state),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStateColor(String? state) {
    switch (state) {
      case 'new':
        return AppColors.primary;
      case 'learning':
        return AppColors.warning;
      case 'review':
        return AppColors.primary;
      case 'mastered':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}

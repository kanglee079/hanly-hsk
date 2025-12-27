import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/game_repo.dart';
import 'leaderboard_controller.dart';

/// Leaderboard screen
class LeaderboardScreen extends GetView<LeaderboardController> {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: HMAppBar(title: 'Bảng xếp hạng'),
      body: Column(
        children: [
          // Game type tabs
          _buildGameTypeTabs(isDark),

          // Period filter
          _buildPeriodFilter(isDark),

          // Leaderboard list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final leaderboard = controller.leaderboard.value;
              if (leaderboard == null || leaderboard.entries.isEmpty) {
                return HMEmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'Chưa có dữ liệu',
                  description: 'Hãy chơi game để lên bảng xếp hạng!',
                );
              }

              return ListView.builder(
                padding: AppSpacing.screenPadding,
                itemCount: leaderboard.entries.length + 1, // +1 for my rank card
                itemBuilder: (context, index) {
                  if (index == 0 && leaderboard.myRank != null) {
                    return _buildMyRankCard(leaderboard.myRank!, isDark);
                  }

                  final entryIndex = leaderboard.myRank != null ? index - 1 : index;
                  if (entryIndex >= leaderboard.entries.length) return null;

                  return _buildLeaderboardItem(
                    leaderboard.entries[entryIndex],
                    isDark,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTypeTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Obx(() => Row(
            children: controller.gameTypes.map((type) {
              final isSelected = controller.selectedGameType.value == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.setGameType(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.getGameTypeName(type),
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildPeriodFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => Row(
            children: controller.periods.map((period) {
              final isSelected = controller.selectedPeriod.value == period;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.setPeriod(period),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      controller.getPeriodName(period),
                      textAlign: TextAlign.center,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }

  Widget _buildMyRankCard(LeaderboardEntry myRank, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withAlpha(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${myRank.rank}',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                  'Thứ hạng của bạn',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                Text(
                  myRank.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${myRank.score}',
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'điểm',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, bool isDark) {
    final rankColor = _getRankColor(entry.rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: entry.rank <= 3
                ? _buildMedal(entry.rank)
                : Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: rankColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withAlpha(25),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              entry.displayName,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Score
          Text(
            '${entry.score}',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedal(int rank) {
    final icons = {
      1: '🥇',
      2: '🥈',
      3: '🥉',
    };

    return Text(
      icons[rank] ?? '$rank',
      style: const TextStyle(fontSize: 24),
      textAlign: TextAlign.center,
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return AppColors.primary;
    if (rank <= 10) return AppColors.success;
    return AppColors.textSecondary;
  }
}


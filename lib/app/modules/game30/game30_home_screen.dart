import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/game_repo.dart';
import 'game30_home_controller.dart';

/// Game 30s Home Screen with Leaderboard - shown BEFORE starting the game
/// UI styled to match SRS Review List screen for consistency
class Game30HomeScreen extends GetView<Game30HomeController> {
  const Game30HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header - matches SRS Review List style
            _buildHeader(isDark),
            
            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const HMLoadingContent(
                    message: 'Đang tải...',
                    icon: Icons.leaderboard_rounded,
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: controller.loadLeaderboard,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Game info card
                        _buildGameInfoCard(isDark),
                        
                        const SizedBox(height: 24),
                        
                        // Your stats
                        _buildYourStats(isDark),
                        
                        const SizedBox(height: 24),
                        
                        // Leaderboard
                        _buildLeaderboardSection(isDark),
                        
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              }),
            ),
            
            // Play button - matches SRS Review List bottom button
            _buildPlayButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    // Styled to match SrsReviewListScreen header
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button - same style as SRS Review List
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title - same style as SRS Review List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game 30 giây',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Thử thách tốc độ của bạn!',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFF8B5CF6), // Purple
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Timer icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('⏱️', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30 giây thử thách!',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trả lời nhanh, điểm cao hơn',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rules - horizontal chips
          Row(
            children: [
              _buildRuleChip('✅ +10', 'Đúng'),
              const SizedBox(width: 8),
              _buildRuleChip('⚡ x2', 'Streak'),
              const SizedBox(width: 8),
              _buildRuleChip('⏰ +2s', 'Bonus'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleChip(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourStats(bool isDark) {
    return Obx(() {
      final entry = controller.currentUserEntry.value;
      final highScore = entry?.score ?? controller.localHighScore.value;
      final rank = entry?.rank ?? 0;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Thành tích của bạn',
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Stats row
          Row(
            children: [
              // High score
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  value: '$highScore',
                  label: 'Điểm cao',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // Rank
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  value: rank > 0 ? '#$rank' : '--',
                  label: 'Xếp hạng',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // Games played
              Expanded(
                child: _buildStatCard(
                  icon: Icons.sports_esports_rounded,
                  iconColor: const Color(0xFF10B981),
                  value: '${controller.gamesPlayed.value}',
                  label: 'Lượt chơi',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bảng xếp hạng',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${controller.totalPlayers.value} người',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ],
          ),
        ),
        
        // Top 3 podium
        _buildTop3Podium(isDark),
        
        const SizedBox(height: 12),
        
        // Rest of leaderboard
        Obx(() {
          final entries = controller.leaderboardEntries
              .where((e) => e.rank > 3)
              .toList();
          
          if (entries.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  _buildLeaderboardRow(entries[i], isDark),
                  if (i < entries.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTop3Podium(bool isDark) {
    return Obx(() {
      final top3 = controller.leaderboardEntries.take(3).toList();
      if (top3.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  'Chưa có ai trong bảng xếp hạng',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy là người đầu tiên chinh phục!',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Reorder for podium display: 2nd, 1st, 3rd
      final podiumOrder = <_PodiumItem>[];
      if (top3.length >= 2) podiumOrder.add(_PodiumItem(top3[1], 2));
      if (top3.isNotEmpty) podiumOrder.add(_PodiumItem(top3[0], 1));
      if (top3.length >= 3) podiumOrder.add(_PodiumItem(top3[2], 3));
      
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: podiumOrder.map((item) => 
            _buildPodiumItem(item.entry, item.position, isDark)
          ).toList(),
        ),
      );
    });
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int position, bool isDark) {
    final heights = {1: 80.0, 2: 60.0, 3: 45.0};
    final avatarSizes = {1: 52.0, 2: 44.0, 3: 40.0};
    final colors = {
      1: const Color(0xFFF59E0B), // Gold/Amber
      2: const Color(0xFF94A3B8), // Silver
      3: const Color(0xFFD97706), // Bronze
    };
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final isCurrentUser = _isCurrentUser(entry);
    final size = avatarSizes[position]!;
    
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar - with image support
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.primary.withAlpha(20)
                  : colors[position]!.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? AppColors.primary : colors[position]!,
                width: position == 1 ? 3 : 2,
              ),
              image: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(entry.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? Center(
                    child: Text(
                      entry.displayName.isNotEmpty 
                          ? entry.displayName[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? AppColors.primary : colors[position],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          // Name
          Text(
            isCurrentUser ? 'Bạn' : _truncateName(entry.displayName),
            style: AppTypography.labelSmall.copyWith(
              color: isCurrentUser 
                  ? AppColors.primary
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Score
          Text(
            '${entry.score}',
            style: AppTypography.labelMedium.copyWith(
              color: isCurrentUser ? AppColors.primary : colors[position],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Podium
          Container(
            height: heights[position],
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[position]!.withAlpha(150),
                  colors[position]!.withAlpha(230),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                medals[position]!,
                style: TextStyle(fontSize: position == 1 ? 24 : 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _truncateName(String name) {
    if (name.length <= 8) return name;
    return '${name.substring(0, 7)}...';
  }

  bool _isCurrentUser(LeaderboardEntry entry) {
    final currentUser = controller.currentUserEntry.value;
    if (currentUser == null) return false;
    return entry.odId == currentUser.odId || entry.odId == 'current';
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, bool isDark) {
    final isCurrentUser = _isCurrentUser(entry);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? AppColors.primary.withAlpha(10) 
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.primary.withAlpha(20)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: AppTypography.labelSmall.copyWith(
                  color: isCurrentUser 
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar - with image support
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.primary.withAlpha(20)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              shape: BoxShape.circle,
              border: isCurrentUser ? Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1.5,
              ) : null,
              image: entry.avatarUrl != null && entry.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(entry.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: entry.avatarUrl == null || entry.avatarUrl!.isEmpty
                ? Center(
                    child: Text(
                      entry.displayName.isNotEmpty 
                          ? entry.displayName[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser 
                            ? AppColors.primary
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textSecondary),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              isCurrentUser ? 'Bạn' : entry.displayName,
              style: AppTypography.bodyMedium.copyWith(
                color: isCurrentUser 
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.primary.withAlpha(15)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.score}',
              style: AppTypography.labelMedium.copyWith(
                color: isCurrentUser 
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final canPlay = controller.canPlay.value;
          final cannotPlayReason = controller.cannotPlayReason.value;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning if cannot play
              if (!canPlay && cannotPlayReason.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withAlpha(12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cannotPlayReason,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Play button with remaining plays
              Row(
                children: [
                  // Remaining plays indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          controller.remainingPlaysDisplay,
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lượt',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Main play button
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: canPlay 
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: canPlay ? null : (isDark ? AppColors.surfaceDark : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canPlay
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withAlpha(40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: canPlay
                              ? () {
                                  HapticFeedback.mediumImpact();
                                  controller.startGame();
                                }
                              : null,
                          child: Center(
                            child: controller.isStartingGame.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: HMLoadingIndicator.small(color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        canPlay ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                                        color: canPlay ? Colors.white : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        canPlay ? 'Bắt đầu chơi' : 'Chưa thể chơi',
                                        style: AppTypography.titleSmall.copyWith(
                                          color: canPlay ? Colors.white : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Podium item helper class
class _PodiumItem {
  final LeaderboardEntry entry;
  final int position;
  
  _PodiumItem(this.entry, this.position);
}


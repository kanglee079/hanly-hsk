import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';

/// Widget shown when practice session is complete
class PracticeCompleteWidget extends StatelessWidget {
  final bool isDark;
  final int correctCount;
  final int totalCount;
  final int timeSpent; // seconds
  final VoidCallback onContinue;
  final VoidCallback onFinish;

  const PracticeCompleteWidget({
    super.key,
    required this.isDark,
    required this.correctCount,
    required this.totalCount,
    required this.timeSpent,
    required this.onContinue,
    required this.onFinish,
  });

  int get accuracy => totalCount > 0 ? ((correctCount / totalCount) * 100).round() : 100;
  
  String get _performanceMessage {
    if (accuracy >= 90) return 'Xuất sắc! 🏆';
    if (accuracy >= 80) return 'Tuyệt vời! 🎉';
    if (accuracy >= 70) return 'Tốt lắm! 👍';
    if (accuracy >= 60) return 'Khá tốt! 💪';
    return 'Cố gắng thêm! 📚';
  }
  
  Color get _performanceColor {
    if (accuracy >= 80) return const Color(0xFF10B981);
    if (accuracy >= 60) return const Color(0xFFF59E0B);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE0F2FE),
                  const Color(0xFFBAE6FD),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Success icon with gradient
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _performanceColor.withValues(alpha: 0.2),
                      _performanceColor.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _performanceColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  accuracy >= 70 ? Icons.emoji_events_rounded : Icons.school_rounded,
                  size: 48,
                  color: _performanceColor,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Message
              Text(
                _performanceMessage,
                style: AppTypography.headlineMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Bạn đã hoàn thành buổi học!',
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Stats card with glassmorphism style
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.check_circle_rounded,
                      value: '$correctCount/$totalCount',
                      label: 'Đúng',
                      color: const Color(0xFF10B981),
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      icon: Icons.percent_rounded,
                      value: '$accuracy%',
                      label: 'Chính xác',
                      color: _performanceColor,
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      icon: Icons.timer_rounded,
                      value: _formatTime(timeSpent),
                      label: 'Thời gian',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Action buttons
              HMButton(
                text: 'Học tiếp',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onContinue();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
              ),
              
              const SizedBox(height: 12),
              
              HMButton(
                text: 'Hoàn thành',
                variant: HMButtonVariant.outline,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onFinish();
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? Colors.white54 : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 48,
      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}

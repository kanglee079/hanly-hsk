import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/exercise_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Matching pairs game widget - Stateful to prevent shuffle on rebuild
class ExerciseMatchingWidget extends StatefulWidget {
  final Exercise exercise;
  final bool isDark;
  final List<int> matchedLeft;
  final List<int> matchedRight;
  final int selectedLeft;
  final int selectedRight;
  final bool showWrongMatch;
  final int wrongLeft;
  final int wrongRight;
  final Function(int) onSelectLeft;
  final Function(int) onSelectRight;

  const ExerciseMatchingWidget({
    super.key,
    required this.exercise,
    required this.isDark,
    required this.matchedLeft,
    required this.matchedRight,
    required this.selectedLeft,
    required this.selectedRight,
    this.showWrongMatch = false,
    this.wrongLeft = -1,
    this.wrongRight = -1,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  @override
  State<ExerciseMatchingWidget> createState() => _ExerciseMatchingWidgetState();
}

class _ExerciseMatchingWidgetState extends State<ExerciseMatchingWidget>
    with TickerProviderStateMixin {
  late List<_MatchItem> _leftItems;
  late List<_MatchItem> _rightItems;
  
  // Animation controllers for wrong match shake
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeItems();
    _initAnimations();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _initializeItems() {
    final items = widget.exercise.matchingItems ?? [];
    _leftItems = items.map((e) => _MatchItem(index: e.leftIndex, text: e.leftText)).toList();
    _rightItems = items.map((e) => _MatchItem(index: e.rightIndex, text: e.rightText)).toList();
    // Shuffle only once
    _rightItems.shuffle();
  }

  @override
  void didUpdateWidget(ExerciseMatchingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if exercise changed
    if (widget.exercise != oldWidget.exercise) {
      _initializeItems();
    }
    // Trigger shake animation on wrong match
    if (widget.showWrongMatch && !oldWidget.showWrongMatch) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.exercise.matchingItems ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
              // Hint text
              _buildHintText(),
              
              const SizedBox(height: 16),
              
              // Column headers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'HANZI',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'NGHĨA',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF10B981),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Matching grid
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column (Hanzi)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _leftItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _leftItems[index];
                          final isMatched = widget.matchedLeft.contains(item.index);
                          final isSelected = widget.selectedLeft == item.index;
                          final isWrong = widget.showWrongMatch && widget.wrongLeft == item.index;
                          
                          return AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              double offset = 0;
                              if (isWrong) {
                                offset = math.sin(_shakeAnimation.value * math.pi * 4) * 8;
                              }
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: _buildMatchCard(
                              text: item.text,
                              isHanzi: true,
                              isMatched: isMatched,
                              isSelected: isSelected,
                              isWrong: isWrong,
                              onTap: (isMatched || widget.showWrongMatch) ? null : () {
                                HapticFeedback.lightImpact();
                                widget.onSelectLeft(item.index);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Right column (Meaning)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _rightItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _rightItems[index];
                          final isMatched = widget.matchedRight.contains(item.index);
                          final isSelected = widget.selectedRight == item.index;
                          final isWrong = widget.showWrongMatch && widget.wrongRight == item.index;
                          
                          return AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              double offset = 0;
                              if (isWrong) {
                                offset = math.sin(_shakeAnimation.value * math.pi * 4) * 8;
                              }
                              return Transform.translate(
                                offset: Offset(offset, 0),
                                child: child,
                              );
                            },
                            child: _buildMatchCard(
                              text: item.text,
                              isHanzi: false,
                              isMatched: isMatched,
                              isSelected: isSelected,
                              isWrong: isWrong,
                              onTap: (isMatched || widget.showWrongMatch) ? null : () {
                                HapticFeedback.lightImpact();
                                widget.onSelectRight(item.index);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Hint - fixed at bottom
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.showWrongMatch
                      ? AppColors.error.withValues(alpha: 0.1)
                      : (widget.isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.showWrongMatch
                        ? AppColors.error.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.showWrongMatch
                          ? Icons.close_rounded
                          : Icons.touch_app_rounded,
                      size: 18,
                      color: widget.showWrongMatch
                          ? AppColors.error
                          : (widget.isDark ? Colors.white70 : AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.showWrongMatch
                          ? 'Không đúng, thử lại!'
                          : 'Chọn 1 Hanzi và 1 nghĩa để ghép cặp',
                      style: AppTypography.bodySmall.copyWith(
                        color: widget.showWrongMatch
                            ? AppColors.error
                            : (widget.isDark ? Colors.white70 : AppColors.textSecondary),
                        fontWeight: widget.showWrongMatch ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHintText() {
    final matched = widget.matchedLeft.length;
    final total = widget.exercise.matchingItems?.length ?? 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.extension_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ghép cặp',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$matched/$total',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard({
    required String text,
    required bool isHanzi,
    required bool isMatched,
    required bool isSelected,
    required bool isWrong,
    VoidCallback? onTap,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    double borderWidth = 1.5;
    List<BoxShadow>? shadows;
    
    if (isWrong) {
      // Wrong match state - red
      bgColor = AppColors.error.withValues(alpha: 0.15);
      borderColor = AppColors.error;
      textColor = AppColors.error;
      borderWidth = 2;
    } else if (isMatched) {
      // Matched state - green
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      textColor = const Color(0xFF10B981);
    } else if (isSelected) {
      // Selected state - blue
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      borderColor = AppColors.primary;
      textColor = AppColors.primary;
      borderWidth = 2;
      shadows = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      // Default state
      bgColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
      borderColor = widget.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08);
      textColor = widget.isDark ? Colors.white : AppColors.textPrimary;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMatched) ...[
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (isWrong) ...[
              const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: isHanzi
                    ? TextStyle(
                        fontFamily: 'NotoSansSC',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      )
                    : AppTypography.bodyMedium.copyWith(color: textColor),
                child: Text(
                  isHanzi ? text : _capitalize(text),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchItem {
  final int index;
  final String text;
  
  _MatchItem({required this.index, required this.text});
}

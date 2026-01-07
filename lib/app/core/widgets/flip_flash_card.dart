import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'book_page_scaffold.dart';

/// A flip flash card widget with 3D rotation animation
/// Used in the Word Introduction flow
class FlipFlashCard extends StatefulWidget {
  final Widget frontContent;
  final Widget backContent;
  final bool isFlipped;
  final VoidCallback onFlip;
  final Duration flipDuration;

  const FlipFlashCard({
    super.key,
    required this.frontContent,
    required this.backContent,
    required this.isFlipped,
    required this.onFlip,
    this.flipDuration = const Duration(milliseconds: 400),
  });

  @override
  State<FlipFlashCard> createState() => _FlipFlashCardState();
}

class _FlipFlashCardState extends State<FlipFlashCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.flipDuration,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _flipAnimation.addListener(() {
      // Switch content at halfway point
      if (_flipAnimation.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_flipAnimation.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void didUpdateWidget(FlipFlashCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFlip();
      },
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          // Calculate rotation angle
          final angle = _flipAnimation.value * math.pi;
          
          // Determine which side to show
          final showingFront = _flipAnimation.value < 0.5;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(showingFront ? angle : angle - math.pi),
            child: showingFront ? widget.frontContent : widget.backContent,
          );
        },
      ),
    );
  }
}

/// Flash card specifically designed for vocabulary learning
/// Extends BookPageScaffold for consistent styling
class VocabFlashCard extends StatelessWidget {
  final String hanzi;
  final String pinyin;
  final String meaning;
  final String? wordType;
  final String? example;
  final String? examplePinyin;
  final String? exampleMeaning;
  final String? mnemonic;
  final bool isFlipped;
  final bool isDark;
  final VoidCallback onFlip;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onPlaySlow;

  const VocabFlashCard({
    super.key,
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    this.wordType,
    this.example,
    this.examplePinyin,
    this.exampleMeaning,
    this.mnemonic,
    required this.isFlipped,
    required this.isDark,
    required this.onFlip,
    this.onPlayAudio,
    this.onPlaySlow,
  });

  BookPageColors get _colors => BookPageColors(isDark: isDark);

  @override
  Widget build(BuildContext context) {
    return FlipFlashCard(
      isFlipped: isFlipped,
      onFlip: onFlip,
      frontContent: _buildFrontCard(),
      backContent: _buildBackCard(),
    );
  }

  Widget _buildFrontCard() {
    return BookPageScaffold(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          
          // Hanzi - main character
          Text(
            hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: _colors.textPrimary,
              fontSize: 80,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Pinyin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _colors.accentGold.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _colors.accentGold.withAlpha(60)),
            ),
            child: Text(
              pinyin,
              style: AppTypography.pinyin.copyWith(
                fontSize: 22,
                color: _colors.accentGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: _colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Nhấn để xem nghĩa',
                style: AppTypography.bodySmall.copyWith(
                  color: _colors.textTertiary,
                ),
              ),
            ],
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return BookPageScaffold(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enableScroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Hanzi + Pinyin + Audio
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hanzi,
                      style: AppTypography.hanziLarge.copyWith(
                        color: _colors.textPrimary,
                        fontSize: 42,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pinyin,
                      style: AppTypography.pinyin.copyWith(
                        fontSize: 16,
                        color: _colors.accentGold,
                      ),
                    ),
                  ],
                ),
              ),
              if (onPlayAudio != null)
                _buildAudioButton(
                  Icons.volume_up_rounded,
                  onPlayAudio!,
                  isPrimary: true,
                ),
              if (onPlaySlow != null) ...[
                const SizedBox(width: 8),
                _buildAudioButton(
                  Icons.slow_motion_video_rounded,
                  onPlaySlow!,
                  isPrimary: false,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Meaning
          _buildSection(
            icon: Icons.translate_rounded,
            title: 'Nghĩa',
            child: Text(
              meaning,
              style: AppTypography.headlineSmall.copyWith(
                color: _colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Word Type
          if (wordType != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                wordType!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Example
          if (example != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.format_quote_rounded,
              title: 'Ví dụ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example!,
                    style: TextStyle(
                      fontFamily: 'NotoSansSC',
                      fontSize: 16,
                      color: _colors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (examplePinyin != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      examplePinyin!,
                      style: AppTypography.pinyinSmall.copyWith(
                        color: _colors.accentGold.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (exampleMeaning != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      exampleMeaning!,
                      style: AppTypography.bodySmall.copyWith(
                        color: _colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Mnemonic
          if (mnemonic != null && mnemonic!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Mẹo nhớ',
              child: Text(
                mnemonic!,
                style: AppTypography.bodyMedium.copyWith(
                  color: _colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Tap hint
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: _colors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Nhấn để lật lại',
                  style: AppTypography.labelSmall.copyWith(
                    color: _colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _colors.accentGold),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: _colors.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildAudioButton(IconData icon, VoidCallback onTap, {required bool isPrimary}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? _colors.accentGold.withAlpha(20)
              : _colors.borderColor.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPrimary
                ? _colors.accentGold.withAlpha(60)
                : _colors.borderColor.withAlpha(60),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isPrimary ? _colors.accentGold : _colors.textSecondary,
        ),
      ),
    );
  }
}


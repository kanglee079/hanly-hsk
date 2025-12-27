import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/vocab_model.dart';

/// Capitalize first letter
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Widget to show learning content for a vocabulary word
class LearningContentWidget extends StatelessWidget {
  final VocabModel vocab;
  final bool isDark;
  final VoidCallback onContinue;
  final VoidCallback? onPlayAudio;
  final VoidCallback? onPlaySlow;
  final void Function(String text, String? audioUrl, bool slow)? onPlayExampleSentence;

  const LearningContentWidget({
    super.key,
    required this.vocab,
    required this.isDark,
    required this.onContinue,
    this.onPlayAudio,
    this.onPlaySlow,
    this.onPlayExampleSentence,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // Hanzi
                  Text(
                    vocab.hanzi,
                    style: AppTypography.hanziLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontSize: 72,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Pinyin
                  Text(
                    vocab.pinyin,
                    style: AppTypography.pinyin.copyWith(
                      fontSize: 24,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Meaning
                  Text(
                    _capitalize(vocab.meaningVi),
                    style: AppTypography.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Audio controls (Normal + Slow)
                  if (onPlayAudio != null || onPlaySlow != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (onPlayAudio != null)
                          _AudioPillButton(
                            icon: Icons.volume_up_rounded,
                            label: 'Nghe',
                            onTap: onPlayAudio!,
                          ),
                        if (onPlayAudio != null && onPlaySlow != null)
                          const SizedBox(width: 12),
                        if (onPlaySlow != null)
                          _AudioPillButton(
                            icon: Icons.slow_motion_video_rounded,
                            label: 'Chậm',
                            onTap: onPlaySlow!,
                          ),
                      ],
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Hanzi DNA
                  if (vocab.hanziDna != null) _buildHanziDna(),
                  
                  // Mnemonic
                  if (vocab.mnemonic != null && vocab.mnemonic!.isNotEmpty)
                    _buildMnemonic(),
                  
                  // Examples
                  if (vocab.examples.isNotEmpty) _buildExamples(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Continue button
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                HMButton(
                  text: 'Tiếp tục',
                  onPressed: onContinue,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHanziDna() {
    final dna = vocab.hanziDna!;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cấu tạo chữ',
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Radical
          if (dna.radical != null)
            _buildDnaRow('Bộ thủ', '${dna.radical} (${dna.radicalMeaning ?? ""})'),
          
          // Stroke count
          _buildDnaRow('Số nét', '${dna.strokeCount} nét'),
          
          // Components
          if (dna.components.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Thành phần:',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dna.components.map<Widget>((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Text(
                  c.toString(),
                  style: AppTypography.hanziSmall.copyWith(
                    fontSize: 20,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDnaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonic() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.secondary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mẹo nhớ',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vocab.mnemonic!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ví dụ',
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...vocab.examples.take(2).map((example) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Example audio (always visible; may fallback to TTS)
              if (onPlayExampleSentence != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ExampleAudioButton(
                      icon: Icons.volume_up_rounded,
                      onTap: () => onPlayExampleSentence!(
                        example.hanzi,
                        example.audioUrl,
                        false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ExampleAudioButton(
                      icon: Icons.slow_motion_video_rounded,
                      onTap: () => onPlayExampleSentence!(
                        example.hanzi,
                        example.audioUrl,
                        true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(
                example.hanzi,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (example.pinyin.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  example.pinyin,
                  style: AppTypography.pinyinSmall.copyWith(
                    color: AppColors.primary.withAlpha(180),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                _capitalize(example.meaningVi),
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _AudioPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AudioPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleAudioButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ExampleAudioButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}


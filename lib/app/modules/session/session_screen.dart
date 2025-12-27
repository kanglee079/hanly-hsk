import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/today_model.dart';
import '../today/today_controller.dart';
import 'session_controller.dart';

/// Capitalize first letter of Vietnamese text
String capitalizeFirst(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// Get session mode label
String _getSessionModeLabel(SessionMode mode) {
  switch (mode) {
    case SessionMode.newWords:
      return S.newWords;
    case SessionMode.review:
      return 'Từ ôn';
    case SessionMode.reviewToday:
      return 'Ôn từ hôm nay';
    case SessionMode.game30:
      return 'Trò chơi';
  }
}

/// Session screen with 5-step flow
class SessionScreen extends GetView<SessionController> {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
        appBar: HMAppBar(
        showBackButton: true,
        onBackPressed: controller.exitSession,
        titleWidget: Obx(() => HMLinearStepIndicator(
              totalSteps: 6, // 6 steps now including pronunciation
              currentStep: controller.currentStep.value + 1,
            )),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '${(controller.elapsedSeconds.value ~/ 60).toString().padLeft(2, '0')}:${(controller.elapsedSeconds.value % 60).toString().padLeft(2, '0')}',
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isSessionComplete.value) {
          return _buildCompleteScreen(isDark);
        }

        final vocab = controller.currentVocab;
        if (vocab == null) {
          return const Center(child: Text('Không có từ vựng'));
        }

        return Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: controller.progress,
              backgroundColor:
                  isDark ? AppColors.surfaceVariantDark : AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),

            // Main content - FIXED height to prevent layout jumps
            Expanded(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: _buildStepContent(vocab, isDark),
              ),
            ),

            // Bottom action - FIXED at bottom
            _buildBottomAction(isDark),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent(dynamic vocab, bool isDark) {
    switch (controller.currentStepEnum) {
      case SessionStep.guess:
        return _GuessStep(vocab: vocab, isDark: isDark, controller: controller);
      case SessionStep.audio:
        return _AudioStep(vocab: vocab, isDark: isDark, controller: controller);
      case SessionStep.hanziDna:
        return _HanziDnaStep(vocab: vocab, isDark: isDark, controller: controller);
      case SessionStep.context:
        return _ContextStep(vocab: vocab, isDark: isDark, controller: controller);
      case SessionStep.pronunciation:
        return _PronunciationStep(vocab: vocab, isDark: isDark, controller: controller);
      case SessionStep.quiz:
        return _QuizStep(vocab: vocab, isDark: isDark, controller: controller);
    }
  }

  Widget _buildBottomAction(bool isDark) {
    return Obx(() {
      final isQuizStep = controller.currentStepEnum == SessionStep.quiz;
      final isPronunciationStep = controller.currentStepEnum == SessionStep.pronunciation;
      final isReviewMode = controller.sessionMode == SessionMode.review;
      final needsReveal = controller.needsRevealButton;

      return SafeArea(
        child: Container(
          // Fixed height container to prevent layout jumps
          constraints: const BoxConstraints(minHeight: 120),
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isQuizStep && controller.hasAnswered.value && isReviewMode)
                // Rating buttons for review
                _RatingButtons(controller: controller, isDark: isDark)
              else if (isQuizStep && controller.hasAnswered.value)
                HMButton(
                  text: S.next,
                  onPressed: controller.nextStep,
                )
              else if (isPronunciationStep)
                // Pronunciation step - show pass/skip buttons if has result
                _PronunciationBottomAction(controller: controller, isDark: isDark)
              else if (!isQuizStep && !needsReveal)
                // Steps that don't need reveal (hanziDna, context) or already revealed
                HMButton(
                  text: S.next,
                  onPressed: controller.nextStep,
                )
              else if (!isQuizStep && needsReveal)
                HMButton(
                  text: S.reveal,
                  onPressed: controller.reveal,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCompleteScreen(bool isDark) {
    final accuracy = controller.totalQuizzes > 0
        ? (controller.correctCount / controller.totalQuizzes * 100).round()
        : 100;

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.sessionComplete,
              style: AppTypography.displaySmall.copyWith(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  value: '${(controller.elapsedSeconds.value / 60).ceil()}',
                  label: S.minutesLearned,
                  isDark: isDark,
                ),
                _StatItem(
                  value: '${controller.queue.length}',
                  label: _getSessionModeLabel(controller.sessionMode),
                  isDark: isDark,
                ),
                _StatItem(
                  value: '$accuracy%',
                  label: S.accuracy,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 48),
            // Continue Learning button (only for new words mode)
            if (controller.sessionMode == SessionMode.newWords)
              Obx(() => controller.isLoadingMore.value 
                ? const CircularProgressIndicator()
                : HMButton(
                    text: 'Học tiếp',
                    onPressed: controller.continueSession,
                    icon: const Icon(Icons.arrow_forward, size: 20),
                  ),
              ),
            if (controller.sessionMode == SessionMode.newWords)
              const SizedBox(height: 12),
            HMButton(
              text: S.done,
              variant: controller.sessionMode == SessionMode.newWords 
                  ? HMButtonVariant.outline 
                  : HMButtonVariant.primary,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuessStep extends StatelessWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _GuessStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vocab.hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Fixed height container for revealed content to prevent layout jumps
          SizedBox(
            height: 100,
            child: Obx(() {
              if (controller.isRevealed.value) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vocab.pinyin,
                      style: AppTypography.pinyin.copyWith(
                        fontSize: 24,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      capitalizeFirst(vocab.meaningVi),
                      style: AppTypography.headlineMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }
              return Center(
                child: Text(
                  'Bạn có nhớ nghĩa không?',
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AudioStep extends StatelessWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _AudioStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasSlowAudio = vocab.audioSlowUrl != null && vocab.audioSlowUrl!.isNotEmpty;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            vocab.hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            vocab.pinyin,
            style: AppTypography.pinyin.copyWith(
              fontSize: 20,
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          // Audio buttons - Normal and Slow
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Normal speed
              _AudioButton(
                icon: Icons.volume_up_rounded,
                label: 'Bình thường',
                onTap: () => controller.playAudio(),
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              // Slow speed
              _AudioButton(
                icon: Icons.slow_motion_video_rounded,
                label: 'Chậm',
                onTap: hasSlowAudio ? () => controller.playAudio(slow: true) : null,
                isDark: isDark,
                enabled: hasSlowAudio,
              ),
            ],
          ),
          // Fixed height for meaning to prevent layout jumps
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: Obx(() {
              if (controller.isRevealed.value) {
                return Center(
                  child: Text(
                    capitalizeFirst(vocab.meaningVi),
                    style: AppTypography.headlineSmall.copyWith(
                      color:
                          isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ),
        ],
      ),
    );
  }
}

/// Audio button widget
class _AudioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool enabled;

  const _AudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: enabled 
                    ? AppColors.primary.withAlpha(20) 
                    : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: enabled 
                      ? AppColors.primary.withAlpha(50) 
                      : (isDark ? AppColors.borderDark : AppColors.border),
                ),
              ),
              child: Icon(
                icon,
                size: 28,
                color: enabled 
                    ? AppColors.primary 
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: enabled 
                    ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HanziDnaStep extends StatelessWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _HanziDnaStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final dna = vocab.hanziDna;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            vocab.hanzi,
            style: AppTypography.hanziMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          if (dna != null) ...[
            if (dna.radical != null)
              _DnaItem(
                label: S.radical,
                value: '${dna.radical} (${dna.radicalMeaning ?? ""})',
                isDark: isDark,
              ),
            const SizedBox(height: 16),
            _DnaItem(
              label: S.strokeCount,
              value: '${dna.strokeCount} nét',
              isDark: isDark,
            ),
            if (dna.components.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                S.components,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (dna.components as List<dynamic>)
                    .map<Widget>((c) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariant,
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Text(
                            c.toString(),
                            style: AppTypography.hanziSmall.copyWith(
                              fontSize: 24,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
          if (vocab.mnemonic != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight.withAlpha(50),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.mnemonic,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab.mnemonic!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DnaItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DnaItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodyMedium.copyWith(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ContextStep extends StatefulWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _ContextStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  State<_ContextStep> createState() => _ContextStepState();
}

class _ContextStepState extends State<_ContextStep> {
  FlutterTts? _tts;
  String? _speakingText;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts?.setLanguage('zh-CN');
    await _tts?.setSpeechRate(0.4);
    await _tts?.setVolume(1.0);
    
    _tts?.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _speakingText = null;
        });
      }
    });
  }

  Future<void> _speakExample(String text) async {
    if (_isSpeaking && _speakingText == text) {
      await _tts?.stop();
      setState(() {
        _isSpeaking = false;
        _speakingText = null;
      });
      return;
    }
    
    setState(() {
      _isSpeaking = true;
      _speakingText = text;
    });
    await _tts?.speak(text);
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final vocab = widget.vocab;
    final collocations = vocab.collocations as List<dynamic>? ?? [];
    final examples = vocab.examples as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  vocab.hanzi,
                  style: AppTypography.hanziMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  capitalizeFirst(vocab.meaningVi),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (collocations.isNotEmpty) ...[
            Text(
              S.collocations,
              style: AppTypography.titleSmall.copyWith(
                color:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: collocations.map<Widget>((c) => HMChip(
                    label: c.toString(),
                    backgroundColor: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                  )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (examples.isNotEmpty) ...[
            Text(
              S.examples,
              style: AppTypography.titleSmall.copyWith(
                color:
                    isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ...examples.map<Widget>((e) {
              final hasPinyin = e.pinyin != null && e.pinyin!.isNotEmpty;
              final exampleText = e.hanzi ?? '';
              final isCurrentSpeaking = _isSpeaking && _speakingText == exampleText;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HMCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chinese sentence
                                Text(
                                  exampleText,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Pinyin (only if available)
                                if (hasPinyin) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    e.pinyin!,
                                    style: AppTypography.pinyinSmall.copyWith(
                                      color: AppColors.primary.withAlpha(180),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Audio button for example
                          if (exampleText.isNotEmpty)
                            GestureDetector(
                              onTap: () => _speakExample(exampleText),
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: isCurrentSpeaking
                                      ? AppColors.primary.withAlpha(30)
                                      : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  isCurrentSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                  size: 20,
                                  color: isCurrentSpeaking 
                                      ? AppColors.primary 
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Vietnamese translation
                      const SizedBox(height: 8),
                      Text(
                        capitalizeFirst(e.meaningVi ?? ''),
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Pronunciation step - user speaks the word (compact UI)
class _PronunciationStep extends StatelessWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _PronunciationStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word display - compact
          Text(
            vocab.hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vocab.pinyin,
            style: AppTypography.pinyin.copyWith(
              fontSize: 20,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            capitalizeFirst(vocab.meaningVi),
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Audio buttons - inline compact
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CompactAudioButton(
                icon: Icons.volume_up_rounded,
                label: 'Nghe mẫu',
                onTap: () => controller.playAudio(),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _CompactAudioButton(
                icon: Icons.slow_motion_video_rounded,
                label: 'Chậm',
                onTap: () => controller.playAudio(slow: true),
                isDark: isDark,
                enabled: vocab.audioSlowUrl != null && vocab.audioSlowUrl!.isNotEmpty,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Microphone button
          Obx(() {
            final isListening = controller.isListening.value;
            final isEvaluating = controller.isEvaluatingPronunciation.value;
            
            return GestureDetector(
              onTap: isEvaluating ? null : controller.startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isListening ? 80 : 70,
                height: isListening ? 80 : 70,
                decoration: BoxDecoration(
                  color: isListening 
                      ? AppColors.error 
                      : (isEvaluating ? AppColors.warning : AppColors.primary),
                  shape: BoxShape.circle,
                  boxShadow: isListening ? [
                    BoxShadow(
                      color: AppColors.error.withAlpha(100),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ] : null,
                ),
                child: isEvaluating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: isListening ? 36 : 30,
                        color: Colors.white,
                      ),
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Status text
          Obx(() {
            if (controller.isListening.value) {
              return Text(
                '🎤 Đang nghe...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            if (!controller.hasPronunciationResult.value) {
              return Text(
                'Nhấn mic và đọc từ trên',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          const SizedBox(height: 16),
          
          // Result feedback - compact
          Obx(() {
            if (!controller.hasPronunciationResult.value) {
              return const SizedBox.shrink();
            }
            
            final passed = controller.isPronunciationPassed.value;
            final score = controller.pronunciationScore.value;
            final feedback = controller.pronunciationFeedback.value;
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: passed 
                    ? AppColors.success.withAlpha(20) 
                    : AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: passed 
                      ? AppColors.success.withAlpha(50) 
                      : AppColors.warning.withAlpha(50),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    passed ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: passed ? AppColors.success : AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$score điểm',
                    style: AppTypography.titleMedium.copyWith(
                      color: passed ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (feedback.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '- $feedback',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark 
                              ? AppColors.textSecondaryDark 
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          
          // Note about simulator
          Obx(() {
            if (!controller.hasPronunciationResult.value && !controller.isListening.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '⚠️ Trên Simulator: Dùng nút "Xác nhận" bên dưới',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warning,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

/// Compact audio button for pronunciation step
class _CompactAudioButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final bool enabled;

  const _CompactAudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: enabled 
                ? AppColors.primary.withAlpha(15) 
                : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled 
                  ? AppColors.primary.withAlpha(40) 
                  : (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled 
                    ? AppColors.primary 
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: enabled 
                      ? AppColors.primary 
                      : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom action for pronunciation step
class _PronunciationBottomAction extends StatelessWidget {
  final SessionController controller;
  final bool isDark;

  const _PronunciationBottomAction({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasPronunciationResult = controller.hasPronunciationResult.value;
      final isPassed = controller.isPronunciationPassed.value;
      final hasListened = controller.hasListenedAudio.value;
      
      if (hasPronunciationResult && isPassed) {
        // Passed - show next button
        return HMButton(
          text: S.next,
          onPressed: controller.nextStep,
        );
      }
      
      if (hasPronunciationResult && !isPassed) {
        // Not passed - show retry and skip buttons
        return Row(
          children: [
            Expanded(
              child: HMButton(
                text: 'Thử lại',
                variant: HMButtonVariant.outline,
                onPressed: controller.retryPronunciation,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HMButton(
                text: 'Tiếp tục',
                onPressed: controller.nextStep,
              ),
            ),
          ],
        );
      }
      
      // No result yet - show manual confirm and skip options
      // Manual confirm requires listening to audio first
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info text
          if (!hasListened)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '👆 Nghe audio trước khi xác nhận',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: HMButton(
                  text: hasListened ? '✓ Xác nhận đọc đúng' : 'Xác nhận',
                  variant: HMButtonVariant.outline,
                  onPressed: hasListened ? controller.manualPassPronunciation : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HMButton(
                  text: 'Bỏ qua',
                  variant: HMButtonVariant.secondary,
                  onPressed: controller.nextStep,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _QuizStep extends StatelessWidget {
  final dynamic vocab;
  final bool isDark;
  final SessionController controller;

  const _QuizStep({
    required this.vocab,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            vocab.hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn nghĩa đúng:',
            style: AppTypography.bodyMedium.copyWith(
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Obx(() => Column(
                children: List.generate(
                  controller.quizOptions.length,
                  (index) {
                    final option = controller.quizOptions[index];
                    final isSelected = controller.selectedAnswer.value == index;
                    final hasAnswered = controller.hasAnswered.value;
                    final isCorrect = option == vocab.meaningVi;

                    Color? bgColor;
                    Color? borderColor;
                    if (hasAnswered) {
                      if (isCorrect) {
                        bgColor = AppColors.successLight;
                        borderColor = AppColors.success;
                      } else if (isSelected) {
                        bgColor = AppColors.errorLight;
                        borderColor = AppColors.error;
                      }
                    } else if (isSelected) {
                      borderColor = AppColors.primary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: hasAnswered
                            ? null
                            : () => controller.selectAnswer(index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: bgColor ??
                                (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surface),
                            borderRadius: AppSpacing.borderRadiusMd,
                            border: Border.all(
                              color: borderColor ??
                                  (isDark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                              width: isSelected || (hasAnswered && isCorrect)
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  // Capitalize Vietnamese text
                                  capitalizeFirst(option),
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (hasAnswered && isCorrect)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                ),
                              if (hasAnswered && isSelected && !isCorrect)
                                const Icon(
                                  Icons.cancel_rounded,
                                  color: AppColors.error,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  final SessionController controller;
  final bool isDark;

  const _RatingButtons({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show feedback overlay when rating was just submitted
      if (controller.showingRatingFeedback.value) {
        final response = controller.lastRatingResponse.value;
        return _RatingFeedback(response: response, isDark: isDark);
      }

      final vocab = controller.currentVocab;
      
      return Column(
        children: [
          // Show current SRS info if available
          if (vocab?.state != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStateIcon(vocab?.state),
                    size: 14,
                    color: _getStateColor(vocab?.state),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vocab?.stateDisplay ?? 'Mới',
                    style: AppTypography.labelSmall.copyWith(
                      color: _getStateColor(vocab?.state),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (vocab?.reps != null && vocab!.reps! > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${vocab.reps} lần ôn',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Bạn nhớ từ này như thế nào?',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _RatingButton(
                label: S.rateAgain,
                color: AppColors.ratingAgain,
                onTap: () => controller.submitRating(ReviewRating.again),
              ),
              const SizedBox(width: 8),
              _RatingButton(
                label: S.rateHard,
                color: AppColors.ratingHard,
                onTap: () => controller.submitRating(ReviewRating.hard),
              ),
              const SizedBox(width: 8),
              _RatingButton(
                label: S.rateGood,
                color: AppColors.ratingGood,
                onTap: () => controller.submitRating(ReviewRating.good),
              ),
              const SizedBox(width: 8),
              _RatingButton(
                label: S.rateEasy,
                color: AppColors.ratingEasy,
                onTap: () => controller.submitRating(ReviewRating.easy),
              ),
            ],
          ),
        ],
      );
    });
  }

  IconData _getStateIcon(String? state) {
    switch (state) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'review':
        return Icons.refresh_rounded;
      case 'mastered':
        return Icons.verified_rounded;
      default:
        return Icons.fiber_new_rounded;
    }
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

class _RatingFeedback extends StatelessWidget {
  final ReviewAnswerResponse? response;
  final bool isDark;

  const _RatingFeedback({this.response, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final intervalDays = response?.intervalDays ?? 0;
    final newState = response?.state ?? 'learning';
    
    String intervalText;
    if (intervalDays == 0) {
      intervalText = 'Hôm nay';
    } else if (intervalDays == 1) {
      intervalText = 'Ngày mai';
    } else {
      intervalText = '$intervalDays ngày';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStateIcon(newState),
            size: 36,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          Text(
            'Đã lưu!',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ôn lại sau: $intervalText',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStateIcon(String state) {
    switch (state) {
      case 'learning':
        return Icons.school_rounded;
      case 'review':
        return Icons.refresh_rounded;
      case 'mastered':
        return Icons.emoji_events_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

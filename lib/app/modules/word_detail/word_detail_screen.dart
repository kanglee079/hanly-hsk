import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../routes/app_routes.dart';
import '../../data/models/vocab_model.dart';
import 'word_detail_controller.dart';

/// Word detail screen - redesigned with real data
class WordDetailScreen extends GetView<WordDetailController> {
  const WordDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        title: Text(
          'Word Detail',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final vocab = controller.vocab.value;
        final isLoading = controller.isLoading.value;
        final hasError = controller.hasError.value;

        if (vocab == null && isLoading) {
          return const HMLoadingContent(
            message: 'Đang tải từ vựng...',
            icon: Icons.translate_rounded,
          );
        }

        if (vocab == null && hasError) {
          return HMEmptyState(
            icon: Icons.error_outline,
            title: 'Không thể tải',
            description: 'Vui lòng thử lại sau.',
            actionLabel: 'Thử lại',
            onAction: controller.retry,
          );
        }

        if (vocab == null) {
          return const HMLoadingContent(icon: Icons.translate_rounded);
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== MAIN WORD SECTION =====
              _buildMainWordSection(vocab, isDark),

              const SizedBox(height: 16),

              // ===== AUDIO CONTROLS =====
              _buildAudioControls(vocab, isDark),

              const SizedBox(height: 20),

              // ===== IMAGE CAROUSEL =====
              if (vocab.images.isNotEmpty) _buildImageCarousel(vocab, isDark),

              const SizedBox(height: 20),

              // ===== QUICK ACTIONS =====
              _buildQuickActions(vocab, isDark),

              const SizedBox(height: 24),

              Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HANZI DNA =====
                    _buildHanziDnaSection(vocab, isDark),

                    const SizedBox(height: 20),

                    // ===== EXAMPLES =====
                    if (vocab.examples.isNotEmpty)
                      _buildExamplesSection(vocab, isDark),

                    const SizedBox(height: 16),

                    // ===== USAGE NOTES =====
                    if (vocab.usageNotes != null && vocab.usageNotes!.isNotEmpty)
                      _buildExpandableSection(
                        icon: Icons.tips_and_updates_outlined,
                        iconColor: AppColors.primary,
                        title: 'Ghi chú sử dụng',
                        content: vocab.usageNotes!,
                        isExpanded: controller.meaningExpanded.value,
                        onToggle: () => controller.toggleSection('meaning'),
                        isDark: isDark,
                      ),

                    const SizedBox(height: 12),

                    // ===== GRAMMAR =====
                    if (vocab.grammarNotes != null && vocab.grammarNotes!.isNotEmpty)
                      _buildExpandableSection(
                        icon: Icons.menu_book_outlined,
                        iconColor: AppColors.secondary,
                        title: 'Ngữ pháp',
                        content: vocab.grammarNotes!,
                        isExpanded: controller.hanziDnaExpanded.value,
                        onToggle: () => controller.toggleSection('hanziDna'),
                        isDark: isDark,
                      ),

                    const SizedBox(height: 12),

                    // ===== HSK TIPS =====
                    if (vocab.hskTips != null && vocab.hskTips!.isNotEmpty)
                      _buildExpandableSection(
                        icon: Icons.school_outlined,
                        iconColor: AppColors.success,
                        title: 'Mẹo HSK',
                        content: vocab.hskTips!,
                        isExpanded: controller.contextExpanded.value,
                        onToggle: () => controller.toggleSection('context'),
                        isDark: isDark,
                      ),

                    const SizedBox(height: 24),

                    // ===== METADATA GRID =====
                    _buildMetadataGrid(vocab, isDark),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainWordSection(VocabModel vocab, bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Center(
        child: Column(
          children: [
            // Large Hanzi
            Text(
              vocab.hanzi,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // Pinyin
            Text(
              vocab.pinyin,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            // Meanings
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
                children: [
                  const TextSpan(
                    text: '(VI) ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: vocab.meaningVi),
                  if (vocab.meaningEn != null && vocab.meaningEn!.isNotEmpty) ...[
                    const TextSpan(text: '  •  '),
                    const TextSpan(
                      text: '(EN) ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: vocab.meaningEn),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls(VocabModel vocab, bool isDark) {
    final hasAudio = vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty;
    final hasSlowAudio = vocab.audioSlowUrl != null && vocab.audioSlowUrl!.isNotEmpty;

    if (!hasAudio && !hasSlowAudio) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Normal speed button (1x)
          if (hasAudio)
            GestureDetector(
              onTap: () => controller.playAudio(slow: false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '1x',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (hasAudio && hasSlowAudio) const SizedBox(width: 12),

          // Slow speed button
          if (hasSlowAudio)
            GestureDetector(
              onTap: () => controller.playAudio(slow: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.slow_motion_video_rounded,
                      size: 22,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Chậm',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(VocabModel vocab, bool isDark) {
    return Column(
      children: [
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              itemCount: vocab.images.length,
              onPageChanged: (index) => controller.setImageIndex(index),
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: vocab.images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(
                          child: HMLoadingIndicator.small(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        ),
                      ),
                    ),

                    // Visual Context badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Visual Context',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Dots indicator
        if (vocab.images.length > 1) ...[
          const SizedBox(height: 12),
          Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  vocab.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == controller.currentImageIndex.value
                          ? AppColors.primary
                          : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildQuickActions(VocabModel vocab, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Favorite
          _QuickActionButton(
            icon: vocab.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: 'Yêu thích',
            isActive: vocab.isFavorite,
            activeColor: AppColors.favorite,
            onTap: controller.toggleFavorite,
            isDark: isDark,
          ),

          // Add to Deck
          _QuickActionButton(
            icon: Icons.add_circle_outline,
            label: 'Thêm vào bộ',
            onTap: () => Get.toNamed(Routes.decks),
            isDark: isDark,
          ),

          // Practice
          _QuickActionButton(
            icon: Icons.school_outlined,
            label: 'Luyện tập',
            isActive: true,
            activeColor: AppColors.primary,
            onTap: () => Get.toNamed(Routes.practice, arguments: {
              'mode': 'learnNew',
              'vocabId': vocab.id,
            }),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHanziDnaSection(VocabModel vocab, bool isDark) {
    final dna = vocab.hanziDna;
    final strokeCount = dna?.strokeCount ?? 0;
    final components = dna?.components ?? <String>[];
    final radical = dna?.radical ?? '';
    final mnemonic = vocab.mnemonic;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hanzi DNA',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                'Total $strokeCount Strokes',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Component breakdown - CENTERED and ALIGNED
          if (components.isNotEmpty || radical.isNotEmpty)
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Radical first if exists
                    if (radical.isNotEmpty) ...[
                      _ComponentBox(
                        char: radical,
                        isDark: isDark,
                      ),
                      _buildOperator('+', isDark),
                    ],
                    
                    // Components - extract only the first character
                    ...components.take(2).toList().asMap().entries.map((entry) {
                      final componentsList = components.take(2).toList();
                      final isLast = entry.key == (componentsList.length - 1);
                      // Extract only the Chinese character (first char before space or parenthesis)
                      final fullText = entry.value;
                      final charOnly = fullText.split(' ').first.split('(').first.trim();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _ComponentBox(
                            char: charOnly.isNotEmpty ? charOnly : fullText,
                            isDark: isDark,
                          ),
                          if (!isLast) _buildOperator('+', isDark),
                        ],
                      );
                    }),

                    // Arrow and result
                    _buildOperator('→', isDark),
                    _ComponentBox(
                      char: vocab.hanzi.length > 1 ? vocab.hanzi[0] : vocab.hanzi,
                      isHighlighted: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

          // Mnemonic
          if (mnemonic != null && mnemonic.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Mnemonic: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: mnemonic),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOperator(String op, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        op,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildExamplesSection(VocabModel vocab, bool isDark) {
    return Obx(() {
      final showAll = controller.examplesExpanded.value;
      final examples = showAll ? vocab.examples : vocab.examples.take(1).toList();

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examples',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Examples list
            ...examples.asMap().entries.map((entry) {
              final index = entry.key;
              final example = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < examples.length - 1 ? 16 : 0),
                child: _ExampleItem(
                  example: example,
                  onSpeak: () => controller.speakText(example.hanzi),
                  isSpeaking: controller.isTextSpeaking(example.hanzi),
                  isDark: isDark,
                ),
              );
            }),

            // Show more/less
            if (vocab.examples.length > 1) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => controller.examplesExpanded.value = !showAll,
                child: Row(
                  children: [
                    Text(
                      showAll
                          ? 'Ẩn bớt'
                          : 'Hiện ${vocab.examples.length - 1} ví dụ khác',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      showAll ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildExpandableSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataGrid(VocabModel vocab, bool isDark) {
    return Column(
      children: [
        // Row 1: Level & Frequency
        Row(
          children: [
            Expanded(
              child: _MetadataItem(
                icon: 'Lvl',
                isIconText: true,
                label: 'HSK OFFICIAL',
                value: 'Level ${vocab.levelInt}',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetadataItem(
                icon: Icons.trending_up,
                label: 'FREQUENCY',
                value: vocab.frequencyRank > 0 ? 'Top ${vocab.frequencyRank}' : 'N/A',
                iconColor: AppColors.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 2: Type & Difficulty
        Row(
          children: [
            Expanded(
              child: _MetadataItem(
                icon: Icons.label_outline,
                label: 'TYPE',
                value: vocab.wordType ?? 'N/A',
                iconColor: AppColors.secondary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetadataItem(
                icon: Icons.speed_outlined,
                label: 'DIFFICULTY',
                value: _getDifficultyLabel(vocab.difficultyScore),
                iconColor: AppColors.success,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDifficultyLabel(int score) {
    switch (score) {
      case 1:
        return 'Dễ';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khó';
      case 4:
        return 'Rất khó';
      case 5:
        return 'Chuyên gia';
      default:
        return 'Trung bình';
    }
  }
}

// ===== HELPER WIDGETS =====

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? (activeColor ?? AppColors.primary)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(16),
              border: isActive
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? (activeColor ?? AppColors.primary)
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentBox extends StatelessWidget {
  final String char;
  final bool isHighlighted;
  final bool isDark;

  const _ComponentBox({
    required this.char,
    this.isHighlighted = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? null
            : Border.all(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFE2E8F0),
              ),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isHighlighted
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}

class _ExampleItem extends StatelessWidget {
  final ExampleModel example;
  final VoidCallback onSpeak;
  final bool isSpeaking;
  final bool isDark;

  const _ExampleItem({
    required this.example,
    required this.onSpeak,
    required this.isSpeaking,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chinese sentence
          Text(
            example.hanzi,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // Pinyin + Audio button
          Row(
            children: [
              Expanded(
                child: Text(
                  example.pinyin.isNotEmpty
                      ? example.pinyin
                      : 'Pinyin không khả dụng',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? AppColors.primary.withAlpha(20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                    size: 20,
                    color: isSpeaking
                        ? AppColors.primary
                        : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Vietnamese translation
          Text(
            example.meaningVi,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  final dynamic icon;
  final bool isIconText;
  final String label;
  final String value;
  final Color? iconColor;
  final bool isDark;

  const _MetadataItem({
    required this.icon,
    this.isIconText = false,
    required this.label,
    required this.value,
    this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.secondary).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isIconText
                ? Text(
                    icon.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconColor ?? AppColors.secondary,
                    ),
                  )
                : Icon(
                    icon as IconData,
                    size: 18,
                    color: iconColor ?? AppColors.secondary,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

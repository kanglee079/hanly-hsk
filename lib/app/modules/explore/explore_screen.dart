import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/date_format.dart';
import '../../data/models/vocab_model.dart';
import '../../data/models/collection_model.dart';
import '../../services/tutorial_service.dart';
import 'explore_controller.dart';
import 'widgets/explore_filter_sheet.dart';

/// Explore tab screen - matches the target design
class ExploreScreen extends GetView<ExploreController> {
  const ExploreScreen({super.key});

  // Get registered keys from TutorialService
  GlobalKey get _searchKey =>
      Get.find<TutorialService>().registerKey('explore_search');
  GlobalKey get _hskLevelsKey =>
      Get.find<TutorialService>().registerKey('explore_hsk_levels');
  GlobalKey get _dailyPickKey =>
      Get.find<TutorialService>().registerKey('explore_daily_pick');
  GlobalKey get _collectionsKey =>
      Get.find<TutorialService>().registerKey('explore_collections');
  GlobalKey get _recentKey =>
      Get.find<TutorialService>().registerKey('explore_recent');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.showSearchResults.value) {
            return _buildSearchResultsView(context, isDark);
          }
          return _buildMainView(isDark);
        }),
      ),
    );
  }

  Widget _buildMainView(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          _buildHeader(isDark),

          const SizedBox(height: 16),

          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Showcase(
                  key: _searchKey,
                  title: 'Tìm kiếm từ vựng',
                  description:
                      'Gõ bất kỳ từ tiếng Trung, pinyin hoặc tiếng Việt để tra cứu.',
                  overlayOpacity: 0.7,
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildSearchBar(isDark),
                ),

                const SizedBox(height: 16),

                // Filter chips (HSK Levels)
                Showcase(
                  key: _hskLevelsKey,
                  title: 'Cấp độ HSK',
                  description:
                      'Học theo từng cấp HSK từ 1 đến 6, phù hợp với trình độ của bạn.',
                  overlayOpacity: 0.7,
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildFilterChips(isDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== TỪ VỰNG HÔM NAY =====
          Showcase(
            key: _dailyPickKey,
            title: 'Từ vựng hôm nay',
            description:
                'Mỗi ngày app sẽ gợi ý từ mới phù hợp với cấp độ của bạn!',
            overlayOpacity: 0.7,
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Obx(() => _buildDailyPickSection(isDark)),
          ),

          const SizedBox(height: 24),

          // ===== BỘ SƯU TẬP =====
          Showcase(
            key: _collectionsKey,
            title: 'Bộ sưu tập',
            description:
                'Khám phá các bài học được sắp xếp theo chủ đề và cấp độ.',
            overlayOpacity: 0.7,
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildCollectionsSection(isDark),
          ),

          const SizedBox(height: 24),

          // ===== GẦN ĐÂY =====
          Showcase(
            key: _recentKey,
            title: 'Gần đây',
            description: 'Xem lại các từ bạn đã tra cứu hoặc học gần đây.',
            overlayOpacity: 0.7,
            targetShapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Obx(() => _buildRecentSection(isDark)),
          ),

          // Bottom padding for glass nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Back button + Search
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.clearSearch,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSearchBar(isDark, isActive: true)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showFilterSheet(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Results header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      'KẾT QUẢ (${controller.vocabs.length})',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Row(
                      children: [
                        Obx(
                          () => Text(
                            _getSortLabel(controller.sortBy.value),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Results list
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value || controller.isSearching.value) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 5,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: HMSkeletonCard(height: 100),
                ),
              );
            }

            if (controller.vocabs.isEmpty) {
              return HMEmptyState(
                icon: Icons.search_off_rounded,
                title: S.noResults,
                description: 'Thử tìm kiếm với từ khóa khác',
                actionLabel: S.clearFilter,
                onAction: controller.clearFilters,
              );
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  controller.loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
                itemCount:
                    controller.vocabs.length +
                    (controller.isLoadingMore.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.vocabs.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: HMLoadingIndicator.small()),
                    );
                  }

                  final vocab = controller.vocabs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VocabCard(
                      vocab: vocab,
                      isDark: isDark,
                      onTap: () => controller.openVocabDetail(vocab),
                      onAdd: () => controller.toggleFavorite(vocab),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding.copyWith(top: 8, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormatUtil.formatDayFull(DateTime.now()).toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
          Text(
            S.explore,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, {bool isActive = false}) {
    if (isActive) {
      // Active search mode with TextField - use Obx for focus state
      return Obx(() {
        final isFocused =
            controller.isSearchFocused.value ||
            controller.searchFocusNode.hasFocus;

        return GestureDetector(
          onTap: () {
            // Request focus when tapping the container
            controller.searchFocusNode.requestFocus();
            controller.isSearchFocused.value = true;
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              borderRadius: AppSpacing.borderRadiusLg,
              border: isFocused
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search,
                  size: 20,
                  color: isFocused
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.searchFocusNode,
                    autofocus: false, // Don't auto focus
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm Hán tự, Pinyin hoặc Nghĩa',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => controller.search(),
                    onTap: () {
                      controller.isSearchFocused.value = true;
                    },
                  ),
                ),
                if (controller.searchQuery.value.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.searchController.clear();
                      controller.searchQuery.value = '';
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      });
    }

    // Inactive search placeholder - open search view and focus
    return GestureDetector(
      onTap: () {
        controller.openSearchView(focus: true);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Text(
              'Tìm Hán tự, Pinyin hoặc Nghĩa',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            controller.chipLabels.length,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => controller.setChipFilter(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: controller.selectedChipIndex.value == index
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : AppColors.surface),
                    borderRadius: BorderRadius.circular(20),
                    border: controller.selectedChipIndex.value == index
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                  ),
                  child: Text(
                    controller.chipLabels[index],
                    style: AppTypography.labelMedium.copyWith(
                      color: controller.selectedChipIndex.value == index
                          ? AppColors.white
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPickSection(bool isDark) {
    final vocab = controller.dailyPick.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show section header
          Text(
            'Từ vựng hôm nay',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Content or empty state
          if (vocab == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: AppSpacing.borderRadiusXl,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đang tải từ vựng...',
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mỗi ngày app sẽ gợi ý từ mới phù hợp với bạn',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => controller.openVocabDetail(vocab),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.surfaceVariantDark, AppColors.surfaceDark]
                        : [const Color(0xFFF8F7FF), const Color(0xFFF1EEFF)],
                  ),
                  borderRadius: AppSpacing.borderRadiusXl,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : const Color(0xFFE0DBFF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      children: [
                        // Hanzi icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Center(
                            child: Text(
                              vocab.hanzi,
                              style: AppTypography.hanziSmall.copyWith(
                                fontSize: 28,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    vocab.pinyin,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      vocab.level,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vocab.meaningVi,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Audio button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    if (vocab.mnemonic != null &&
                        vocab.mnemonic!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Quote
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '"${vocab.mnemonic}"',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: controller.saveDailyPick,
                            child: Text(
                              'Lưu',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ sưu tập',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Xem tất cả',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Content or empty state
        SizedBox(
          height: 200,
          child: Obx(() {
            if (controller.collections.isEmpty) {
              // Empty state
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    borderRadius: AppSpacing.borderRadiusXl,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đang tải bộ sưu tập...',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Các bài học theo chủ đề và cấp độ HSK',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.collections.length,
              itemBuilder: (context, index) {
                final collection = controller.collections[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _CollectionCard(
                    collection: collection,
                    isDark: isDark,
                    onTap: () => controller.openCollection(collection),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRecentSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always show section header
          Text(
            'Gần đây',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Content or empty state
          if (controller.recentItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chưa có từ nào gần đây',
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Các từ bạn tra cứu sẽ xuất hiện ở đây',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...controller.recentItems
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecentItemCard(
                      item: item,
                      isDark: isDark,
                      onTap: () => controller.openRecentItem(item),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'Frequency':
        return 'Theo tần suất';
      case 'Difficulty':
        return 'Theo độ khó';
      case 'Level':
        return 'Theo cấp độ';
      default:
        return 'Sắp xếp';
    }
  }

  void _showFilterSheet(BuildContext context) {
    HMBottomSheet.show(
      title: S.filter,
      child: ExploreFilterSheet(controller: controller),
    );
  }

  void _showSortSheet(BuildContext context) {
    HMBottomSheet.show(
      title: S.sort,
      child: Column(
        children: [
          _SortOption(
            label: S.sortByFrequency,
            isSelected: controller.sortBy.value == 'Frequency',
            onTap: () {
              controller.sortBy.value = 'Frequency';
              controller.sortVocabs();
              Get.back();
            },
          ),
          _SortOption(
            label: S.sortByDifficulty,
            isSelected: controller.sortBy.value == 'Difficulty',
            onTap: () {
              controller.sortBy.value = 'Difficulty';
              controller.sortVocabs();
              Get.back();
            },
          ),
          _SortOption(
            label: S.level,
            isSelected: controller.sortBy.value == 'Level',
            onTap: () {
              controller.sortBy.value = 'Level';
              controller.sortVocabs();
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final bool isDark;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: collection.badgeColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                collection.badge,
                style: AppTypography.labelSmall.copyWith(
                  color: collection.badgeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            // Title
            Text(
              collection.title,
              style: AppTypography.titleSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              collection.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Bottom row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${collection.wordCount} từ',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentItemCard extends StatelessWidget {
  final RecentItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentItemCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${item.hanzi} - ${item.meaning}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabCard extends StatelessWidget {
  final VocabModel vocab;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _VocabCard({
    required this.vocab,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = AppColors.getHskColor(vocab.levelInt);

    return HMCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      vocab.hanzi,
                      style: AppTypography.hanziMedium.copyWith(
                        fontSize: 28,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vocab.pinyin,
                        style: AppTypography.pinyin.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty)
                      Icon(
                        Icons.volume_up_outlined,
                        size: 20,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: vocab.isFavorite
                        ? AppColors.success
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    vocab.isFavorite ? Icons.check_rounded : Icons.add_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vocab.meaningVi,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: vocab.level, color: levelColor),
              if (vocab.wordType != null && vocab.wordType!.isNotEmpty)
                _TagChip(
                  label: _translateWordType(vocab.wordType!),
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  isOutline: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateWordType(String type) {
    switch (type.toLowerCase()) {
      case 'verb':
        return 'Động từ';
      case 'noun':
        return 'Danh từ';
      case 'adjective':
        return 'Tính từ';
      case 'adverb':
        return 'Trạng từ';
      case 'phrase':
        return 'Cụm từ';
      case 'pronoun':
        return 'Đại từ';
      default:
        return type.capitalize ?? type;
    }
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutline;

  const _TagChip({
    required this.label,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: isOutline ? Border.all(color: color.withAlpha(100)) : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isSelected ? AppColors.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
    );
  }
}

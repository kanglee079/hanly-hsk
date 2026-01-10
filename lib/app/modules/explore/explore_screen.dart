import 'package:flutter/cupertino.dart';
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

/// Explore tab screen - redesigned with proper logic
class ExploreScreen extends GetView<ExploreController> {
  const ExploreScreen({super.key});

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
          // Main view switcher based on browse mode
          switch (controller.browseMode.value) {
            case BrowseMode.home:
              return _buildHomeView(context, isDark);
            case BrowseMode.search:
              return _buildSearchResultsView(context, isDark);
            case BrowseMode.level:
              return _buildBrowseView(context, isDark);
            case BrowseMode.topic:
              if (controller.isTopicSelection) {
                return _buildTopicSelectionView(context, isDark);
              }
              return _buildBrowseView(context, isDark);
          }
        }),
      ),
    );
  }

  /// Main home view with all sections
  Widget _buildHomeView(BuildContext context, bool isDark) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 16),

            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Showcase(
                    key: _searchKey,
                    title: 'Tìm kiếm từ vựng',
                    description: 'Gõ từ tiếng Trung, pinyin hoặc tiếng Việt để tra cứu.',
                    overlayOpacity: 0.7,
                    targetShapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildSearchBar(isDark, isActive: false),
                  ),
                  const SizedBox(height: 16),

                  Showcase(
                    key: _hskLevelsKey,
                    title: 'Lọc theo cấp độ',
                    description: 'Chọn cấp HSK hoặc chủ đề để duyệt từ vựng.',
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

            Showcase(
              key: _dailyPickKey,
              title: 'Từ vựng hôm nay',
              description: 'Mỗi ngày app sẽ gợi ý một từ mới ngẫu nhiên cho bạn!',
              overlayOpacity: 0.7,
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Obx(() => _buildDailyPickSection(isDark)),
            ),

            const SizedBox(height: 24),

            Showcase(
              key: _collectionsKey,
              title: 'Bộ sưu tập',
              description: 'Khám phá các bài học theo chủ đề và cấp độ.',
              overlayOpacity: 0.7,
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildCollectionsSection(isDark),
            ),

            const SizedBox(height: 24),

            Showcase(
              key: _recentKey,
              title: 'Gần đây',
              description: 'Xem lại các từ bạn đã tra cứu gần đây.',
              overlayOpacity: 0.7,
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Obx(() => _buildRecentSection(isDark)),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// Search results view
  Widget _buildSearchResultsView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back + search + filter
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBackButton(isDark),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSearchBar(isDark, isActive: true)),
                  const SizedBox(width: 12),
                  _buildFilterButton(isDark, context),
                ],
              ),
              const SizedBox(height: 16),
              _buildResultsHeader(isDark, context),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Results
        Expanded(
          child: Obx(() {
            if (controller.isSearching.value) {
              return _buildLoadingSkeleton();
            }

            if (controller.vocabs.isEmpty && controller.searchQuery.value.isNotEmpty) {
              return HMEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Không tìm thấy kết quả',
                description: 'Thử tìm kiếm với từ khóa khác',
                actionLabel: 'Về trang chính',
                onAction: controller.goHome,
              );
            }

            return _buildVocabList(controller.vocabs, isDark);
          }),
        ),
      ],
    );
  }

  /// Browse view (by level or topic)
  Widget _buildBrowseView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with back + title + filter
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBackButton(isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Text(
                      controller.browseTitle.value,
                      style: AppTypography.titleLarge.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ),
                  _buildFilterButton(isDark, context),
                ],
              ),
              const SizedBox(height: 16),
              _buildResultsHeader(isDark, context, isBrowse: true),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Results
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingSkeleton();
            }

            if (controller.browseVocabs.isEmpty) {
              return HMEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Không có từ vựng',
                description: 'Chưa có từ vựng cho mục này',
                actionLabel: 'Về trang chính',
                onAction: controller.goHome,
              );
            }

            return _buildVocabList(controller.browseVocabs, isDark, canLoadMore: true);
          }),
        ),
      ],
    );
  }

  /// Topic selection view
  Widget _buildTopicSelectionView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildBackButton(isDark),
                  const SizedBox(width: 12),
                  Text(
                    'Chọn chủ đề',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Obx(() {
            if (controller.topics.isEmpty) {
              return const Center(child: HMLoadingIndicator());
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: controller.topics.length,
              itemBuilder: (context, index) {
                final topic = controller.topics[index];
                return _TopicCard(
                  topic: topic,
                  isDark: isDark,
                  onTap: () => controller.selectTopic(topic),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // ===== HELPER WIDGETS =====

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: controller.goHome,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterButton(bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.tune_rounded,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildResultsHeader(bool isDark, BuildContext context, {bool isBrowse = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(() {
          final count = isBrowse 
              ? controller.browseVocabs.length 
              : controller.vocabs.length;
          return Text(
            'KẾT QUẢ ($count)',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showSortSheet(context),
          child: Row(
            children: [
              Obx(() => Text(
                _getSortLabel(controller.sortBy.value),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              )),
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
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: HMSkeletonCard(height: 100),
      ),
    );
  }

  Widget _buildVocabList(List<VocabModel> vocabs, bool isDark, {bool canLoadMore = false}) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (canLoadMore && 
            notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          controller.loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
        itemCount: vocabs.length + (controller.isLoadingMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= vocabs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: HMLoadingIndicator.small()),
            );
          }

          final vocab = vocabs[index];
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
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
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
      return Obx(() {
        final isFocused = controller.isSearchFocused.value || controller.searchFocusNode.hasFocus;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isFocused ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                CupertinoIcons.search,
                size: 20,
                color: isFocused
                    ? AppColors.primary
                    : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  focusNode: controller.searchFocusNode,
                  autofocus: true,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm Hán tự, Pinyin hoặc Nghĩa',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  textInputAction: TextInputAction.search,
                  onTap: () => controller.isSearchFocused.value = true,
                ),
              ),
              if (controller.searchQuery.value.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.searchController.clear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      });
    }

    return GestureDetector(
      onTap: () => controller.openSearchView(focus: true),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 20,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Text(
              'Tìm Hán tự, Pinyin hoặc Nghĩa',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          controller.chipLabels.length,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => controller.setChipFilter(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: controller.selectedChipIndex.value == index
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : AppColors.surface),
                  borderRadius: BorderRadius.circular(20),
                  border: controller.selectedChipIndex.value == index
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                ),
                child: Text(
                  controller.chipLabels[index],
                  style: AppTypography.labelMedium.copyWith(
                    color: controller.selectedChipIndex.value == index
                        ? AppColors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildDailyPickSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Từ vựng hôm nay',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ngẫu nhiên',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (controller.isLoadingDailyPick.value)
            _buildDailyPickSkeleton(isDark)
          else if (controller.dailyPick.value == null)
            _buildDailyPickEmpty(isDark)
          else
            _buildDailyPickCard(controller.dailyPick.value!, isDark),
        ],
      ),
    );
  }

  Widget _buildDailyPickSkeleton(bool isDark) {
    return HMSkeleton(
      width: double.infinity,
      height: 140,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildDailyPickEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
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
                  'Chưa có từ vựng',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kéo xuống để tải lại',
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

  Widget _buildDailyPickCard(VocabModel vocab, bool isDark) {
    return GestureDetector(
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
            color: isDark ? AppColors.borderDark : const Color(0xFFE0DBFF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vocab.pinyin,
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: controller.saveDailyPick,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceVariantDark : AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (vocab.mnemonic != null && vocab.mnemonic!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '"${vocab.mnemonic}"',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ sưu tập',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: controller.openAllCollections,
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: Obx(() {
            if (controller.isLoadingCollections.value) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: HMSkeleton(
                    width: 180,
                    height: 200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }
            
            if (controller.collections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
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
                        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có bộ sưu tập',
                        style: AppTypography.titleSmall.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final displayItems = controller.collections.take(6).toList();
            
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final collection = displayItems[index];
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
          Text(
            'Tra cứu gần đây',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (controller.recentItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
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
                          'Chưa có từ nào',
                          style: AppTypography.titleSmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Các từ bạn tra cứu sẽ xuất hiện ở đây',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
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
                .take(5)
                .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentItemCard(
                    item: item,
                    isDark: isDark,
                    onTap: () => controller.openRecentItem(item),
                  ),
                )),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'frequency_rank':
        return 'Theo tần suất';
      case 'difficulty_score':
        return 'Theo độ khó';
      case 'order_in_level':
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
            isSelected: controller.sortBy.value == 'frequency_rank',
            onTap: () {
              controller.sortVocabs('frequency_rank');
              Get.back();
            },
          ),
          _SortOption(
            label: S.sortByDifficulty,
            isSelected: controller.sortBy.value == 'difficulty_score',
            onTap: () {
              controller.sortVocabs('difficulty_score');
              Get.back();
            },
          ),
          _SortOption(
            label: S.level,
            isSelected: controller.sortBy.value == 'order_in_level',
            onTap: () {
              controller.sortVocabs('order_in_level');
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}

// ===== PRIVATE WIDGETS =====

class _TopicCard extends StatelessWidget {
  final String topic;
  final bool isDark;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.label_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                topic,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
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
            Text(
              collection.title,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              collection.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${collection.wordCount} từ',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
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
            Text(
              item.hanzi,
              style: AppTypography.hanziSmall.copyWith(
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.pinyin,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    item.meaning,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
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
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
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
                    color: vocab.isFavorite ? AppColors.success : AppColors.primary,
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
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
      case 'verb': return 'Động từ';
      case 'noun': return 'Danh từ';
      case 'adjective': return 'Tính từ';
      case 'adverb': return 'Trạng từ';
      case 'phrase': return 'Cụm từ';
      case 'pronoun': return 'Đại từ';
      case 'particle': return 'Trợ từ';
      default: return type.capitalize ?? type;
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

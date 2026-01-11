import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../../core/constants/toast_messages.dart';
import '../../data/models/hsk_exam_model.dart';
import '../../data/repositories/hsk_exam_repo.dart';
import '../../routes/app_routes.dart';

/// HSK Exam all tests screen - shows complete list with filters
class HskExamAllTestsScreen extends StatefulWidget {
  const HskExamAllTestsScreen({super.key});

  @override
  State<HskExamAllTestsScreen> createState() => _HskExamAllTestsScreenState();
}

class _HskExamAllTestsScreenState extends State<HskExamAllTestsScreen> {
  final HskExamRepo _examRepo = Get.find<HskExamRepo>();

  List<MockTestModel> tests = [];
  bool isLoading = true;
  String selectedLevel = 'all';
  String? skillFilter;
  String screenTitle = 'Tất cả đề thi';

  final levels = ['all', 'HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];

  @override
  void initState() {
    super.initState();
    // Get skill filter from arguments
    skillFilter = Get.arguments?['skill'] as String?;
    screenTitle = Get.arguments?['title'] as String? ?? 'Tất cả đề thi';
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => isLoading = true);
    try {
      tests = await _examRepo.getTests(
        level: selectedLevel == 'all' ? null : selectedLevel,
      );
      
      // Filter by skill if specified
      if (skillFilter != null) {
        tests = tests.where((test) {
          if (skillFilter == 'listening') {
            return test.sections.any((s) => s.isListening);
          } else if (skillFilter == 'reading') {
            return test.sections.any((s) => !s.isListening);
          }
          return true;
        }).toList();
      }
    } catch (e) {
      HMToast.error(ToastMessages.examTestsLoadError);
    }
    setState(() => isLoading = false);
  }

  void _selectLevel(String level) {
    if (selectedLevel != level) {
      setState(() => selectedLevel = level);
      _loadTests();
    }
  }

  void _startTest(String testId) {
    Get.toNamed(Routes.hskExamTest, arguments: {'testId': testId});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark),

            // Level filter
            _buildLevelFilter(isDark),

            // Tests list
            Expanded(
              child: isLoading
                  ? _buildLoadingState(isDark)
                  : tests.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildTestsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screenTitle,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (skillFilter != null)
                  Text(
                    skillFilter == 'listening' 
                        ? 'Luyện tập phần nghe' 
                        : 'Luyện tập phần đọc',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Test count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${tests.length} đề',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 16),
      child: Row(
        children: levels.map((level) {
          final isSelected = selectedLevel == level;
          final label = level == 'all' ? 'Tất cả' : level;
          return GestureDetector(
            onTap: () => _selectLevel(level),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: List.generate(6, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HMSkeleton(
              width: double.infinity,
              height: 90,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              skillFilter == 'listening' 
                  ? Icons.headphones_rounded 
                  : skillFilter == 'reading' 
                      ? Icons.menu_book_rounded 
                      : Icons.quiz_rounded,
              size: 64,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đề thi',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              skillFilter == 'listening'
                  ? 'Chưa có đề luyện nghe cho cấp độ này'
                  : skillFilter == 'reading'
                      ? 'Chưa có đề luyện đọc cho cấp độ này'
                      : 'Chưa có đề thi cho cấp độ này',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadTests,
      color: AppColors.primary,
      child: ListView.builder(
        padding: AppSpacing.screenPadding.copyWith(top: 0),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTestCard(test, isDark),
          );
        },
      ),
    );
  }

  Widget _buildTestCard(MockTestModel test, bool isDark) {
    // Get sections info
    final hasListening = test.sections.any((s) => s.isListening);
    final hasReading = test.sections.any((s) => !s.isListening);
    
    return HMCard(
      onTap: () => _startTest(test.id),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getLevelColor(test.level),
                  _getLevelColor(test.level).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                test.level.replaceAll('HSK', ''),
                style: AppTypography.titleLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildInfoChip(
                      '${test.totalQuestions} câu',
                      Icons.quiz_outlined,
                      isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      '${test.totalDuration} phút',
                      Icons.timer_outlined,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (hasListening)
                      _buildSkillBadge('Nghe', const Color(0xFF3B82F6), isDark),
                    if (hasListening && hasReading)
                      const SizedBox(width: 6),
                    if (hasReading)
                      _buildSkillBadge('Đọc', const Color(0xFF22C55E), isDark),
                    if (test.bestScore != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🏆 ${test.bestScore}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Arrow
          Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'HSK1':
        return const Color(0xFF22C55E);
      case 'HSK2':
        return const Color(0xFF84CC16);
      case 'HSK3':
        return const Color(0xFFEAB308);
      case 'HSK4':
        return const Color(0xFFF97316);
      case 'HSK5':
        return const Color(0xFFEC4899);
      case 'HSK6':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }
}

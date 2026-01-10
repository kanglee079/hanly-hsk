import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/strings_vi.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/hm_tutorial_overlay.dart';
import '../today/today_screen.dart';
import '../learn/learn_screen.dart';
import '../hsk_exam/hsk_exam_screen.dart';
import '../explore/explore_screen.dart';
import '../me/me_screen.dart';
import 'shell_controller.dart';

/// Main shell screen with bottom navigation
/// Uses IndexedStack + Crossfade for smooth, instant tab switching
class ShellScreen extends GetView<ShellController> {
  const ShellScreen({super.key});

  // Pre-built screens (kept in memory for instant switching)
  // Wrapped in RepaintBoundary for optimal performance
  // Order: Today, Learn, Exam, Explore, Me
  static const _screens = [
    RepaintBoundary(child: TodayScreen()),
    RepaintBoundary(child: LearnScreen()),
    RepaintBoundary(child: HskExamScreen()),
    RepaintBoundary(child: ExploreScreen()),
    RepaintBoundary(child: MeScreen()),
  ];

  // Global key for bottom nav (used in tutorial)
  static final GlobalKey bottomNavKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: HMTutorialOverlay(
        child: Scaffold(
          extendBody: true,
          body: Obx(
            () => _SmoothTabSwitcher(
              currentIndex: controller.currentIndex.value,
              children: _screens,
            ),
          ),
          bottomNavigationBar: Obx(
            () => _PillBottomNav(
              key: bottomNavKey,
              currentIndex: controller.currentIndex.value,
              onTap: controller.changePage,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth tab switcher with crossfade animation
/// - Keeps all children in memory (IndexedStack behavior)
/// - Crossfade between tabs for smooth visual transition
/// - No janky animation through intermediate pages
class _SmoothTabSwitcher extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const _SmoothTabSwitcher({
    required this.currentIndex,
    required this.children,
  });

  @override
  State<_SmoothTabSwitcher> createState() => _SmoothTabSwitcherState();
}

class _SmoothTabSwitcherState extends State<_SmoothTabSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  int _previousIndex = 0;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _previousIndex = widget.currentIndex;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _previousIndex = _currentIndex;
        });
      }
    });
  }

  @override
  void didUpdateWidget(_SmoothTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.currentIndex;
      _isAnimating = true;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Keep all screens in memory with IndexedStack-like behavior
        // but only show current and previous during animation
        for (int i = 0; i < widget.children.length; i++) _buildTabContent(i),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    // Determine visibility
    final bool isCurrentTab = index == _currentIndex;
    final bool isPreviousTab = index == _previousIndex && _isAnimating;
    final bool isVisible = isCurrentTab || isPreviousTab;

    if (!isVisible) {
      // Keep in tree but offstage to preserve state
      return Offstage(offstage: true, child: widget.children[index]);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double opacity;
        if (_isAnimating) {
          if (isCurrentTab) {
            opacity = _fadeIn.value;
          } else {
            opacity = _fadeOut.value;
          }
        } else {
          opacity = isCurrentTab ? 1.0 : 0.0;
        }

        return Opacity(
          opacity: opacity,
          child: IgnorePointer(
            ignoring: !isCurrentTab || _isAnimating,
            child: child,
          ),
        );
      },
      child: widget.children[index],
    );
  }
}

/// Pill-style bottom navigation with animated labels
class _PillBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDark;

  const _PillBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  static const _items = [
    _NavItemData(
      svgPath: AppIcons.navToday,
      label: S.tabToday,
    ),
    _NavItemData(
      svgPath: AppIcons.navLearn,
      label: S.tabLearn,
    ),
    _NavItemData(
      svgPath: AppIcons.school,
      label: S.tabExam,
    ),
    _NavItemData(
      svgPath: AppIcons.navExplore,
      label: S.tabExplore,
    ),
    _NavItemData(
      svgPath: AppIcons.navMe,
      label: S.tabMe,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 40),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 20 : 15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withAlpha(250)
                  : Colors.white.withAlpha(252),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(35)
                    : const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (index) {
                return _NavItem(
                  data: _items[index],
                  isSelected: currentIndex == index,
                  onTap: () => onTap(index),
                  isDark: isDark,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String svgPath;
  final String label;

  const _NavItemData({
    required this.svgPath,
    required this.label,
  });
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF636366);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: activeColor.withAlpha(40), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SVG Icon with scale animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: isSelected ? 1.0 : 0.92),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: SvgPicture.asset(
                    data.svgPath,
                    width: 26,
                    height: 26,
                    colorFilter: ColorFilter.mode(
                      isSelected ? activeColor : inactiveColor,
                      BlendMode.srcIn,
                    ),
                  ),
                );
              },
            ),
            // Animated label - only shows when selected
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isSelected ? null : 0,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: activeColor,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

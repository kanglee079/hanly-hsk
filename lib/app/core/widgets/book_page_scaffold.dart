import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A single-page Chinese book style scaffold
/// Used for all learning screens to maintain consistent "古典书籍" aesthetic
class BookPageScaffold extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsets padding;
  final bool showTopOrnament;
  final bool showBottomOrnament;
  final bool enableScroll;

  const BookPageScaffold({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(20),
    this.showTopOrnament = true,
    this.showBottomOrnament = true,
    this.enableScroll = false,
  });

  // Book style colors
  Color get _bookBg => isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFDF8F0);
  Color get _pageBg => isDark ? const Color(0xFF232838) : const Color(0xFFFFFBF5);
  Color get _borderColor => isDark ? const Color(0xFF3A4155) : const Color(0xFFD4C4A8);
  Color get _accentGold => const Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bookBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: _pageBg,
          child: Stack(
            children: [
              // Corner decorations
              _buildCornerDecoration(Alignment.topLeft),
              _buildCornerDecoration(Alignment.topRight, flipX: true),
              _buildCornerDecoration(Alignment.bottomLeft, flipY: true),
              _buildCornerDecoration(Alignment.bottomRight, flipX: true, flipY: true),

              // Left edge decoration (binding effect)
              Positioned(
                left: 0,
                top: 20,
                bottom: 20,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _borderColor.withAlpha(0),
                        _borderColor.withAlpha(120),
                        _borderColor,
                        _borderColor.withAlpha(120),
                        _borderColor.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: padding,
                child: Column(
                  children: [
                    if (showTopOrnament) ...[
                      _buildOrnament(),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: enableScroll
                          ? SingleChildScrollView(child: child)
                          : child,
                    ),
                    if (showBottomOrnament) ...[
                      const SizedBox(height: 16),
                      _buildOrnament(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerDecoration(Alignment alignment, {bool flipX = false, bool flipY = false}) {
    return Positioned(
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 0 : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 0 : null,
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 0 : null,
      bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 0 : null,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0),
        child: CustomPaint(
          size: const Size(40, 40),
          painter: _CornerPainter(color: _accentGold.withAlpha(60)),
        ),
      ),
    );
  }

  Widget _buildOrnament() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentGold.withAlpha(0), _accentGold.withAlpha(100)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _accentGold.withAlpha(80),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.auto_awesome, size: 12, color: _accentGold.withAlpha(120)),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _accentGold.withAlpha(80),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accentGold.withAlpha(100), _accentGold.withAlpha(0)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter for corner decorations
class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.4)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.4, 0)
      ..moveTo(size.width * 0.15, size.height * 0.15)
      ..quadraticBezierTo(0, 0, size.width * 0.15, size.height * 0.15);

    // Small decorative curves
    final innerPath = Path()
      ..moveTo(8, 16)
      ..quadraticBezierTo(8, 8, 16, 8);

    canvas.drawPath(path, paint);
    canvas.drawPath(innerPath, paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper colors for book page (accessible from outside)
class BookPageColors {
  final bool isDark;

  BookPageColors({required this.isDark});

  Color get bookBg => isDark ? const Color(0xFF1A1F2E) : const Color(0xFFFDF8F0);
  Color get pageBg => isDark ? const Color(0xFF232838) : const Color(0xFFFFFBF5);
  Color get borderColor => isDark ? const Color(0xFF3A4155) : const Color(0xFFD4C4A8);
  Color get accentGold => const Color(0xFFB8860B);
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textTertiary => isDark ? AppColors.textTertiaryDark : AppColors.textTertiary;
}


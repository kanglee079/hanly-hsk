import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/book_page_scaffold.dart';
import '../../../core/widgets/hm_button.dart';
import '../../../data/models/vocab_model.dart';

/// Widget to show learning content with realistic page curl effect (interactive drag)
class LearningContentWidget extends StatefulWidget {
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
  State<LearningContentWidget> createState() => _LearningContentWidgetState();
}

class _LearningContentWidgetState extends State<LearningContentWidget>
    with TickerProviderStateMixin {
  // Page curl controller
  late final AnimationController _controller;

  // Entry animation controller (fade + scale)
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  // --- Drag state
  bool _isDragging = false;
  bool _isFlipped = false;

  double _dragProgress = 0.0;         // progress during drag
  double _dragStartProgress = 0.0;    // progress at drag start
  Offset? _dragStartPos;              // local position at drag start
  Offset? _touchPos;                  // current finger local position

  // Cached pages to avoid rebuilding heavy UI during animation frames
  late Widget _frontCached;
  late Widget _backCached;

  static const _curlCurve = Curves.easeOutCubic;

  BookPageColors get _colors => BookPageColors(isDark: widget.isDark);

  double get _progress => _isDragging ? _dragProgress : _controller.value;

  @override
  void initState() {
    super.initState();

    // Page curl controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Entry animation controller
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _rebuildCachedPages();

    // Start entry animation
    Future.microtask(() {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void didUpdateWidget(LearningContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final vocabChanged = widget.vocab.id != oldWidget.vocab.id;
    final themeChanged = widget.isDark != oldWidget.isDark;

    if (vocabChanged || themeChanged) {
      _resetToFront();
      _rebuildCachedPages();

      // Re-run entry animation when vocab changes
      if (vocabChanged) {
        _entryController.reset();
        _entryController.forward();
      }
    }
  }

  void _rebuildCachedPages() {
    // Cache pages inside RepaintBoundary so animation frames don’t rebuild heavy widgets.
    _frontCached = RepaintBoundary(child: _buildFrontPage());
    _backCached = RepaintBoundary(child: _buildBackPage());
  }

  void _resetToFront() {
    _isDragging = false;
    _isFlipped = false;
    _dragProgress = 0.0;
    _dragStartProgress = 0.0;
    _dragStartPos = null;
    _touchPos = null;
    _controller.value = 0.0;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // --- Gestures (interactive curl)
  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _controller.stop();

    _dragStartPos = details.localPosition;
    _touchPos = details.localPosition;

    // Start from current visual progress (can be mid-animation)
    final current = _controller.value;
    _dragStartProgress = current;
    _dragProgress = current;
    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging || _dragStartPos == null) return;

    _touchPos = details.localPosition;

    final dxFromStart = details.localPosition.dx - _dragStartPos!.dx;

    // One formula works for both:
    // drag left (dx negative) => progress increases (flip forward)
    // drag right (dx positive) => progress decreases (flip back)
    final next = (_dragStartProgress - (dxFromStart / width)).clamp(0.0, 1.0);

    setState(() => _dragProgress = next);
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;

    final vx = details.velocity.pixelsPerSecond.dx;
    final current = _dragProgress;

    final isFling = vx.abs() > 650;
    final target = isFling
        ? (vx < 0 ? 1.0 : 0.0) // fling left => forward, fling right => back
        : (current > 0.5 ? 1.0 : 0.0);

    // Haptic + animate
    if (target > current) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _controller
      ..value = current
      ..animateTo(
        target,
        curve: _curlCurve,
        duration: Duration(milliseconds: (360 + (220 * (target - current).abs())).toInt()),
      ).then((_) {
        _isFlipped = _controller.value >= 0.999;
        _touchPos = null; // optional: clear touch anchor after settle
        setState(() {});
      });

    setState(() {});
  }

  // Tap anywhere to flip
  void _onTapUp(TapUpDetails details, double width) {
    if (_isFlipped) {
      _flipBack();
    } else {
      _flipForward();
    }
  }

  void _flipForward() {
    HapticFeedback.mediumImpact();
    _controller
      ..stop()
      ..animateTo(1.0, curve: _curlCurve, duration: const Duration(milliseconds: 800))
          .then((_) => setState(() => _isFlipped = true));
  }

  void _flipBack() {
    HapticFeedback.lightImpact();
    _controller
      ..stop()
      ..animateTo(0.0, curve: _curlCurve, duration: const Duration(milliseconds: 800))
          .then((_) => setState(() => _isFlipped = false));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (d) => _onTapUp(d, width),
                      onHorizontalDragStart: _onDragStart,
                      onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
                      onHorizontalDragEnd: _onDragEnd,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return _PageCurlWidget(
                            progress: _progress,
                            touchPos: _touchPos,
                            isDark: widget.isDark,
                            frontPage: _frontCached,
                            backPage: _backCached,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Continue button
            Container(
              height: 80,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: HMButton(
                  text: _isFlipped ? 'Tiếp tục' : 'Lật trang',
                  variant: _isFlipped ? HMButtonVariant.primary : HMButtonVariant.secondary,
                  onPressed: () {
                    if (_isFlipped) {
                      widget.onContinue();
                    } else {
                      _flipForward();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI PAGES (giữ nguyên layout của bạn) ----------------

  Widget _buildFrontPage() {
    return BookPageScaffold(
      isDark: widget.isDark,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          _buildOrnament(),
          const SizedBox(height: 24),
          Text(
            widget.vocab.hanzi,
            style: AppTypography.hanziLarge.copyWith(
              color: _colors.textPrimary,
              fontSize: 88,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _colors.accentGold.withAlpha(20),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _colors.accentGold.withAlpha(60)),
            ),
            child: Text(
              widget.vocab.pinyin,
              style: AppTypography.pinyin.copyWith(
                fontSize: 24,
                color: _colors.accentGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (widget.onPlayAudio != null || widget.onPlaySlow != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.onPlayAudio != null)
                  _buildAudioButton(Icons.volume_up_rounded, 'Nghe', widget.onPlayAudio!, isPrimary: true),
                if (widget.onPlayAudio != null && widget.onPlaySlow != null)
                  const SizedBox(width: 16),
                if (widget.onPlaySlow != null)
                  _buildAudioButton(Icons.slow_motion_video_rounded, 'Chậm', widget.onPlaySlow!, isPrimary: false),
              ],
            ),
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _colors.borderColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: _colors.textTertiary),
                const SizedBox(width: 8),
                Text('Nhấn hoặc kéo để lật trang', style: AppTypography.bodySmall.copyWith(color: _colors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildOrnament(),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildBackPage() {
    final example = widget.vocab.examples.isNotEmpty ? widget.vocab.examples.first : null;
    final dna = widget.vocab.hanziDna;

    return BookPageScaffold(
      isDark: widget.isDark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enableScroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildOrnament()),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.vocab.hanzi, style: AppTypography.hanziLarge.copyWith(color: _colors.textPrimary, fontSize: 44)),
                    const SizedBox(height: 4),
                    Text(widget.vocab.pinyin, style: AppTypography.pinyin.copyWith(fontSize: 18, color: _colors.accentGold)),
                  ],
                ),
              ),
              if (widget.onPlayAudio != null) _buildSmallAudioButton(Icons.volume_up_rounded, widget.onPlayAudio!, isPrimary: true),
              if (widget.onPlaySlow != null) ...[
                const SizedBox(width: 10),
                _buildSmallAudioButton(Icons.slow_motion_video_rounded, widget.onPlaySlow!, isPrimary: false),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            icon: Icons.translate_rounded,
            title: 'Nghĩa',
            child: Text(
              widget.vocab.meaningViCapitalized,
              style: AppTypography.headlineSmall.copyWith(color: _colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          if (widget.vocab.wordType != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
              child: Text(widget.vocab.wordType!, style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
          if (dna != null) ...[
            const SizedBox(height: 18),
            _buildSection(
              icon: Icons.auto_awesome_rounded,
              title: 'Cấu tạo',
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (dna.radical != null) _buildDnaChip('Bộ', dna.radical!),
                  _buildDnaChip('Nét', '${dna.strokeCount}'),
                  ...dna.components.take(3).map((c) => _buildComponentChip(c.toString())),
                ],
              ),
            ),
          ],
          if (example != null) ...[
            const SizedBox(height: 18),
            _buildSection(
              icon: Icons.format_quote_rounded,
              title: 'Ví dụ',
              trailing: widget.onPlayExampleSentence != null
                  ? GestureDetector(
                      onTap: () => widget.onPlayExampleSentence!(example.hanzi, example.audioUrl, false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _colors.accentGold.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _colors.accentGold.withAlpha(50)),
                        ),
                        child: Icon(Icons.volume_up_rounded, size: 18, color: _colors.accentGold),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example.hanzi,
                    style: TextStyle(
                      fontFamily: 'NotoSansSC',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _colors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (example.pinyin.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      example.pinyin,
                      style: AppTypography.pinyinSmall.copyWith(color: _colors.accentGold.withAlpha(180), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    example.meaningViCapitalized,
                    style: AppTypography.bodyMedium.copyWith(color: _colors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(child: _buildOrnament()),
        ],
      ),
    );
  }

  Widget _buildOrnament() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1.5, color: _colors.accentGold.withAlpha(80)),
        const SizedBox(width: 8),
        Icon(Icons.auto_awesome, size: 12, color: _colors.accentGold.withAlpha(150)),
        const SizedBox(width: 8),
        Container(width: 24, height: 1.5, color: _colors.accentGold.withAlpha(80)),
      ],
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: _colors.accentGold),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.labelLarge.copyWith(color: _colors.accentGold, fontWeight: FontWeight.w600)),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildAudioButton(IconData icon, String label, VoidCallback onTap, {required bool isPrimary}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? _colors.accentGold.withAlpha(25) : _colors.borderColor.withAlpha(25),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isPrimary ? _colors.accentGold.withAlpha(70) : _colors.borderColor.withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isPrimary ? _colors.accentGold : _colors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.labelLarge.copyWith(color: isPrimary ? _colors.accentGold : _colors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAudioButton(IconData icon, VoidCallback onTap, {required bool isPrimary}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? _colors.accentGold.withAlpha(25) : _colors.borderColor.withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(color: isPrimary ? _colors.accentGold.withAlpha(70) : _colors.borderColor.withAlpha(70)),
        ),
        child: Icon(icon, size: 22, color: isPrimary ? _colors.accentGold : _colors.textSecondary),
      ),
    );
  }

  Widget _buildDnaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _colors.borderColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colors.borderColor.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTypography.labelSmall.copyWith(color: _colors.textTertiary, fontSize: 11)),
          Text(value, style: TextStyle(fontFamily: 'NotoSansSC', fontSize: 16, fontWeight: FontWeight.w500, color: _colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildComponentChip(String component) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _colors.borderColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _colors.borderColor.withAlpha(60)),
      ),
      child: Text(component, style: TextStyle(fontFamily: 'NotoSansSC', fontSize: 18, fontWeight: FontWeight.w500, color: _colors.textPrimary)),
    );
  }
}

// ---------------- Curl Rendering ----------------

class _PageCurlWidget extends StatelessWidget {
  final double progress;     // 0..1
  final Offset? touchPos;    // local finger position inside card
  final bool isDark;
  final Widget frontPage;
  final Widget backPage;

  const _PageCurlWidget({
    required this.progress,
    required this.touchPos,
    required this.isDark,
    required this.frontPage,
    required this.backPage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Back page under
              Positioned.fill(child: backPage),

              // Back page shadow near curl
              if (progress > 0 && progress < 1)
                Positioned.fill(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _BackPageShadowPainter(
                      progress: progress,
                      isDark: isDark,
                      touchY: touchPos?.dy,
                    ),
                  ),
                ),

              // Front page clipped
              if (progress < 1)
                Positioned.fill(
                  child: ClipPath(
                    clipper: _PageCurlClipper(progress: progress, touchY: touchPos?.dy),
                    child: frontPage,
                  ),
                ),

              // Curl fold (back of the turning page)
              if (progress > 0.02 && progress < 0.98)
                Positioned.fill(
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _CurlFoldPainter(
                      progress: progress,
                      isDark: isDark,
                      width: w,
                      height: h,
                      touchY: touchPos?.dy,
                    ),
                  ),
                ),

              // Edge highlight
              if (progress > 0.02 && progress < 0.98)
                Positioned.fill(
                  child: CustomPaint(
                    willChange: true,
                    painter: _EdgeHighlightPainter(
                      progress: progress,
                      isDark: isDark,
                      touchY: touchPos?.dy,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Clipper: curve follows finger Y (touchY) so it feels “bám ngón”
class _PageCurlClipper extends CustomClipper<Path> {
  final double progress;
  final double? touchY;

  _PageCurlClipper({required this.progress, required this.touchY});

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final y = (touchY ?? h * 0.52).clamp(0.0, h);

    // Curl position (vertical cut line moves left as progress increases)
    final curlX = w * (1 - progress);

    // Tuning knobs (feel free to adjust):
    final s = math.sin(progress * math.pi); // 0..1..0
    final depth = h * (0.035 + 0.085 * s);  // curl depth (how much it "bends")

    // Control points shift depending on finger y
    final topCtrlY = ui.lerpDouble(h * 0.12, y, 0.55)!;
    final botCtrlY = ui.lerpDouble(h * 0.88, y, 0.55)!;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(curlX - depth, 0)
      ..quadraticBezierTo(
        curlX + depth * 0.85, topCtrlY,
        curlX, y,
      )
      ..quadraticBezierTo(
        curlX + depth * 0.85, botCtrlY,
        curlX - depth, h,
      )
      ..lineTo(0, h)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant _PageCurlClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.touchY != touchY;
}

/// Back page shadow (only draw near curl zone, not full screen)
class _BackPageShadowPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final double? touchY;

  _BackPageShadowPainter({
    required this.progress,
    required this.isDark,
    required this.touchY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final curlX = w * (1 - progress);
    final s = math.sin(progress * math.pi);
    final intensity = (0.35 + 0.65 * s).clamp(0.0, 1.0);

    // shadow band width
    final bandW = ui.lerpDouble(60, 120, s)!.toDouble();
    final left = (curlX - bandW).clamp(0.0, w);
    final rect = Rect.fromLTWH(left, 0, (bandW * 1.45).clamp(0.0, w), h);

    final shadowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(left, 0),
        Offset(left + rect.width, 0),
        [
          Colors.transparent,
          Colors.black.withAlpha((85 * intensity).toInt()),
          Colors.black.withAlpha((40 * intensity).toInt()),
          Colors.transparent,
        ],
        [0.0, 0.38, 0.70, 1.0],
      );

    canvas.drawRect(rect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _BackPageShadowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.touchY != touchY;
}

/// Fold painter: draws the “back side” of the curling page.
/// Main trick: fold path also uses touchY so it follows the finger.
class _CurlFoldPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final double width;
  final double height;
  final double? touchY;

  _CurlFoldPainter({
    required this.progress,
    required this.isDark,
    required this.width,
    required this.height,
    required this.touchY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final y = (touchY ?? h * 0.52).clamp(0.0, h);

    final curlX = w * (1 - progress);
    final s = math.sin(progress * math.pi);

    // Tuning knobs:
    final depth = h * (0.030 + 0.090 * s);          // how much the edge bends
    final foldW = w * (0.10 + 0.14 * s);            // width of the folded part
    final foldSoft = ui.lerpDouble(0.45, 0.65, s)!; // curvature softness

    if (foldW < 2) return;

    final topCtrlY = ui.lerpDouble(h * 0.14, y, 0.58)!;
    final botCtrlY = ui.lerpDouble(h * 0.86, y, 0.58)!;

    // Outer fold shape
    final path = Path()
      ..moveTo(curlX - depth, 0)
      ..quadraticBezierTo(
        curlX + depth * 0.90, topCtrlY,
        curlX, y,
      )
      ..quadraticBezierTo(
        curlX + depth * 0.90, botCtrlY,
        curlX - depth, h,
      )
      ..lineTo(curlX + foldW, h)
      ..quadraticBezierTo(
        curlX + foldW - depth * foldSoft, botCtrlY,
        curlX + foldW, y,
      )
      ..quadraticBezierTo(
        curlX + foldW - depth * foldSoft, topCtrlY,
        curlX + foldW, 0,
      )
      ..close();

    // Gradient to simulate paper back side
    final baseA = isDark ? const Color(0xFF2A3142) : const Color(0xFFF6F0E7);
    final baseB = isDark ? const Color(0xFF1E2430) : const Color(0xFFEFE6D9);
    final baseC = isDark ? const Color(0xFF262C39) : const Color(0xFFF3EADB);

    final curlPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(curlX, 0),
        Offset(curlX + foldW, 0),
        [
          baseA,
          baseB,
          baseC,
        ],
        [0.0, 0.55, 1.0],
      );

    canvas.drawPath(path, curlPaint);

    // Inner shadow to give depth
    final inner = Paint()
      ..shader = ui.Gradient.linear(
        Offset(curlX, 0),
        Offset(curlX + foldW * 0.55, 0),
        [
          Colors.black.withAlpha((65 * s).toInt()),
          Colors.transparent,
        ],
      );

    canvas.drawPath(path, inner);

    // Slight specular highlight near fold edge
    final spec = Paint()
      ..shader = ui.Gradient.linear(
        Offset(curlX + foldW * 0.72, 0),
        Offset(curlX + foldW, 0),
        [
          Colors.transparent,
          Colors.white.withAlpha((38 * s).toInt()),
        ],
      );

    canvas.drawPath(path, spec);
  }

  @override
  bool shouldRepaint(covariant _CurlFoldPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.touchY != touchY || oldDelegate.isDark != isDark;
}

/// Edge highlight: follows the same curve line (touchY-aware)
class _EdgeHighlightPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final double? touchY;

  _EdgeHighlightPainter({
    required this.progress,
    required this.isDark,
    required this.touchY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final y = (touchY ?? h * 0.52).clamp(0.0, h);

    final curlX = w * (1 - progress);
    final s = math.sin(progress * math.pi);

    final depth = h * (0.030 + 0.090 * s);
    final topCtrlY = ui.lerpDouble(h * 0.14, y, 0.58)!;
    final botCtrlY = ui.lerpDouble(h * 0.86, y, 0.58)!;

    final highlightPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.white).withAlpha((90 * s).toInt())
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(curlX - depth, 0)
      ..quadraticBezierTo(
        curlX + depth * 0.90, topCtrlY,
        curlX, y,
      )
      ..quadraticBezierTo(
        curlX + depth * 0.90, botCtrlY,
        curlX - depth, h,
      );

    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _EdgeHighlightPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.touchY != touchY || oldDelegate.isDark != isDark;
}

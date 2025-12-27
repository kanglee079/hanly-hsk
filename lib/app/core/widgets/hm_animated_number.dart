import 'package:flutter/widgets.dart';

/// Calm, reusable number tween for "streaming" UI updates.
///
/// Uses an implicit `IntTween` so values animate smoothly without manual controllers.
class HMAnimatedNumber extends ImplicitlyAnimatedWidget {
  final int value;
  final TextStyle style;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;

  const HMAnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
    super.duration = const Duration(milliseconds: 220),
    super.curve = Curves.easeOutCubic,
  });

  @override
  AnimatedWidgetBaseState<HMAnimatedNumber> createState() => _HMAnimatedNumberState();
}

class _HMAnimatedNumberState extends AnimatedWidgetBaseState<HMAnimatedNumber> {
  IntTween? _tween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tween = visitor(
      _tween,
      widget.value,
      (dynamic value) => IntTween(begin: value as int, end: widget.value),
    ) as IntTween?;
  }

  @override
  Widget build(BuildContext context) {
    final v = _tween?.evaluate(animation) ?? widget.value;
    return Text(
      '${widget.prefix}$v${widget.suffix}',
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}



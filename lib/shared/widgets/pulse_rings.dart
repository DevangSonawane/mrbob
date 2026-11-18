import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Soft rings breathing out of a circular [child] — the "live mic" glow.
///
/// Without [levelListenable] the rings pulse on a calm loop (an invitation).
/// With it, a glow disc swells with the voice and the rings speed up and
/// reach further, so the customer sees they are being heard.
///
/// One ticker, one long-lived painter, no rebuilds per frame.
class PulseRings extends StatefulWidget {
  const PulseRings({
    super.key,
    required this.child,
    required this.coreSize,
    required this.color,
    this.spread = 1.9,
    this.rings = 3,
    this.period = const Duration(milliseconds: 2400),
    this.levelListenable,
    this.active = true,
  });

  final Widget child;

  /// Diameter of the [child] disc; rings start at its edge.
  final double coreSize;
  final Color color;

  /// Outer ring diameter as a multiple of [coreSize].
  final double spread;
  final int rings;
  final Duration period;
  final ValueListenable<double>? levelListenable;

  /// False stops the rings (the child stays).
  final bool active;

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  late final _RingsPainter _painter;
  static final _zero = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6);
    if (widget.active) _ticker.start();
    _painter = _RingsPainter(time: _time)..apply(widget, _zero);
  }

  @override
  void didUpdateWidget(covariant PulseRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _painter.apply(widget, _zero);
    if (widget.active && !_ticker.isActive) _ticker.start();
    if (!widget.active && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outer = widget.coreSize * widget.spread;
    return SizedBox.square(
      dimension: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(child: CustomPaint(painter: _painter)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.time}) : super(repaint: time);

  final ValueListenable<double> time;
  late ValueListenable<double> _level;
  late double _core;
  late Color _color;
  late int _rings;
  late double _period;
  bool _reactive = false;
  double _smooth = 0;

  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;
  final _fill = Paint()..isAntiAlias = true;

  void apply(PulseRings w, ValueListenable<double> fallback) {
    _level = w.levelListenable ?? fallback;
    _reactive = w.levelListenable != null;
    _core = w.coreSize / 2;
    _color = w.color;
    _rings = w.rings;
    _period = w.period.inMilliseconds / 1000;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    _smooth += (_level.value.clamp(0.0, 1.0) - _smooth) * 0.22;
    final level = _reactive ? _smooth : 0.0;

    // Voice glow: a soft disc swelling with the level.
    if (_reactive) {
      final glowR = _core * (1.08 + 0.55 * level);
      _fill.shader = RadialGradient(
        colors: [
          _color.withValues(alpha: 0.30 + 0.25 * level),
          _color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: glowR * 1.4));
      canvas.drawCircle(c, glowR * 1.4, _fill);
      _fill.shader = null;
    }

    // Rings: faster and further when the voice is loud.
    final speed = 1 + 1.4 * level;
    final reach = _reactive ? 0.55 + 0.45 * level : 1.0;
    for (var i = 0; i < _rings; i++) {
      final p = ((t * speed / _period) + i / _rings) % 1.0;
      final eased = Curves.easeOut.transform(p);
      final r = _core + (maxR - _core) * eased * reach;
      final a = math.pow(1 - p, 1.6) * (0.42 + 0.3 * level);
      _stroke
        ..strokeWidth = 1.5 + 2.5 * (1 - p)
        ..color = _color.withValues(alpha: a.toDouble().clamp(0.0, 1.0));
      canvas.drawCircle(c, r, _stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}

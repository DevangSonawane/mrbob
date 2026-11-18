import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

/// "Finding your pro" — the booking assistant's thinking scene.
///
/// The customer's home pulses at the centre of a drifting city map while a
/// teal radar turns around it. A big magnifying glass glides over the map
/// in a figure-8 (streets magnify inside the lens), pins for nearby pros —
/// plumber, electrician, painter, carpenter, AC — pop up one by one, then
/// one is matched: it gets a gold ring and a dashed gold route draws to the
/// home. Loops seamlessly on one 6-second controller (every motion is a
/// whole number of cycles per loop).
class ZingSearchScene extends StatefulWidget {
  const ZingSearchScene({super.key, this.width = 300});

  final double width;

  @override
  State<ZingSearchScene> createState() => _ZingSearchSceneState();
}

class _ZingSearchSceneState extends State<ZingSearchScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  static const _home = Offset(0.5, 0.54);

  /// Pro pins: position on the map (0..1), tool, tint, and when it lands.
  static const _pins = [
    _Pin(Offset(0.18, 0.22), LucideIcons.wrench, Color(0xFF1E88E5), 0.06),
    _Pin(Offset(0.83, 0.70), LucideIcons.zap, Color(0xFFF29A0B), 0.18),
    _Pin(Offset(0.14, 0.72), LucideIcons.paintRoller, Color(0xFFD81B60), 0.30),
    _Pin(Offset(0.62, 0.14), LucideIcons.hammer, Color(0xFF6D4C41), 0.42),
    _Pin(Offset(0.86, 0.30), LucideIcons.airVent, AppColors.brandTeal, 0.54),
  ];

  /// The pin that gets matched at the end of each loop (the electrician).
  static const _matched = 1;

  // Match timeline (fractions of the loop).
  static const _routeStart = 0.68;
  static const _routeEnd = 0.82;
  static const _clearAt = 0.93;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 0.92;
    final home = Offset(_home.dx * w, _home.dy * h);
    return RepaintBoundary(
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = _loop.value;
            final matchedPos = Offset(
              _pins[_matched].pos.dx * w,
              _pins[_matched].pos.dy * h,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: CustomPaint(
                      painter: _MapPainter(
                        t: t,
                        home: home,
                        routeFrom: matchedPos,
                        routeProgress: _routeProgress(t),
                      ),
                    ),
                  ),
                ),
                for (var i = 0; i < _pins.length; i++)
                  _buildPin(_pins[i], t, w, h, matched: i == _matched),
                _buildHome(home, t),
                // The searching glass, above everything on the map.
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: CustomPaint(painter: _GlassPainter(t: t)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 0 → 1 while the route draws, 0 outside the match window.
  static double _routeProgress(double t) {
    if (t < _routeStart || t > _clearAt) return 0;
    return Curves.easeInOut.transform(
      ((t - _routeStart) / (_routeEnd - _routeStart)).clamp(0.0, 1.0),
    );
  }

  Widget _buildHome(Offset c, double t) {
    const size = 50.0;
    final beat = 1 + 0.05 * math.sin(t * 2 * math.pi * 3);
    // A happy bump when the route arrives.
    final arrived = t > _routeEnd && t < _clearAt;
    final bump = arrived
        ? 1 +
              0.12 *
                  math.sin(((t - _routeEnd) / 0.05).clamp(0.0, 1.0) * math.pi)
        : 1.0;
    return Positioned(
      left: c.dx - size / 2,
      top: c.dy - size,
      child: Transform.scale(
        scale: beat * bump,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.brandForest,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandForest.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.house,
                color: AppColors.brandGold,
                size: 22,
              ),
            ),
            CustomPaint(
              size: const Size(14, 8),
              painter: _TailPainter(AppColors.brandForest),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin(
    _Pin pin,
    double t,
    double w,
    double h, {
    required bool matched,
  }) {
    const land = 0.10;
    final since = t - pin.at;
    double scale;
    double opacity;
    if (since < 0) {
      scale = 0;
      opacity = 0;
    } else if (since < land) {
      scale = Curves.elasticOut.transform(since / land);
      opacity = (since / land * 3).clamp(0.0, 1.0);
    } else if (t > _clearAt) {
      final out = ((t - _clearAt) / (1 - _clearAt)).clamp(0.0, 1.0);
      scale = 1 - 0.4 * out;
      opacity = 1 - out;
    } else {
      scale = 1 + 0.04 * math.sin((t - pin.at) * 2 * math.pi * 4);
      // Unmatched pros step back once the match is found.
      opacity = !matched && t > _routeStart ? 0.45 : 1;
    }
    final isMatch = matched && t > _routeStart && t <= _clearAt;
    final size = isMatch ? 42.0 : 36.0;
    final color = isMatch ? AppColors.brandGold : pin.color;
    return Positioned(
      left: pin.pos.dx * w - size / 2,
      top: pin.pos.dy * h - size - 6,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: isMatch ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: isMatch ? 0.55 : 0.30),
                          blurRadius: isMatch ? 16 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(pin.icon, size: 17, color: pin.color),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _TailPainter(color),
                  ),
                ],
              ),
              if (isMatch)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.brandForest,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 10,
                      color: AppColors.brandGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pin {
  const _Pin(this.pos, this.icon, this.color, this.at);

  final Offset pos;
  final IconData icon;
  final Color color;
  final double at;
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}

/// Shared street layout so the lens can magnify the same map.
void _paintStreets(Canvas canvas, Size size, double t, {double alpha = 1}) {
  const spacing = 34.0;
  final shift = t * spacing;
  final street = Paint()
    ..color = AppColors.brandTeal.withValues(alpha: 0.07 * alpha)
    ..strokeWidth = 1.2;
  for (var x = -spacing + shift; x < size.width + spacing; x += spacing) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), street);
  }
  for (var y = -spacing + shift; y < size.height + spacing; y += spacing) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), street);
  }
  final road = Paint()
    ..color = Colors.white
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;
  final roadEdge = Paint()
    ..color = AppColors.brandTeal.withValues(alpha: 0.10 * alpha)
    ..strokeWidth = 11
    ..strokeCap = StrokeCap.round;
  final a1 = Offset(-20, size.height * 0.30 + shift);
  final b1 = Offset(size.width + 20, size.height * 0.05 + shift);
  final a2 = Offset(size.width * 0.25 - shift, size.height + 20);
  final b2 = Offset(size.width * 0.45 - shift, -20);
  for (final (a, b) in [(a1, b1), (a2, b2)]) {
    canvas.drawLine(a, b, roadEdge);
    canvas.drawLine(a, b, road);
  }
}

/// Cream city map, a teal radar turning around the home, the dashed gold
/// route of the matched pro, and twinkling gold sparks.
class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.t,
    required this.home,
    required this.routeFrom,
    required this.routeProgress,
  });

  final double t;
  final Offset home;
  final Offset routeFrom;
  final double routeProgress;

  static const _teal = AppColors.brandTeal;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceTint, Color(0xFFFFFBF1)],
        ).createShader(rect),
    );
    _paintStreets(canvas, size, t);

    // Radar around the home: rings, ripples and a turning sweep.
    final maxR = size.longestSide * 0.62;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _teal.withValues(alpha: 0.12);
    for (final f in [0.3, 0.55, 0.8]) {
      canvas.drawCircle(home, maxR * f, ring);
    }
    for (var i = 0; i < 2; i++) {
      final p = ((t * 3) + i / 2) % 1.0;
      canvas.drawCircle(
        home,
        28 + 70 * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - p) + 0.5
          ..color = _teal.withValues(alpha: 0.30 * (1 - p)),
      );
    }
    canvas.save();
    canvas.translate(home.dx, home.dy);
    canvas.rotate(t * 2 * math.pi * 2);
    final sweepRect = Rect.fromCircle(center: Offset.zero, radius: maxR);
    canvas.drawCircle(
      Offset.zero,
      maxR,
      Paint()
        ..shader = SweepGradient(
          colors: [
            _teal.withValues(alpha: 0),
            _teal.withValues(alpha: 0),
            _teal.withValues(alpha: 0.16),
          ],
          stops: const [0, 0.8, 1],
        ).createShader(sweepRect),
    );
    canvas.restore();

    // Matched pro → home: a dashed gold route that draws itself.
    if (routeProgress > 0) {
      final mid = Offset(
        (routeFrom.dx + home.dx) / 2,
        math.max(routeFrom.dy, home.dy) + 40,
      );
      final route = Path()
        ..moveTo(routeFrom.dx, routeFrom.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, home.dx, home.dy);
      final metric = route.computeMetrics().first;
      final dashed = _dash(metric, metric.length * routeProgress);
      canvas.drawPath(
        dashed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
      canvas.drawPath(
        dashed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = AppColors.brandGold,
      );
    }

    const sparks = [
      Offset(0.32, 0.10),
      Offset(0.72, 0.48),
      Offset(0.26, 0.48),
      Offset(0.52, 0.90),
    ];
    for (var i = 0; i < sparks.length; i++) {
      final a = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 3 + i * 1.7);
      _star(
        canvas,
        Offset(sparks[i].dx * size.width, sparks[i].dy * size.height),
        4 + 3 * a,
        AppColors.brandGold.withValues(alpha: 0.25 + 0.6 * a),
      );
    }
  }

  Path _dash(PathMetric metric, double upTo) {
    const dash = 9.0, gap = 7.0;
    final out = Path();
    var d = 0.0;
    while (d < upTo) {
      out.addPath(metric.extractPath(d, math.min(d + dash, upTo)), Offset.zero);
      d += dash + gap;
    }
    return out;
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 - math.pi / 2;
      final rr = k.isEven ? r : r * 0.32;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t;
}

/// The magnifying glass gliding over the map in a figure-8: magnified
/// streets inside a lightly tinted lens, a white glint, a forest rim and a
/// forest handle with a gold band, with a soft drop shadow.
class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const tau = 2 * math.pi;
    final r = size.width * 0.12;
    final c = Offset(
      size.width * (0.5 + 0.30 * math.sin(t * tau)),
      size.height * (0.46 + 0.22 * math.sin(t * tau * 2)),
    );
    // Handle points down-right, swaying slightly with the motion.
    final angle = math.pi / 4 + 0.15 * math.sin(t * tau);
    final dir = Offset(math.cos(angle), math.sin(angle));

    // Drop shadow (glass "floats" above the map).
    final shadow = Paint()
      ..color = AppColors.brandForest.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(c + const Offset(8, 12), r, shadow);
    canvas.drawLine(
      c + const Offset(8, 12) + dir * r,
      c + const Offset(8, 12) + dir * (r * 2.3),
      shadow..strokeWidth = r * 0.42,
    );

    // Handle.
    final handle = Paint()
      ..color = AppColors.brandForest
      ..strokeWidth = r * 0.36
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + dir * (r * 1.05), c + dir * (r * 2.3), handle);
    canvas.drawLine(
      c + dir * (r * 1.25),
      c + dir * (r * 1.45),
      Paint()
        ..color = AppColors.brandGold
        ..strokeWidth = r * 0.40,
    );

    // Lens: magnified streets.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    canvas.drawCircle(
      c,
      r,
      Paint()..color = const Color(0xFFDDF3F4).withValues(alpha: 0.55),
    );
    canvas.translate(c.dx, c.dy);
    canvas.scale(1.7);
    canvas.translate(-c.dx, -c.dy);
    _paintStreets(canvas, size, t, alpha: 2.2);
    canvas.restore();

    // Glint + rim.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.66),
      math.pi * 1.05,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.20
        ..color = AppColors.brandForest,
    );
    canvas.drawCircle(
      c,
      r * 1.08,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.brandGold.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter old) => old.t != t;
}

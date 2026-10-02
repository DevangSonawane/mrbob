import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flutter port (inspired by, not copied from) thinking-orbs `listening`
/// state — MIT by Jakub Antalik.
///
/// Dotted sphere + tilted orbit particles, waveform rolling through.
/// Drives off the amplitude source (0..1) — prefer wiring
/// [ThinkingOrb.amplitudeListenable] straight to a live `_voiceLevel`.
///
/// Perf contract: this repaints every frame for as long as it is on screen,
/// often on top of a glass shader and a backdrop blur. So there is exactly
/// one painter for the orb's whole life, it is driven by a [Listenable]
/// rather than by widget rebuilds, and every per-frame buffer is allocated
/// once and refilled in place. A steady-state frame allocates nothing but
/// the alpha-modulated colours handed to the one shared [Paint].
enum ThinkingOrbState { listening, breathing, working }

class ThinkingOrb extends StatefulWidget {
  const ThinkingOrb({
    super.key,
    this.size = 120,
    this.state = ThinkingOrbState.listening,
    this.amplitude = 0,
    this.amplitudeListenable,
    this.ink,
    this.speed = 1.0,
    this.dotCount = 380,
  });

  final double size;
  final ThinkingOrbState state;

  /// Static amplitude. Only read when [amplitudeListenable] is null.
  final double amplitude;

  /// Live amplitude source. Preferred: the painter subscribes to it, so a
  /// mic tick repaints the orb without rebuilding this widget or allocating
  /// a fresh painter for the tick.
  final ValueListenable<double>? amplitudeListenable;

  final Color? ink;
  final double speed;

  /// Sphere dot budget. The visual difference between 380 and 560 dots on
  /// a soft orb is invisible; the draw, sort and buffer cost is not.
  final int dotCount;

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  /// Long-lived painter. Mutated in place by [didUpdateWidget]; never
  /// recreated, so the repaint path stays allocation-free.
  late _OrbPainter _painter;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
    // Seeded with widget.ink only. Theme.of is not legal before
    // didChangeDependencies completes, so the brightness-aware ink is
    // resolved there instead.
    _painter = _OrbPainter(
      clock: _clock,
      repaint: _resolveRepaint(),
      ink: widget.ink ?? _lightInk,
      state: widget.state,
      speed: widget.speed,
      dotCount: widget.dotCount,
      amplitudeListenable: widget.amplitudeListenable,
      amplitude: widget.amplitude,
    );
  }

  Listenable _resolveRepaint() {
    final live = widget.amplitudeListenable;
    return live == null ? _clock : Listenable.merge([_clock, live]);
  }

  static const _lightInk = Color(0xFF0D230D);
  static const _darkInk = Colors.white;

  /// Brightness-aware ink. Must only be called once the inherited theme is
  /// reachable — i.e. from [didChangeDependencies] or later, never from
  /// [initState].
  Color _resolveInk() =>
      widget.ink ??
      (Theme.of(context).brightness == Brightness.dark
          ? _darkInk
          : _lightInk);

  /// Pushes the resolved ink into the painter. Ink feeds the cached glow
  /// shaders and warmth ramp, so a change re-derives both.
  void _applyThemeInk() {
    final next = _resolveInk();
    if (next != _painter.ink) {
      _painter
        ..ink = next
        ..rebuildGeometry();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyThemeInk();
  }

  @override
  void didUpdateWidget(covariant ThinkingOrb old) {
    super.didUpdateWidget(old);
    _painter.amplitudeListenable = widget.amplitudeListenable;
    _painter.amplitude = widget.amplitude;
    if (old.state != widget.state) {
      _painter.state = widget.state;
    }
    if (old.speed != widget.speed) {
      _painter.speed = widget.speed;
    }
    if (old.dotCount != widget.dotCount) {
      _painter
        ..dotCount = widget.dotCount
        ..rebuildGeometry();
    }
    // An explicit ink needs no inherited theme, so it is safe to apply here;
    // a null ink is picked up by didChangeDependencies instead.
    if (widget.ink != null && widget.ink != _painter.ink) {
      _painter
        ..ink = widget.ink!
        ..rebuildGeometry();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _painter,
      ),
    );
  }
}

class _Vec {
  const _Vec(this.x, this.y, this.z, this.phase);
  final double x;
  final double y;
  final double z;
  final double phase;
}

/// True Fibonacci sphere with per-dot random phase for twinkle.
List<_Vec> _fibonacciSphere(int count) {
  final rand = math.Random(7);
  final golden = math.pi * (3 - math.sqrt(5));
  return List.generate(count, (i) {
    final y = 1 - (i / (count - 1)) * 2;
    final r = math.sqrt(math.max(0, 1 - y * y));
    final theta = golden * i;
    return _Vec(
      r * math.cos(theta),
      y,
      r * math.sin(theta),
      rand.nextDouble() * math.pi * 2,
    );
  });
}

/// Tilted orbit ring particles (the lively "working" feel, always on).
List<_Vec> _orbitRing(int count, double tilt) {
  final rand = math.Random(21);
  return List.generate(count, (i) {
    final a = (i / count) * math.pi * 2;
    return _Vec(
      math.cos(a),
      math.sin(a) * math.cos(tilt),
      math.sin(a) * math.sin(tilt),
      rand.nextDouble() * math.pi * 2,
    );
  });
}

final _sphere560 = _fibonacciSphere(560);
final _ringA = _orbitRing(64, 0.5);
final _ringB = _orbitRing(52, -0.9);

const _gold = Color(0xFFFCB723);

/// Amplitude resolution for the cached glow and warmth ramps. Eight steps
/// over a 0.14 -> 0.30 alpha range is well under a perceptible step.
const int _ampBuckets = 8;
const int _depthBuckets = 16;

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.clock,
    required Listenable repaint,
    required this.ink,
    required this.state,
    required this.speed,
    required this.dotCount,
    required this.amplitudeListenable,
    required this.amplitude,
  }) : super(repaint: repaint) {
    rebuildGeometry();
  }

  final Animation<double> clock;
  Color ink;
  ThinkingOrbState state;
  double speed;
  int dotCount;
  ValueListenable<double>? amplitudeListenable;
  double amplitude;

  // ── Reusable per-frame buffers ───────────────────────────────────────────
  // All of this used to be built inside paint(): a fresh dot list, ~720
  // _PaintDot objects, ~720 Paint objects and a `.take()` slice every frame.
  // Sized once on geometry change, refilled in place afterwards.
  final List<_PaintDot> _dots = <_PaintDot>[];
  final Paint _dotPaint = Paint();

  late List<_Vec> _sphere;
  late List<Paint> _glowPaints;
  late List<List<Color>> _warmthRamp;

  void rebuildGeometry() {
    _sphere = dotCount >= _sphere560.length
        ? _sphere560
        : _sphere560.sublist(0, dotCount);

    final total = _sphere.length + _ringA.length + _ringB.length;
    while (_dots.length > total) {
      _dots.removeLast();
    }
    while (_dots.length < total) {
      _dots.add(_PaintDot());
    }

    // Unit-radius glow shaders, drawn through a canvas scale so the
    // per-frame radius change costs no shader allocation.
    _glowPaints = List.generate(_ampBuckets, (a) {
      final amp = a / (_ampBuckets - 1);
      return Paint()
        ..shader = RadialGradient(
          colors: [
            ink.withValues(alpha: 0.14 + amp * 0.16),
            ink.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
    });

    // ink -> gold warmth is a per-dot lerp, so quantise it into a small
    // amplitude x depth table instead of allocating a colour per dot.
    _warmthRamp = List.generate(_ampBuckets, (a) {
      final amp = (a + 1) / _ampBuckets;
      return List<Color>.generate(_depthBuckets, (d) {
        final depth = d / (_depthBuckets - 1);
        final warmth = (depth * amp * 0.55).clamp(0.0, 0.6);
        return Color.lerp(ink, _gold, warmth) ?? ink;
      });
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final amp = (amplitudeListenable?.value ?? amplitude).clamp(0.0, 1.0);
    final ampIdx = (amp * _ampBuckets).ceil() - 1;
    final bucket = ampIdx < 0 ? 0 : (ampIdx > _ampBuckets - 1 ? _ampBuckets - 1 : ampIdx);

    final t = clock.value * 2 * math.pi * speed;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 * 0.72;

    // Lively global pulse — never sits still, voice pumps it harder.
    final pulse =
        1 + 0.035 * math.sin(t * 1.6) + amp * 0.10 * math.sin(t * 3.1);
    final radius = baseRadius * pulse;

    // Energy floor stays high so idle still shimmers.
    final breathe = 0.5 + 0.5 * math.sin(t * 1.1);
    final energy = switch (state) {
      ThinkingOrbState.listening => 0.45 + amp * 0.85 + breathe * 0.10,
      ThinkingOrbState.breathing => 0.45 + 0.20 * breathe,
      ThinkingOrbState.working => 0.9,
    };

    // Soft glow behind — forest at low alpha, swells with voice.
    final glowR = radius * (1.35 + amp * 0.25);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(glowR);
    canvas.drawCircle(Offset.zero, 1, _glowPaints[bucket]);
    canvas.restore();

    // Rotation speeds up with voice — feels responsive.
    final rotSpeed =
        (state == ThinkingOrbState.working ? 1.1 : 0.75) + amp * 0.9;
    final rotY = t * rotSpeed;
    final rotX = 0.42 + 0.18 * math.sin(t * 0.7);
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    var n = 0;
    final dotScale = size.width / 170;
    for (var i = 0; i < _sphere.length; i++) {
      final v = _sphere[i];
      final x1 = v.x * cosY + v.z * sinY;
      final z1 = -v.x * sinY + v.z * cosY;
      final y1 = v.y * cosX - z1 * sinX;
      final z2 = v.y * sinX + z1 * cosX;

      // Two crossing waves rolling through the rings.
      final wave =
          math.sin(y1 * 5.0 + t * 2.6) * 0.14 * energy +
          math.sin(x1 * 3.5 - t * 2.0 + v.phase * 0.15) * 0.08 * energy;
      final r = radius * (1 + wave);

      final depth = (z2 + 1) / 2;
      // Per-dot twinkle — the shimmer that makes it feel alive.
      final twinkle = 0.72 + 0.28 * math.sin(t * 2.4 + v.phase);
      _dots[n++]
        ..offset = Offset(center.dx + x1 * r, center.dy + y1 * r)
        ..radius =
            dotScale.clamp(0.9, 3.0) *
            (0.35 + depth * 1.1) *
            twinkle *
            (1 + amp * 0.35)
        ..depth = depth
        ..twinkle = twinkle;
    }

    // Orbit particles — faster tilted rings skimming the surface.
    final ringDotScale = size.width / 200;
    void addRing(List<_Vec> ring, double ringR, double spin, double scale) {
      final c = math.cos(t * spin);
      final s = math.sin(t * spin);
      for (var i = 0; i < ring.length; i++) {
        final v = ring[i];
        final x1 = v.x * c - v.y * s;
        final y1 = v.x * s + v.y * c;
        final depth = (v.z + 1) / 2;
        final tw = 0.6 + 0.4 * math.sin(t * 3.0 + v.phase);
        _dots[n++]
          ..offset = Offset(
            center.dx + x1 * radius * ringR,
            center.dy + y1 * radius * ringR,
          )
          ..radius = ringDotScale.clamp(0.8, 2.4) * scale * tw
          ..depth = depth
          ..twinkle = tw;
      }
    }

    addRing(_ringA, 1.12, 1.3 + amp, 1.0);
    addRing(_ringB, 1.22, -1.0 - amp * 0.8, 0.8);

    // n always lands on _dots.length (the sphere slice plus both rings),
    // so this sorts the reusable buffer in place rather than slicing a copy.
    assert(n == _dots.length);
    _dots.sort((a, b) => a.depth.compareTo(b.depth));

    final ramp = _warmthRamp[bucket];
    for (var i = 0; i < n; i++) {
      final d = _dots[i];
      // Front + loud dots warm toward gold — lively color response.
      final depthIdx =
          (d.depth * (_depthBuckets - 1)).round().clamp(0, _depthBuckets - 1);
      _dotPaint.color = ramp[depthIdx].withValues(
        alpha: (0.22 + d.depth * 0.78) * (0.75 + d.twinkle * 0.25),
      );
      canvas.drawCircle(d.offset, d.radius, _dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => false;
}

/// Mutable so the orb can refill it every frame instead of allocating.
class _PaintDot {
  Offset offset = Offset.zero;
  double radius = 0;
  double depth = 0;
  double twinkle = 0;
}
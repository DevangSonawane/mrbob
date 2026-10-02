import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Geometry preset for [VoiceBeam] — the `type` prop of `voice-glow`.
///
/// Mirrors the three canvases the upstream library ships: a ~350px chat
/// input, a ~150x44 recording pill, and the bottom edge of a phone screen.
enum VoiceBeamType {
  /// ~350px chat input. The reference geometry the other two derive from.
  standard,

  /// ~150x44 recording pill: short, wide, shallow rise.
  pill,

  /// Bottom of a phone screen: a long beam running the full width.
  mobile,
}

/// The `colorVariant` prop: a named lobe palette plus its matching band
/// colours. `colorful` is upstream's default; the rest are their variants.
enum VoiceBeamColorVariant {
  colorful,
  mono,
  ocean,
  sunset,
  forest,
  candy,
  ice,
  gold,
}

/// The `bandColors` prop: `{ core, above, mid, below }`.
@immutable
class VoiceBeamBandColors {
  const VoiceBeamBandColors({
    required this.core,
    required this.above,
    required this.mid,
    required this.below,
  });

  /// The bright inner line drawn along the beam crest.
  final Color core;

  /// Wide soft bloom behind the crest.
  final Color above;

  /// Chromatic fringe on one side of the crest.
  final Color mid;

  /// Chromatic fringe on the opposite side.
  final Color below;
}

/// Flutter port of `voice-glow`'s VoiceBeam (libraries.dev/voice).
///
/// Overlays a sound-reactive glow along the bottom edge of [child]: a
/// centred, colourful beam that rises and blooms with the voice, and that
/// gathers into a travelling sweep while [processing] is true.
///
/// Geometry provenance:
///  - [VoiceBeamType.standard] uses the upstream default-type constants
///    verbatim (7 lobes at x 0/±36/±72/±108, w 74/54/48/42, h 46/40/32/26,
///    lobeSpacing 0.85, glowWidth 0.65, glowHeight 1.25, reach 1.2,
///    spread 1.05, flow 48px/s, bend 60px, idle 0.18 / 5.2s, attack 0.325s,
///    release 0.86s, gain 3.1, gate 0.015, stroke/inner/bloom opacities
///    1.16 / 0.47 / 0.89 against 170x64 and 200x130 masks, processing gather
///    0.6, mask 0.45, travel 1.55x half-ring, curve 2.1, held level 0.55).
///  - [VoiceBeamType.pill] and [VoiceBeamType.mobile] are derived from the
///    canvas sizes upstream documents for them (~150x44 pill, phone-width
///    bottom edge) rather than transcribed, so they are proportioned for
///    those footprints, not byte-identical to upstream.
///
/// Every per-frame buffer is allocated once and refilled in place: this
/// repaints continuously and usually sits on top of a glass surface.
class VoiceBeam extends StatefulWidget {
  const VoiceBeam({
    super.key,
    required this.child,
    this.levelListenable,
    this.level = 0,
    this.processing = false,
    this.type = VoiceBeamType.standard,
    this.borderRadius = 20,
    this.strength = 1.0,
    this.active = true,
    this.colorVariant = VoiceBeamColorVariant.colorful,
    this.lobeColors,
    this.bandColors,
    this.theme = VoiceBeamTheme.dark,
    this.scale = 1.0,
    this.processingDuration = 1.1,
  });

  final Widget child;

  /// Live 0–1 amplitude. Preferred over [level]; the painter subscribes to
  /// it directly so a mic tick repaints only the beam.
  final ValueListenable<double>? levelListenable;

  /// Static amplitude, used when [levelListenable] is null.
  final double level;

  /// Gathers the glow into a beam that travels its range while work is in
  /// progress.
  final bool processing;

  /// Geometry preset.
  final VoiceBeamType type;

  /// Corner radius of [child]. Upstream auto-detects this from the DOM node;
  /// Flutter has no equivalent, so it is explicit.
  final double borderRadius;

  /// Effect opacity, 0–1.
  final double strength;

  /// Whether the effect runs at all.
  final bool active;

  /// Named palette. Ignored when [lobeColors] is supplied.
  final VoiceBeamColorVariant colorVariant;

  /// Up to 7 lobe colours, overriding [colorVariant]'s lobe palette.
  final List<Color>? lobeColors;

  /// Band colours, overriding [colorVariant]'s band palette.
  final VoiceBeamBandColors? bandColors;

  /// Light/dark tuning of the crest, which upstream draws for dark chrome.
  final VoiceBeamTheme theme;

  /// Multiplies every geometric dimension, for callers that need the effect
  /// larger or smaller than the canvas implies.
  final double scale;

  /// Seconds for one full sweep while [processing].
  final double processingDuration;

  @override
  State<VoiceBeam> createState() => _VoiceBeamState();
}

enum VoiceBeamTheme { dark, light }

/// Per-preset geometry. All lengths are in the preset's own logical units and
/// scaled at paint time against the child's width.
class _Geometry {
  const _Geometry({
    required this.refWidth,
    required this.lobeX,
    required this.lobeW,
    required this.lobeH,
    required this.lobeBand,
    required this.lobeSpacing,
    required this.spanBase,
    required this.glowW,
    required this.glowH,
    required this.reach,
    required this.spread,
    required this.flow,
    required this.bend,
    required this.idle,
    required this.breatheDur,
    required this.strokeW,
    required this.strokeH,
    required this.bloomW,
    required this.bloomH,
  });

  final double refWidth;
  final List<double> lobeX;
  final List<double> lobeW;
  final List<double> lobeH;
  final List<int> lobeBand;
  final double lobeSpacing;
  final double spanBase;
  final double glowW;
  final double glowH;
  final double reach;
  final double spread;
  final double flow;
  final double bend;
  final double idle;
  final double breatheDur;
  final double strokeW;
  final double strokeH;
  final double bloomW;
  final double bloomH;
}

const _gStandard = _Geometry(
  refWidth: 350,
  lobeX: [0, -36, 36, -72, 72, -108, 108],
  lobeW: [74, 54, 54, 48, 48, 42, 42],
  lobeH: [46, 40, 40, 32, 32, 26, 26],
  lobeBand: [0, 1, 1, 2, 2, 1, 1],
  lobeSpacing: 0.85,
  spanBase: 252,
  glowW: 0.65,
  glowH: 1.25,
  reach: 1.2,
  spread: 1.05,
  flow: 48,
  bend: 60,
  idle: 0.18,
  breatheDur: 5.2,
  strokeW: 170,
  strokeH: 64,
  bloomW: 200,
  bloomH: 130,
);

// ~150x44 pill: the same lobe rhythm squeezed to a short, shallow footprint.
const _gPill = _Geometry(
  refWidth: 150,
  lobeX: [0, -22, 22, -42, 42, -60, 60],
  lobeW: [40, 30, 30, 26, 26, 22, 22],
  lobeH: [26, 22, 22, 18, 18, 15, 15],
  lobeBand: [0, 1, 1, 2, 2, 1, 1],
  lobeSpacing: 0.7,
  spanBase: 150,
  glowW: 0.7,
  glowH: 1.0,
  reach: 1.0,
  spread: 1.0,
  flow: 34,
  bend: 26,
  idle: 0.16,
  breatheDur: 4.4,
  strokeW: 110,
  strokeH: 40,
  bloomW: 150,
  bloomH: 84,
);

// Phone-width bottom edge: a long beam with a taller, slower rise.
const _gMobile = _Geometry(
  refWidth: 390,
  lobeX: [0, -52, 52, -104, 104, -156, 156],
  lobeW: [104, 78, 78, 68, 68, 60, 60],
  lobeH: [66, 58, 58, 46, 46, 38, 38],
  lobeBand: [0, 1, 1, 2, 2, 1, 1],
  lobeSpacing: 1.1,
  spanBase: 300,
  glowW: 0.6,
  glowH: 1.35,
  reach: 1.35,
  spread: 1.1,
  flow: 60,
  bend: 90,
  idle: 0.2,
  breatheDur: 6.0,
  strokeW: 300,
  strokeH: 120,
  bloomW: 360,
  bloomH: 220,
);

_Geometry _geometryFor(VoiceBeamType type) => switch (type) {
  VoiceBeamType.standard => _gStandard,
  VoiceBeamType.pill => _gPill,
  VoiceBeamType.mobile => _gMobile,
};

/// Lobe + band palettes for each named `colorVariant`.
class _Palette {
  const _Palette(this.lobes, this.band);
  final List<Color> lobes;
  final VoiceBeamBandColors band;
}

const _pColorful = _Palette(
  [
    Color.fromRGBO(255, 70, 120, 1),
    Color.fromRGBO(60, 190, 255, 1),
    Color.fromRGBO(175, 70, 255, 1),
    Color.fromRGBO(60, 220, 130, 1),
    Color.fromRGBO(255, 150, 40, 1),
    Color.fromRGBO(90, 100, 255, 1),
    Color.fromRGBO(40, 200, 190, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(140, 120, 255, 1),
    above: Color.fromRGBO(255, 70, 80, 1),
    mid: Color.fromRGBO(80, 140, 255, 1),
    below: Color.fromRGBO(80, 140, 255, 1),
  ),
);

const _pMono = _Palette(
  [
    Color.fromRGBO(255, 255, 255, 1),
    Color.fromRGBO(226, 232, 240, 1),
    Color.fromRGBO(203, 213, 225, 1),
    Color.fromRGBO(180, 190, 205, 1),
    Color.fromRGBO(160, 170, 185, 1),
    Color.fromRGBO(140, 150, 165, 1),
    Color.fromRGBO(120, 130, 145, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(148, 163, 184, 1),
    above: Color.fromRGBO(226, 232, 240, 1),
    mid: Color.fromRGBO(203, 213, 225, 1),
    below: Color.fromRGBO(148, 163, 184, 1),
  ),
);

const _pOcean = _Palette(
  [
    Color.fromRGBO(0, 200, 220, 1),
    Color.fromRGBO(20, 150, 230, 1),
    Color.fromRGBO(40, 110, 220, 1),
    Color.fromRGBO(0, 220, 170, 1),
    Color.fromRGBO(70, 180, 255, 1),
    Color.fromRGBO(25, 95, 190, 1),
    Color.fromRGBO(0, 160, 200, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(56, 189, 248, 1),
    above: Color.fromRGBO(14, 165, 233, 1),
    mid: Color.fromRGBO(45, 212, 191, 1),
    below: Color.fromRGBO(59, 130, 246, 1),
  ),
);

const _pSunset = _Palette(
  [
    Color.fromRGBO(255, 94, 98, 1),
    Color.fromRGBO(255, 150, 60, 1),
    Color.fromRGBO(255, 45, 140, 1),
    Color.fromRGBO(255, 200, 80, 1),
    Color.fromRGBO(190, 60, 220, 1),
    Color.fromRGBO(255, 120, 30, 1),
    Color.fromRGBO(240, 70, 180, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(255, 138, 76, 1),
    above: Color.fromRGBO(255, 94, 98, 1),
    mid: Color.fromRGBO(255, 45, 140, 1),
    below: Color.fromRGBO(190, 60, 220, 1),
  ),
);

const _pForest = _Palette(
  [
    Color.fromRGBO(140, 220, 120, 1),
    Color.fromRGBO(70, 200, 140, 1),
    Color.fromRGBO(40, 170, 110, 1),
    Color.fromRGBO(180, 230, 110, 1),
    Color.fromRGBO(90, 215, 190, 1),
    Color.fromRGBO(30, 140, 90, 1),
    Color.fromRGBO(200, 240, 150, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(134, 239, 172, 1),
    above: Color.fromRGBO(74, 222, 128, 1),
    mid: Color.fromRGBO(45, 212, 191, 1),
    below: Color.fromRGBO(163, 230, 53, 1),
  ),
);

const _pCandy = _Palette(
  [
    Color.fromRGBO(255, 130, 200, 1),
    Color.fromRGBO(150, 200, 255, 1),
    Color.fromRGBO(200, 160, 255, 1),
    Color.fromRGBO(255, 200, 120, 1),
    Color.fromRGBO(150, 255, 210, 1),
    Color.fromRGBO(255, 160, 180, 1),
    Color.fromRGBO(190, 230, 255, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(216, 180, 254, 1),
    above: Color.fromRGBO(251, 191, 236, 1),
    mid: Color.fromRGBO(147, 197, 253, 1),
    below: Color.fromRGBO(253, 224, 71, 1),
  ),
);

const _pIce = _Palette(
  [
    Color.fromRGBO(224, 247, 255, 1),
    Color.fromRGBO(186, 230, 253, 1),
    Color.fromRGBO(165, 214, 245, 1),
    Color.fromRGBO(207, 240, 252, 1),
    Color.fromRGBO(147, 205, 232, 1),
    Color.fromRGBO(203, 232, 248, 1),
    Color.fromRGBO(175, 226, 245, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(240, 253, 255, 1),
    above: Color.fromRGBO(186, 230, 253, 1),
    mid: Color.fromRGBO(125, 211, 252, 1),
    below: Color.fromRGBO(148, 196, 220, 1),
  ),
);

const _pGold = _Palette(
  [
    Color.fromRGBO(255, 199, 44, 1),
    Color.fromRGBO(255, 168, 38, 1),
    Color.fromRGBO(240, 140, 20, 1),
    Color.fromRGBO(255, 226, 120, 1),
    Color.fromRGBO(220, 120, 60, 1),
    Color.fromRGBO(200, 100, 30, 1),
    Color.fromRGBO(255, 240, 170, 1),
  ],
  VoiceBeamBandColors(
    core: Color.fromRGBO(253, 224, 71, 1),
    above: Color.fromRGBO(251, 191, 36, 1),
    mid: Color.fromRGBO(249, 115, 22, 1),
    below: Color.fromRGBO(234, 179, 8, 1),
  ),
);

_Palette _paletteFor(VoiceBeamColorVariant variant) => switch (variant) {
  VoiceBeamColorVariant.colorful => _pColorful,
  VoiceBeamColorVariant.mono => _pMono,
  VoiceBeamColorVariant.ocean => _pOcean,
  VoiceBeamColorVariant.sunset => _pSunset,
  VoiceBeamColorVariant.forest => _pForest,
  VoiceBeamColorVariant.candy => _pCandy,
  VoiceBeamColorVariant.ice => _pIce,
  VoiceBeamColorVariant.gold => _pGold,
};

// Input chain + processing constants (upstream voiceDefaults, dark).
const _sensitivity = 3.1;
const _threshold = 0.015;
const _attack = 0.325;
const _release = 0.86;
const _procLevel = 0.55;
const _procTravel = 1.55;
const _procCurve = 2.1;
const _innerOp = 0.47;
const _bloomOp = 0.89;

class _VoiceBeamState extends State<VoiceBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  late _VoiceBeamPainter _painter;
  double _lastTick = 0;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..repeat();
    _lastTick = _now();
    _painter = _VoiceBeamPainter(
      clock: _clock,
      levelListenable: widget.levelListenable,
      level: widget.level,
      processing: widget.processing,
      strength: widget.strength,
      active: widget.active,
      palette: _resolvePalette(),
      geometry: _geometryFor(widget.type),
      theme: widget.theme,
      scale: widget.scale,
      borderRadius: widget.borderRadius,
      processingDuration: widget.processingDuration,
      onTick: _dt,
    );
  }

  _Palette _resolvePalette() {
    final base = _paletteFor(widget.colorVariant);
    final lobes = widget.lobeColors;
    return _Palette(lobes ?? base.lobes, widget.bandColors ?? base.band);
  }

  double _now() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  double _dt() {
    final n = _now();
    final dt = (n - _lastTick).clamp(0.0, 0.1);
    _lastTick = n;
    return dt;
  }

  @override
  void didUpdateWidget(covariant VoiceBeam old) {
    super.didUpdateWidget(old);
    _painter
      ..levelListenable = widget.levelListenable
      ..level = widget.level
      ..processing = widget.processing
      ..strength = widget.strength
      ..active = widget.active
      ..palette = _resolvePalette()
      ..geometry = _geometryFor(widget.type)
      ..theme = widget.theme
      ..scale = widget.scale
      ..borderRadius = widget.borderRadius
      ..processingDuration = widget.processingDuration;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _painter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceBeamPainter extends CustomPainter {
  _VoiceBeamPainter({
    required this.clock,
    required this.levelListenable,
    required this.level,
    required this.processing,
    required this.strength,
    required this.active,
    required this.palette,
    required this.geometry,
    required this.theme,
    required this.scale,
    required this.borderRadius,
    required this.processingDuration,
    required this.onTick,
  }) : super(repaint: clock);

  final Animation<double> clock;
  ValueListenable<double>? levelListenable;
  double level;
  bool processing;
  double strength;
  bool active;
  _Palette palette;
  _Geometry geometry;
  VoiceBeamTheme theme;
  double scale;
  double borderRadius;
  double processingDuration;
  double Function() onTick;

  double _smooth = 0;
  final List<double> _bands = [0, 0, 0];
  double _phase = 0;
  double _scanA = 0;
  double _scanT = 0;
  double _t = 0;

  // ── Paint cache ──────────────────────────────────────────────────────────
  // Softness comes from baked multi-stop gradient falloff, never
  // MaskFilter.blur. A masked draw is its own GPU pass, and this painter
  // issued one per lobe per layer (7 x 2), four blurred path strokes and a
  // blurred hotspot — nineteen passes a frame on top of the glass sheet's own
  // backdrop blur. That is what read as glitchy.
  //
  // Alpha is quantised into buckets so each (lobe, bucket) shader is built
  // once and reused; the per-frame cost is then a draw call and nothing else.
  static const int _alphaBuckets = 6;

  List<Color>? _cachedLobes;
  VoiceBeamTheme? _cachedTheme;
  double _cachedScale = -1;
  List<List<Paint>> _lobePaints = [];

  final Paint _crestPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Rebuilds the cached unit-radius lobe shaders when anything that affects
  /// their appearance changes. Quantised falloff: a hard-ish core, a soft
  /// mid, and a long tail to zero.
  void _ensureLobePaints(List<Color> lobes) {
    if (identical(_cachedLobes, lobes) &&
        _cachedTheme == theme &&
        _cachedScale == scale) {
      return;
    }
    _cachedLobes = lobes;
    _cachedTheme = theme;
    _cachedScale = scale;
    _lobePaints = [
      for (final c in lobes)
        List<Paint>.generate(_alphaBuckets, (b) {
          final a = (b + 1) / _alphaBuckets;
          final col = light ? _darken(c) : c;
          return Paint()
            ..shader = RadialGradient(
              colors: [
                col.withValues(alpha: a),
                col.withValues(alpha: a * 0.55),
                col.withValues(alpha: a * 0.16),
                col.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.35, 0.66, 1.0],
            ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
        }),
    ];
  }

  /// Light surfaces wash a pale lobe out entirely, so darken toward the
  /// surface for contrast rather than relying on the white core we drop.
  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness * 0.62).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 1.15).clamp(0.0, 1.0))
        .toColor();
  }

  bool get light => theme == VoiceBeamTheme.light;

  Paint _lobePaint(int lobe, double alpha) {
    final b = (alpha * _alphaBuckets).ceil() - 1;
    final idx = b < 0 ? 0 : (b > _alphaBuckets - 1 ? _alphaBuckets - 1 : b);
    return _lobePaints[lobe][idx];
  }

  double get _span => geometry.spanBase * geometry.lobeSpacing;

  double _wrap(double x) {
    final half = _span / 2;
    var r = (x + half) % _span;
    if (r < 0) r += _span;
    return r - half;
  }

  double _edgeEnv(double x) {
    final t = x / (_span / 2 + 4);
    return math.max(0, 1 - t * t);
  }

  double _shape(double raw) {
    if (raw <= _threshold) return 0;
    final t = (raw - _threshold) / math.max(0.001, 1 - _threshold);
    return ((1 - math.exp(-3 * t)) / (1 - math.exp(-3))).clamp(0.0, 1.0);
  }

  double _follow(double prev, double target, double dt) {
    final tau = target > prev ? _attack : _release;
    final a = 1 - math.exp(-dt / math.max(0.001, tau));
    return prev + (target - prev) * a;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!active || strength <= 0.01) return;
    final g = geometry;
    final dt = onTick();
    _t += dt;

    final raw =
        ((levelListenable?.value ?? level).clamp(0.0, 1.0) * _sensitivity)
            .clamp(0.0, 1.2);
    _smooth = _follow(_smooth, _shape(raw), dt);
    // Synthesised bands (original does this when driven by `level`).
    final bTargets = [
      _smooth,
      (_smooth * (0.72 + 0.28 * math.sin(_t * 9.1))).clamp(0.0, 1.0),
      (_smooth * (0.6 + 0.4 * math.sin(_t * 13.7 + 2))).clamp(0.0, 1.0),
    ];
    for (var b = 0; b < 3; b++) {
      _bands[b] = _follow(_bands[b], _shape(bTargets[b]), dt);
    }

    // Processing travel (ping-pong, power-eased turns, fresh starts centre).
    if (processing && _scanA < 0.001 && _scanT == 0) {
      _scanT = math.max(0.05, processingDuration) / 2;
    }
    _scanA = _follow(_scanA, processing ? 1 : 0, dt);
    if (processing) {
      _scanT += dt;
    } else if (_scanA < 0.001) {
      _scanT = 0;
    }
    final morph = _scanA * _scanA * (3 - 2 * _scanA);
    final passes = _scanT / math.max(0.05, processingDuration);
    final passIndex = passes.floor();
    final u = passes - passIndex;
    final eased = u < 0.5
        ? 0.5 * math.pow(2 * u, _procCurve)
        : 1 - 0.5 * math.pow(2 - 2 * u, _procCurve);
    final pass = passIndex % 2 == 0 ? 2 * eased - 1 : 1 - 2 * eased;
    final travel = (_span / 2) * _procTravel;
    final cxOff = morph * travel * pass;
    final gather = 1 - morph * 0.6;
    final maskW = 1 - morph * 0.45;
    final passW = 1 + morph * 0.3 * (1 - pass * pass);

    final breathe = 0.5 + 0.5 * math.sin(2 * math.pi * _t / g.breatheDur);
    final voiced = _smooth + (1 - _smooth) * g.idle * breathe;
    final heldT = ((morph - 0.25) / 0.75).clamp(0.0, 1.0);
    final held = heldT * heldT * (3 - 2 * heldT);
    final eff = math.max(voiced, _procLevel * held);

    final glow = 0.15 + 0.85 * eff;
    final h = 0.5 + g.reach * eff;
    final w = (0.85 + g.spread * eff) * passW;

    if (g.flow != 0) {
      _phase = ((_phase + g.flow * eff * dt) % _span + _span) % _span;
    }

    final sc = (size.width / g.refWidth).clamp(0.4, 3.0) * scale;
    final cx = size.width / 2;
    final baseY = size.height + 2 * sc;
    final lift = g.bend * sc * eff;
    // Light chrome loses the white core line and needs a darker crest to
    // stay visible; upstream tunes the band per theme.
    final light = theme == VoiceBeamTheme.light;
    final coreAlpha = light ? 0.30 : 0.38;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(borderRadius),
      ),
    );

    final lobes = palette.lobes;
    final n = math.min(7, lobes.length);
    _ensureLobePaints(lobes);

    // Ellipse mask the original applies per layer (stroke/inner and bloom,
    // centred on the travelling beam, growing with level).
    final maskCx = cx + cxOff * w * sc;
    double mask(double ew, double eh, double x, double y) {
      final dx = (x - maskCx) / math.max(1, ew * maskW);
      final dy = (y - baseY) / math.max(1, eh + lift);
      final d = dx * dx + dy * dy;
      if (d >= 1) return 0;
      return (1 - d) * (1 - d);
    }

void drawLobes({
      required double ew,
      required double eh,
      required double alpha,
      required double softness,
    }) {
      for (var i = 0; i < n; i++) {
        final wx = _wrap(g.lobeX[i] * g.lobeSpacing + _phase);
        final bandLift = 0.6 + 0.7 * _bands[g.lobeBand[i]];
        final env = _edgeEnv(wx);
        if (env <= 0.01) continue;
        final x = cx + (cxOff + wx * gather) * w * sc;
        // Softness widens the ellipse instead of blurring it, which is free.
        final lw =
            g.lobeW[i] * sc * g.glowW * (0.8 + bandLift * 0.3) * softness;
        final lh =
            g.lobeH[i] *
            sc *
            g.glowH *
            h *
            bandLift *
            (1 - morph * 0.3) *
            softness;
        // Centres sit ON the bottom edge; the gradient rises above it.
        // Processing lifts lobes along the corners.
        final y = baseY - lift * (g.lobeX[i].abs() / 140) * morph;
        final m = mask(ew * sc * w, eh * sc * h, x, y - lh * 0.2);
        final a = (alpha * env * (0.35 + 0.65 * m.clamp(0.0, 1.0)) * glow)
            .clamp(0.0, 1.0);
        if (a <= 0.01) continue;
        // Cached unit-radius shader: the canvas scale (lw, lh) sizes it, so
        // the falloff always spans the drawn ellipse.
        final paint = _lobePaint(i, a);
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(lw, lh);
        canvas.drawCircle(Offset.zero, 1, paint);
        canvas.restore();
      }
    }

    // Wide soft halo, then the tighter inner light on top.
    drawLobes(ew: g.bloomW, eh: g.bloomH, alpha: _bloomOp, softness: 1.55);
    drawLobes(
      ew: g.strokeW,
      eh: g.strokeH,
      alpha: _innerOp * 0.46 / 0.47,
      softness: 1.0,
    );

    // Band: bell on the bend ceiling + tail hooks + chromatic fringes.
    final band = palette.band;
    final bendA = g.bend > 0 ? (lift / (g.bend * sc)).clamp(0.0, 1.0) : 0;
    final bandAlpha =
        (1.55 * bendA * (0.25 + eff * 0.75) * strength).clamp(0.0, 1.0);
    if (bandAlpha > 0.02) {
      final spreadPx = size.width * 0.30 * (0.8 + eff * 0.4);
      // Ceiling the band sits on, capped at 82% of height; base sits 27px
      // below the edge.
      final apexCap = size.height * 0.82;
      final apex = math.min(apexCap, (g.strokeH * h + lift) * 0.35);
      final base = size.height + 27 * sc;
      final pts = <Offset>[];
      const steps = 48;
      for (var s = 0; s <= steps; s++) {
        final x = size.width * s / steps;
        final t = ((x - (cx + cxOff * w * sc)) / math.max(1, spreadPx))
            .clamp(-1.0, 1.0);
        // Normalised bell, skew 0.12.
        double bell(double tt) {
          final side = tt < 0 ? 0.88 : 1.12;
          final sg = math.max(0.05, 0.87 * side);
          final v = math.exp(-math.pow(tt.abs() / sg, 1.75));
          final tail = math.exp(-math.pow(1 / sg, 1.75));
          return math.max(0, (v - tail) / (1 - tail));
        }

        final edge = size.width / 2;
        final dist = (x - cx).abs();
        var tail = 0.0;
        if (dist > edge * 0.67) {
          final uu =
              ((dist - edge * 0.67) / math.max(1, edge * 0.33)).clamp(0.0, 1.0);
          tail = 0.59 * math.pow(uu, 2.4) * (1 - morph);
        }
        pts.add(Offset(x, base - apex * bell(t) - lift * 0.4 * tail));
      }

      // No MaskFilter anywhere: a soft line is faked with a few stacked
      // decreasing-alpha passes of the same path, which is a handful of cheap
      // stroke draws instead of one blur pass per line.
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var k = 1; k < pts.length; k++) {
        path.lineTo(pts[k].dx, pts[k].dy);
      }

      void stroke(List<Offset> pp, Color c, double sw) {
        final p = Path()..moveTo(pp[0].dx, pp[0].dy);
        for (var k = 1; k < pp.length; k++) {
          p.lineTo(pp[k].dx, pp[k].dy);
        }
        _crestPaint
          ..strokeWidth = sw * sc
          ..color = c;
        canvas.drawPath(p, _crestPaint);
      }

      void softStroke(List<Offset> pp, Color c, double sw) {
        stroke(pp, c.withValues(alpha: c.a * 0.22), sw * 2.6);
        stroke(pp, c.withValues(alpha: c.a * 0.34), sw * 1.7);
        stroke(pp, c, sw);
      }

      softStroke(pts, band.core.withValues(alpha: 0.34), 3.2);
      stroke(
        pts.map((e) => Offset(e.dx + 1.5 * sc, e.dy - 2 * sc)).toList(),
        band.above.withValues(alpha: 0.5),
        2.2,
      );
      stroke(
        pts.map((e) => Offset(e.dx - 1.5 * sc, e.dy + 2 * sc)).toList(),
        band.below.withValues(alpha: 0.5),
        2.2,
      );
      softStroke(
        pts,
        (light ? Colors.black : Colors.white).withValues(
          alpha: coreAlpha * bandAlpha,
        ),
        1.7,
      );
    }

    // Core hotspot — gradient falloff only.
    final coreX = cx + cxOff * w * sc;
    final coreR = 30 * sc * (0.5 + eff);
    final hotspot = light ? Colors.black : Colors.white;
    canvas.drawCircle(
      Offset(coreX, baseY - 2 * sc),
      coreR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            hotspot.withValues(alpha: 0.35 * bandAlpha + 0.1),
            hotspot.withValues(alpha: 0.35 * bandAlpha + 0.1),
            hotspot.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(coreX, baseY - 2 * sc), radius: coreR),
        ),
    );

    // Edge stroke with palette + bright centre, fading with the glow.
    final sA = (glow * strength).clamp(0.0, 1.0);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        colors: [
          lobes[5].withValues(alpha: 0.0),
          lobes[3].withValues(alpha: 0.9 * sA),
          lobes[1].withValues(alpha: 0.9 * sA),
          (light ? Colors.black : Colors.white).withValues(alpha: 0.95 * sA),
          lobes[2].withValues(alpha: 0.9 * sA),
          lobes[4].withValues(alpha: 0.9 * sA),
          lobes[6].withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.35, 0.5, 0.65, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, size.height - 3, size.width, 3));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, size.height - 2.5, size.width - 1.5, 2),
        const Radius.circular(2),
      ),
      strokePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VoiceBeamPainter old) => false;
}
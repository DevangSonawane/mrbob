import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// Which promo a banner page shows.
enum HeroBannerKind { services, inspection, amc }

/// Swiggy-style full-header promo carousel for the home screen.
///
/// Each banner owns the whole header background (behind the location and
/// search controls); its own art and copy live in the band below
/// [contentTop]. Pages loop horizontally, the services banner flips through
/// categories with a colour crossfade, and [colorNotifier] reports the live
/// header colour (interpolated while swiping) so the status-bar strip can
/// follow it.
///
/// Motion budget: one shared 8s clock for all ambient motion (floating
/// tokens, rays, radar), one-shot entrance per page, timers for rotation.
/// Everything pauses when [contentOpacity] hits 0 (header collapsed), and
/// reduced motion holds still frames with no auto-advance.
class HomeHeroBanners extends StatefulWidget {
  const HomeHeroBanners({
    super.key,
    required this.scale,
    required this.horizontalInset,
    required this.height,
    required this.contentTop,
    required this.parallax,
    required this.scrollOffset,
    required this.contentOpacity,
    required this.brandColor,
    this.colorNotifier,
    this.onCta,
  });

  final double scale;
  final double horizontalInset;

  /// Full (expanded) header height the banners are laid out at.
  final double height;

  /// Where the banner band starts (below location + search).
  final double contentTop;

  /// Vertical offset applied to the backgrounds while the header collapses
  /// (they drift slower than the scroll).
  final double parallax;

  /// How far the header has collapsed. Banner copy, art and page dots move
  /// 1:1 with it, so they slide up under the pinned search bar instead of
  /// vanishing.
  final double scrollOffset;

  /// 1 = banner copy fully visible, 0 = hidden (and motion paused).
  final double contentOpacity;

  final Color brandColor;
  final ValueNotifier<Color>? colorNotifier;
  final ValueChanged<HeroBannerKind>? onCta;

  @override
  State<HomeHeroBanners> createState() => _HomeHeroBannersState();
}

class _HomeHeroBannersState extends State<HomeHeroBanners> {
  late final ValueNotifier<double> _opacity = ValueNotifier(
    widget.contentOpacity,
  );
  late final ValueNotifier<double> _shift = ValueNotifier(_contentShift);

  /// Extra lift on top of [HomeHeroBanners.parallax] so content tracks the
  /// scroll exactly.
  double get _contentShift => -widget.scrollOffset - widget.parallax;

  /// The pager is cached so per-frame collapse rebuilds of this widget
  /// (one per scroll frame) only move a transform instead of rebuilding
  /// every banner.
  Widget? _pager;

  @override
  void didUpdateWidget(covariant HomeHeroBanners oldWidget) {
    super.didUpdateWidget(oldWidget);
    _opacity.value = widget.contentOpacity;
    _shift.value = _contentShift;
    if (oldWidget.scale != widget.scale ||
        oldWidget.horizontalInset != widget.horizontalInset ||
        oldWidget.height != widget.height ||
        oldWidget.contentTop != widget.contentTop ||
        oldWidget.brandColor != widget.brandColor ||
        oldWidget.colorNotifier != widget.colorNotifier) {
      _pager = null;
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _shift.dispose();
    super.dispose();
  }

  void _handleCta(HeroBannerKind kind) => widget.onCta?.call(kind);

  @override
  Widget build(BuildContext context) {
    _pager ??= _BannerPager(
      scale: widget.scale,
      inset: widget.horizontalInset,
      height: widget.height,
      contentTop: widget.contentTop,
      brandColor: widget.brandColor,
      opacity: _opacity,
      shift: _shift,
      colorNotifier: widget.colorNotifier,
      onCta: _handleCta,
    );
    return Transform.translate(
      offset: Offset(0, widget.parallax),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: widget.height,
        maxHeight: widget.height,
        child: _pager,
      ),
    );
  }
}

class _ServiceTheme {
  const _ServiceTheme(this.tag, this.color, this.icons);

  final String tag;
  final Color color;
  final List<IconData> icons;
}

const _serviceThemes = [
  _ServiceTheme('PLUMBING', Color(0xFF0B7480), [
    LucideIcons.droplets,
    LucideIcons.wrench,
    LucideIcons.showerHead,
    LucideIcons.droplet,
  ]),
  _ServiceTheme('ELECTRICAL', Color(0xFF1D4FC4), [
    LucideIcons.zap,
    LucideIcons.plug,
    LucideIcons.lightbulb,
    LucideIcons.cable,
  ]),
  _ServiceTheme('PAINTING', Color(0xFF7438C2), [
    LucideIcons.paintRoller,
    LucideIcons.paintbrush,
    LucideIcons.palette,
    LucideIcons.sparkles,
  ]),
  _ServiceTheme('CARPENTRY', Color(0xFF9C5317), [
    LucideIcons.hammer,
    LucideIcons.ruler,
    LucideIcons.drill,
    LucideIcons.nut,
  ]),
];

const _amcColor = Color(0xFFD62D45);
const _ink = Color(0xFF111614);

/// Everything a banner page needs from the pager.
class _BannerCtx {
  const _BannerCtx({
    required this.scale,
    required this.inset,
    required this.contentTop,
    required this.float,
    required this.enter,
    required this.opacity,
    required this.shift,
    required this.reduceMotion,
    required this.onCta,
  });

  final double scale;
  final double inset;
  final double contentTop;

  /// Shared ambient clock, 0 → 1 every 8s.
  final Animation<double> float;

  /// One-shot entrance for this page, 0 → 1.
  final Animation<double> enter;
  final ValueListenable<double> opacity;
  final ValueListenable<double> shift;
  final bool reduceMotion;
  final ValueChanged<HeroBannerKind> onCta;
}

class _BannerPager extends StatefulWidget {
  const _BannerPager({
    required this.scale,
    required this.inset,
    required this.height,
    required this.contentTop,
    required this.brandColor,
    required this.opacity,
    required this.shift,
    required this.colorNotifier,
    required this.onCta,
  });

  final double scale;
  final double inset;
  final double height;
  final double contentTop;
  final Color brandColor;
  final ValueListenable<double> opacity;
  final ValueListenable<double> shift;
  final ValueNotifier<Color>? colorNotifier;
  final ValueChanged<HeroBannerKind> onCta;

  @override
  State<_BannerPager> createState() => _BannerPagerState();
}

class _BannerPagerState extends State<_BannerPager>
    with TickerProviderStateMixin {
  // Large initial page so the carousel loops in both directions.
  static const _loopBase = 3000;

  late final PageController _pages;
  late final AnimationController _float;
  late final AnimationController _enter;
  late final AnimationController _themeFade;
  late final Timer _themeTicker;
  Timer? _advance;

  var _active = _loopBase;
  int? _previous;
  var _theme = 0;
  var _prevTheme = 0;
  var _reduceMotion = false;
  var _wasPaused = false;
  var _started = false;

  bool get _paused => widget.opacity.value == 0;

  HeroBannerKind _kindOf(int page) =>
      HeroBannerKind.values[page % HeroBannerKind.values.length];

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _loopBase)..addListener(_publishColor);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _themeFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    )..addListener(_publishColor);
    _themeTicker = Timer.periodic(
      const Duration(milliseconds: 1700),
      (_) => _nextTheme(),
    );
    widget.opacity.addListener(_onOpacity);
    _wasPaused = _paused;
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishColor());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!_started) {
      _started = true;
      if (_reduceMotion) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    }
    _syncMotion();
  }

  @override
  void dispose() {
    widget.opacity.removeListener(_onOpacity);
    _themeTicker.cancel();
    _advance?.cancel();
    _pages.dispose();
    _float.dispose();
    _enter.dispose();
    _themeFade.dispose();
    super.dispose();
  }

  void _onOpacity() {
    if (_paused == _wasPaused) return;
    _wasPaused = _paused;
    _syncMotion();
  }

  void _syncMotion() {
    if (_paused) {
      _float.stop();
      _advance?.cancel();
      return;
    }
    if (_reduceMotion) {
      // A composed still frame, and no self-driven paging.
      _float.value = 0.42;
      _advance?.cancel();
      return;
    }
    if (!_float.isAnimating) _float.repeat();
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    _advance?.cancel();
    if (_paused || _reduceMotion) return;
    final dwell = _kindOf(_active) == HeroBannerKind.services
        ? const Duration(milliseconds: 5400)
        : const Duration(milliseconds: 4200);
    _advance = Timer(dwell, () {
      if (!mounted || !_pages.hasClients) return;
      // Never yank the page out from under a finger.
      if (_pages.position.userScrollDirection != ScrollDirection.idle) {
        _scheduleAdvance();
        return;
      }
      _pages.nextPage(
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _nextTheme() {
    if (!mounted || _paused) return;
    if (_kindOf(_active) != HeroBannerKind.services) return;
    setState(() {
      _prevTheme = _theme;
      _theme = (_theme + 1) % _serviceThemes.length;
    });
    _themeFade.forward(from: 0);
  }

  void _onPageChanged(int page) {
    setState(() {
      _previous = _active;
      _active = page;
    });
    if (!_reduceMotion) _enter.forward(from: 0);
    _scheduleAdvance();
  }

  Color _colorOf(HeroBannerKind kind) => switch (kind) {
    HeroBannerKind.services => Color.lerp(
      _serviceThemes[_prevTheme].color,
      _serviceThemes[_theme].color,
      Curves.easeInOut.transform(_themeFade.value),
    )!,
    HeroBannerKind.inspection => widget.brandColor,
    HeroBannerKind.amc => _amcColor,
  };

  void _publishColor() {
    final notifier = widget.colorNotifier;
    if (notifier == null || !mounted) return;
    final page = _pages.hasClients && _pages.position.haveDimensions
        ? (_pages.page ?? _active.toDouble())
        : _active.toDouble();
    final base = page.floor();
    notifier.value = Color.lerp(
      _colorOf(_kindOf(base)),
      _colorOf(_kindOf(base + 1)),
      page - base,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pages,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, page) {
            final Animation<double> enter;
            if (_reduceMotion || page == _previous) {
              enter = kAlwaysCompleteAnimation;
            } else if (page == _active) {
              enter = _enter;
            } else {
              enter = kAlwaysDismissedAnimation;
            }
            final ctx = _BannerCtx(
              scale: widget.scale,
              inset: widget.inset,
              contentTop: widget.contentTop,
              float: _float,
              enter: enter,
              opacity: widget.opacity,
              shift: widget.shift,
              reduceMotion: _reduceMotion,
              onCta: widget.onCta,
            );
            return switch (_kindOf(page)) {
              HeroBannerKind.services => _ServicesBanner(
                ctx: ctx,
                theme: _theme,
                prevTheme: _prevTheme,
                themeFade: _themeFade,
              ),
              HeroBannerKind.inspection => _InspectionBanner(
                ctx: ctx,
                brandColor: widget.brandColor,
              ),
              HeroBannerKind.amc => _AmcBanner(ctx: ctx),
            };
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12 * widget.scale,
          child: IgnorePointer(
            child: _FadeWithCollapse(
              opacity: widget.opacity,
              shift: widget.shift,
              child: _PageDots(
                count: HeroBannerKind.values.length,
                active: _active % HeroBannerKind.values.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Moves banner copy up with the header collapse (under the search bar)
/// and fades it at the very end, without rebuilding it.
class _FadeWithCollapse extends StatelessWidget {
  const _FadeWithCollapse({
    required this.opacity,
    required this.shift,
    required this.child,
  });

  final ValueListenable<double> opacity;
  final ValueListenable<double> shift;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([opacity, shift]),
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, shift.value),
        child: Opacity(
          opacity: opacity.value,
          child: IgnorePointer(ignoring: opacity.value < 0.5, child: child),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == active ? 16 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == active ? 0.95 : 0.45),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Shared banner skeleton: full-bleed [background] plus the copy/art band
/// below the header controls.
class _BannerShell extends StatelessWidget {
  const _BannerShell({
    required this.ctx,
    required this.background,
    required this.band,
    required this.semanticLabel,
  });

  final _BannerCtx ctx;
  final Widget background;
  final Widget band;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: background),
        Positioned(
          left: 0,
          right: 0,
          top: ctx.contentTop,
          bottom: 22 * ctx.scale,
          child: Semantics(
            container: true,
            label: semanticLabel,
            child: _FadeWithCollapse(
              opacity: ctx.opacity,
              shift: ctx.shift,
              child: band,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Banner 1: services — category tag flips, colour crossfades, tokens pop.
// ---------------------------------------------------------------------------

class _ServicesBanner extends StatelessWidget {
  const _ServicesBanner({
    required this.ctx,
    required this.theme,
    required this.prevTheme,
    required this.themeFade,
  });

  final _BannerCtx ctx;
  final int theme;
  final int prevTheme;
  final Animation<double> themeFade;

  static const _slots = [
    (0.12, 0.22, -0.26),
    (0.87, 0.16, 0.22),
    (0.11, 0.80, 0.18),
    (0.88, 0.76, -0.2),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = ctx.scale;
    final current = _serviceThemes[theme];
    return _BannerShell(
      ctx: ctx,
      semanticLabel:
          'Plumbing, electrical, painting and carpentry experts. Book now.',
      background: AnimatedBuilder(
        animation: themeFade,
        builder: (context, child) => ColoredBox(
          color: Color.lerp(
            _serviceThemes[prevTheme].color,
            current.color,
            Curves.easeInOut.transform(themeFade.value),
          )!,
          child: child,
        ),
        child: CustomPaint(
          painter: _RingsPainter(
            clock: ctx.float,
            centerY: ctx.contentTop,
            scale: scale,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      band: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _slots.length; i++)
              Positioned(
                left: box.maxWidth * _slots[i].$1 - 25 * scale,
                top: box.maxHeight * _slots[i].$2 - 25 * scale,
                child: _EnterPop(
                  enter: ctx.enter,
                  interval: Interval(
                    0.12 * i,
                    0.55 + 0.12 * i,
                    curve: Curves.easeOutBack,
                  ),
                  child: _Floating(
                    clock: ctx.float,
                    phase: i / _slots.length,
                    amplitude: 5 * scale,
                    tilt: _slots[i].$3,
                    child: AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: ctx.reduceMotion ? 160 : 520,
                      ),
                      reverseDuration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        if (ctx.reduceMotion) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }
                        return ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                            reverseCurve: Curves.easeInCubic,
                          ),
                          child: RotationTransition(
                            turns: Tween(begin: -0.12, end: 0.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: _ToolToken(
                        key: ValueKey('$theme-$i'),
                        icon: current.icons[i],
                        color: current.color,
                        size: 50 * scale,
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EnterPop(
                    enter: ctx.enter,
                    interval: const Interval(0, 0.5, curve: Curves.easeOutBack),
                    child: _TagPill(
                      scale: scale,
                      child: _FlipSwitcher(
                        reduceMotion: ctx.reduceMotion,
                        child: Text(
                          current.tag,
                          key: ValueKey(theme),
                          style: _TagPill.textStyle(scale),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  _EnterPop(
                    enter: ctx.enter,
                    from: 0.82,
                    interval: const Interval(
                      0.08,
                      0.7,
                      curve: Curves.easeOutBack,
                    ),
                    child: _StickerText('experts', fontSize: 54 * scale),
                  ),
                  SizedBox(height: 10 * scale),
                  _EnterRise(
                    enter: ctx.enter,
                    interval: const Interval(0.3, 0.9),
                    child: _BannerCta(
                      label: 'Book now',
                      scale: scale,
                      onTap: () => ctx.onCta(HeroBannerKind.services),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Concentric rings that slowly breathe behind the services copy.
class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.clock,
    required this.centerY,
    required this.scale,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final double centerY;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      centerY + (size.height - centerY) / 2,
    );
    // Soft highlight behind the title.
    canvas.drawCircle(
      center,
      size.width * 0.55,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: size.width * 0.55),
            ),
    );
    final breathe = math.sin(clock.value * 2 * math.pi) * 6 * scale;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * scale
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(center, 112 * scale + breathe, ring);
    canvas.drawCircle(center, 170 * scale - breathe, ring);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.clock != clock ||
      oldDelegate.centerY != centerY ||
      oldDelegate.scale != scale;
}

// ---------------------------------------------------------------------------
// Banner 2: post-handover deep inspection — a checklist card ticks off each
// area under a scanning magnifier, then an "ALL CHECKED" stamp slams down.
// ---------------------------------------------------------------------------

class _InspectionBanner extends StatelessWidget {
  const _InspectionBanner({required this.ctx, required this.brandColor});

  final _BannerCtx ctx;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final scale = ctx.scale;
    return _BannerShell(
      ctx: ctx,
      semanticLabel:
          'New home? Post-handover deep inspection, snag-free. Book inspection.',
      background: CustomPaint(
        painter: _BlueprintPainter(
          brand: brandColor,
          centerY: ctx.contentTop,
          scale: scale,
        ),
        child: const SizedBox.expand(),
      ),
      band: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: ctx.inset,
            top: 8 * scale,
            child: _EnterPop(
              enter: ctx.enter,
              from: 0.7,
              interval: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
              child: _Floating(
                clock: ctx.float,
                phase: 0.25,
                amplitude: 4 * scale,
                tilt: 0.07,
                sway: 0.025,
                child: _ChecklistCard(clock: ctx.float, scale: scale),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(ctx.inset, 16 * scale, ctx.inset, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EnterSlide(
                  enter: ctx.enter,
                  interval: const Interval(0, 0.5, curve: Curves.easeOutCubic),
                  dx: -28 * scale,
                  child: _TagPill(
                    scale: scale,
                    child: Text('NEW HOME?', style: _TagPill.textStyle(scale)),
                  ),
                ),
                SizedBox(height: 4 * scale),
                _EnterSlide(
                  enter: ctx.enter,
                  interval: const Interval(
                    0.1,
                    0.65,
                    curve: Curves.easeOutBack,
                  ),
                  dx: -40 * scale,
                  skew: true,
                  child: _StickerText('snag-free', fontSize: 40 * scale),
                ),
                SizedBox(height: 6 * scale),
                _EnterRise(
                  enter: ctx.enter,
                  interval: const Interval(0.2, 0.8),
                  child: Text(
                    'Post-handover\ndeep inspection',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(height: 10 * scale),
                _EnterRise(
                  enter: ctx.enter,
                  interval: const Interval(0.3, 0.9),
                  child: _BannerCta(
                    label: 'Book inspection',
                    scale: scale,
                    onTap: () => ctx.onCta(HeroBannerKind.inspection),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inspection report card on the shared clock (8s loop):
/// 0.06–0.62 rows tick one by one under the magnifier, 0.68 the stamp slams
/// down, 0.92–1.0 everything clears for the next loop.
class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.clock, required this.scale});

  final Animation<double> clock;
  final double scale;

  static const _rows = [
    'Walls & plaster',
    'Plumbing & leaks',
    'Wiring & switches',
    'Doors & fittings',
  ];

  static const _green = Color(0xFF17A35B);

  /// 0 → 1 tick progress for [row] at clock [t].
  static double _tick(double t, int row) {
    final start = 0.06 + row * 0.14;
    return ((t - start) / 0.08).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final width = 158 * scale;
    final rowHeight = 25 * scale;
    final headerHeight = 30 * scale;
    final pad = 10 * scale;
    return SizedBox(
      width: width,
      height: headerHeight + rowHeight * _rows.length + pad * 1.4,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t = clock.value;
          // Loop reset: fade ticks + stamp out at the end of the cycle.
          final clear = 1 - ((t - 0.92) / 0.08).clamp(0.0, 1.0);
          // Magnifier glides row to row, then lifts off before the stamp.
          final scan = ((t - 0.02) / 0.58).clamp(0.0, 1.0) * (_rows.length - 1);
          final scanOut = ((t - 0.62) / 0.08).clamp(0.0, 1.0);
          final stampIn = ((t - 0.68) / 0.07).clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14 * scale),
                  border: Border.all(color: _ink, width: 2),
                  boxShadow: const [
                    BoxShadow(color: _ink, offset: Offset(4, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: headerHeight,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12 * scale),
                        ),
                        border: const Border(
                          bottom: BorderSide(color: _ink, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.clipboardCheck,
                            size: 14 * scale,
                            color: _ink,
                          ),
                          SizedBox(width: 5 * scale),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'INSPECTION',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 11 * scale,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: pad * 0.4),
                    for (var i = 0; i < _rows.length; i++)
                      SizedBox(
                        height: rowHeight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          child: Row(
                            children: [
                              _CheckDot(
                                progress: _tick(t, i) * clear,
                                size: 16 * scale,
                                color: _green,
                              ),
                              SizedBox(width: 7 * scale),
                              Expanded(
                                child: Text(
                                  _rows[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color.lerp(
                                      const Color(0xFF6B726B),
                                      _ink,
                                      _tick(t, i) * clear,
                                    ),
                                    fontSize: 10.5 * scale,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Scanning magnifier.
              Positioned(
                right: -16 * scale,
                top:
                    headerHeight +
                    pad * 0.4 +
                    scan * rowHeight -
                    6 * scale -
                    scanOut * 30 * scale,
                child: Opacity(
                  opacity: (1 - scanOut) * clear,
                  child: Container(
                    width: 34 * scale,
                    height: 34 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _ink, width: 2),
                      boxShadow: const [
                        BoxShadow(color: _ink, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.search,
                      size: 17 * scale,
                      color: _ink,
                    ),
                  ),
                ),
              ),
              // Stamp: slams from oversized to rest, then clears with the loop.
              if (stampIn > 0 && clear > 0)
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: stampIn * clear,
                      child: Transform.rotate(
                        angle: -0.22,
                        child: Transform.scale(
                          scale:
                              1 +
                              0.8 * (1 - Curves.easeOutBack.transform(stampIn)),
                          child: Container(
                            margin: EdgeInsets.only(top: headerHeight * 0.6),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 3 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6 * scale),
                              border: Border.all(color: _green, width: 2.4),
                            ),
                            child: Text(
                              'ALL CHECKED',
                              style: TextStyle(
                                color: _green,
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Empty ring that pops into a filled check as [progress] goes 0 → 1.
class _CheckDot extends StatelessWidget {
  const _CheckDot({
    required this.progress,
    required this.size,
    required this.color,
  });

  final double progress;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pop = Curves.easeOutBack.transform(progress);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC9D2CF), width: 1.5),
            ),
          ),
          if (progress > 0)
            Transform.scale(
              scale: pop,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Icon(
                  LucideIcons.check,
                  size: size * 0.7,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Static blueprint backdrop: brand gradient, drafting grid and a faint
/// floor-plan outline — the "inspection" canvas. Painted once.
class _BlueprintPainter extends CustomPainter {
  _BlueprintPainter({
    required this.brand,
    required this.centerY,
    required this.scale,
  });

  final Color brand;
  final double centerY;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brand, const Color(0xFF024852), const Color(0xFF013840)],
        ).createShader(rect),
    );

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final step = 24 * scale;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Floor plan: outer walls, two partitions and a door swing.
    final plan = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;
    final room = Rect.fromLTWH(
      size.width * 0.04,
      centerY + 112 * scale,
      size.width * 0.5,
      (size.height - centerY) - 120 * scale,
    );
    canvas.drawRect(room, plan);
    canvas.drawLine(
      Offset(room.left + room.width * 0.45, room.top),
      Offset(room.left + room.width * 0.45, room.bottom - 18 * scale),
      plan,
    );
    canvas.drawLine(
      Offset(room.left + room.width * 0.45, room.top + room.height * 0.5),
      Offset(room.right, room.top + room.height * 0.5),
      plan,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(room.left + room.width * 0.45, room.bottom),
        radius: 18 * scale,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      plan,
    );

    // Glow behind the checklist card.
    final glowCenter = Offset(size.width * 0.74, centerY + 90 * scale);
    canvas.drawCircle(
      glowCenter,
      150 * scale,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF13A3A8).withValues(alpha: 0.35),
                const Color(0xFF13A3A8).withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: glowCenter, radius: 150 * scale),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _BlueprintPainter oldDelegate) =>
      oldDelegate.brand != brand ||
      oldDelegate.centerY != centerY ||
      oldDelegate.scale != scale;
}

// ---------------------------------------------------------------------------
// Banner 3: AMC plans — rotating starburst, tumbling confetti tokens.
// ---------------------------------------------------------------------------

class _AmcBanner extends StatelessWidget {
  const _AmcBanner({required this.ctx});

  final _BannerCtx ctx;

  static const _confetti = [
    (0.10, 0.18, LucideIcons.shieldCheck),
    (0.89, 0.12, LucideIcons.calendarCheck),
    (0.06, 0.66, LucideIcons.sparkles),
    (0.93, 0.60, LucideIcons.badgeCheck),
    (0.80, 0.94, LucideIcons.wrench),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = ctx.scale;
    return _BannerShell(
      ctx: ctx,
      semanticLabel: 'Introducing AMC plans, all-year care. Explore now.',
      background: ColoredBox(
        color: _amcColor,
        child: CustomPaint(
          painter: _StarburstPainter(
            clock: ctx.float,
            centerY: ctx.contentTop,
            scale: scale,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      band: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _confetti.length; i++)
              Positioned(
                left: box.maxWidth * _confetti[i].$1 - 17 * scale,
                top: box.maxHeight * _confetti[i].$2 - 17 * scale,
                child: _EnterPop(
                  enter: ctx.enter,
                  interval: Interval(
                    0.1 * i,
                    0.5 + 0.1 * i,
                    curve: Curves.easeOutBack,
                  ),
                  child: _Floating(
                    clock: ctx.float,
                    phase: i / _confetti.length,
                    amplitude: 6 * scale,
                    tilt: i.isEven ? -0.35 : 0.35,
                    sway: 0.35,
                    child: _ConfettiTicket(
                      icon: _confetti[i].$3,
                      size: 34 * scale,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EnterRise(
                    enter: ctx.enter,
                    interval: const Interval(0, 0.4),
                    dy: -10 * scale,
                    child: Text(
                      'INTRODUCING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  _EnterPop(
                    enter: ctx.enter,
                    interval: const Interval(
                      0.08,
                      0.55,
                      curve: Curves.easeOutBack,
                    ),
                    child: _TagPill(
                      scale: scale,
                      color: const Color(0xFFFFB3E0),
                      child: Text(
                        'AMC PLANS',
                        style: _TagPill.textStyle(scale),
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  _EnterSlide(
                    enter: ctx.enter,
                    interval: const Interval(
                      0.15,
                      0.75,
                      curve: Curves.easeOutBack,
                    ),
                    dx: 56 * scale,
                    skew: true,
                    child: _StickerText(
                      'all-year care',
                      fontSize: 42 * scale,
                      italic: true,
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  _EnterRise(
                    enter: ctx.enter,
                    interval: const Interval(0.35, 0.95),
                    child: _BannerCta(
                      label: 'Explore now',
                      scale: scale,
                      onTap: () => ctx.onCta(HeroBannerKind.amc),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slowly rotating comic starburst behind the AMC copy. One ray spacing
/// per clock loop, so the rotation is seamless.
class _StarburstPainter extends CustomPainter {
  _StarburstPainter({
    required this.clock,
    required this.centerY,
    required this.scale,
  }) : super(repaint: clock);

  final Animation<double> clock;
  final double centerY;
  final double scale;

  static const _rays = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      centerY + (size.height - centerY) / 2,
    );
    final radius = size.longestSide * 1.2;
    final spacing = 2 * math.pi / _rays;
    final rotation = clock.value * spacing;
    final ray = Paint()..color = Colors.white.withValues(alpha: 0.09);
    for (var k = 0; k < _rays; k++) {
      final a0 = rotation + k * spacing;
      final a1 = a0 + spacing / 2;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + radius * math.cos(a0),
            center.dy + radius * math.sin(a0),
          )
          ..lineTo(
            center.dx + radius * math.cos(a1),
            center.dy + radius * math.sin(a1),
          )
          ..close(),
        ray,
      );
    }
    // Bright core so the title pops.
    canvas.drawCircle(
      center,
      150 * scale,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6B6B).withValues(alpha: 0.55),
            const Color(0xFFFF6B6B).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 150 * scale)),
    );
  }

  @override
  bool shouldRepaint(covariant _StarburstPainter oldDelegate) =>
      oldDelegate.clock != clock ||
      oldDelegate.centerY != centerY ||
      oldDelegate.scale != scale;
}

// ---------------------------------------------------------------------------
// Shared pieces.
// ---------------------------------------------------------------------------

/// Bold white display text with a thick ink outline and hard drop shadow —
/// the sticker look from the reference banners.
class _StickerText extends StatelessWidget {
  const _StickerText(this.text, {required this.fontSize, this.italic = false});

  final String text;
  final double fontSize;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: -fontSize * 0.04,
      height: 1.0,
    );
    return Stack(
      children: [
        Text(
          text,
          maxLines: 1,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.15
              ..strokeJoin = StrokeJoin.round
              ..color = _ink,
            shadows: [
              Shadow(
                color: _ink.withValues(alpha: 0.55),
                offset: Offset(0, fontSize * 0.07),
              ),
            ],
          ),
        ),
        Text(text, maxLines: 1, style: base.copyWith(color: Colors.white)),
      ],
    );
  }
}

/// Slightly tilted sticker label with a hard offset shadow.
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.scale,
    required this.child,
    this.color = AppColors.brandGold,
  });

  final double scale;
  final Widget child;
  final Color color;

  static TextStyle textStyle(double scale) => TextStyle(
    color: _ink,
    fontSize: 17 * scale,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.4,
    height: 1.1,
  );

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.045,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7 * scale),
            border: Border.all(color: _ink, width: 2),
            boxShadow: const [BoxShadow(color: _ink, offset: Offset(3, 3))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Swaps its child with a 3D roll over the X axis: the old word tips away,
/// the new one rolls in from the top.
class _FlipSwitcher extends StatelessWidget {
  const _FlipSwitcher({required this.child, required this.reduceMotion});

  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: reduceMotion ? 160 : 460),
      reverseDuration: Duration(milliseconds: reduceMotion ? 160 : 200),
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.center, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        final incoming = child.key == this.child.key;
        final curved = CurvedAnimation(
          parent: animation,
          curve: incoming
              ? const Interval(0.35, 1, curve: Curves.easeOutBack)
              : Curves.easeIn,
        );
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            final v = curved.value;
            final angle = (1 - v) * (incoming ? -math.pi / 2 : math.pi / 2);
            return Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.003)
                  ..rotateX(angle),
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}

/// Glossy chip with a tool icon — stands in for the reference's 3D props.
class _ToolToken extends StatelessWidget {
  const _ToolToken({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFDCE6E8)],
        ),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Small gold ticket used as tumbling confetti on the AMC banner.
class _ConfettiTicket extends StatelessWidget {
  const _ConfettiTicket({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.78,
      decoration: BoxDecoration(
        color: AppColors.brandGold,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: _ink, width: 1.5),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(2, 2))],
      ),
      child: Icon(icon, size: size * 0.46, color: _ink),
    );
  }
}

class _BannerCta extends StatelessWidget {
  const _BannerCta({
    required this.label,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ink,
      shape: StadiumBorder(
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            7 * scale,
            10 * scale,
            7 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2 * scale),
              Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 16 * scale,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gentle bob + sway on the shared clock (two bobs per loop).
class _Floating extends StatelessWidget {
  const _Floating({
    required this.clock,
    required this.phase,
    required this.amplitude,
    required this.child,
    this.tilt = 0,
    this.sway = 0.07,
  });

  final Animation<double> clock;
  final double phase;
  final double amplitude;
  final double tilt;
  final double sway;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final a = (clock.value * 2 + phase) * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(a) * amplitude),
          child: Transform.rotate(
            angle: tilt + math.cos(a) * sway,
            child: child,
          ),
        );
      },
    );
  }
}

/// Entrance: scale up (with the interval's curve, e.g. a spring overshoot)
/// and fade in.
class _EnterPop extends StatelessWidget {
  const _EnterPop({
    required this.enter,
    required this.interval,
    required this.child,
    this.from = 0.0,
  });

  final Animation<double> enter;
  final Curve interval;
  final double from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: enter, curve: interval);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final v = curved.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: from + (1 - from) * v, child: child),
        );
      },
    );
  }
}

/// Entrance: slide in horizontally (optionally with a settling skew).
class _EnterSlide extends StatelessWidget {
  const _EnterSlide({
    required this.enter,
    required this.interval,
    required this.dx,
    required this.child,
    this.skew = false,
  });

  final Animation<double> enter;
  final Curve interval;
  final double dx;
  final bool skew;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: enter, curve: interval);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final v = curved.value;
        final rest = 1 - v;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(dx * rest, 0, 0)
              ..multiply(Matrix4.skewX(skew ? -0.35 * rest : 0)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Entrance: rise into place and fade in.
class _EnterRise extends StatelessWidget {
  const _EnterRise({
    required this.enter,
    required this.interval,
    required this.child,
    this.dy = 10,
  });

  final Animation<double> enter;
  final Interval interval;
  final double dy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: enter,
      curve: Interval(interval.begin, interval.end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, dy * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Swiggy-style search hint: `Search "plumber"` with the quoted term rolling
/// up to the next one every few seconds. Fixed-height, clipped line so the
/// field never shifts.
class RotatingSearchHint extends StatefulWidget {
  const RotatingSearchHint({
    super.key,
    required this.terms,
    required this.style,
  });

  final List<String> terms;
  final TextStyle style;

  @override
  State<RotatingSearchHint> createState() => _RotatingSearchHintState();
}

class _RotatingSearchHintState extends State<RotatingSearchHint> {
  late final Timer _ticker;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _index = (_index + 1) % widget.terms.length);
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final key = ValueKey(_index);
    return ClipRect(
      child: Row(
        children: [
          Text('Search ', style: widget.style),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: reduceMotion ? 150 : 480),
              reverseDuration: Duration(milliseconds: reduceMotion ? 150 : 300),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                if (reduceMotion) {
                  return FadeTransition(opacity: animation, child: child);
                }
                final incoming = child.key == key;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: Offset(0, incoming ? 1 : -1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: incoming
                                ? Curves.easeOutCubic
                                : Curves.easeInCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: Text(
                '"${widget.terms[_index]}"',
                key: key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: widget.style,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

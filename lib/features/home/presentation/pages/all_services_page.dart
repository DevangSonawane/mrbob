import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/service_visuals.dart';

const _brandTeal = Color(0xFF035864);
const _pageBg = Color(0xFFF6F5F1);

enum _Filter { all, instant, scheduled }

/// Every service category: a collapsing teal header, instant/scheduled
/// filter chips, an inspection promo and a two-column grid of photo cards.
class AllServicesPage extends StatefulWidget {
  const AllServicesPage({
    super.key,
    required this.services,
    required this.onServiceSelected,
  });

  final List<ServiceItem> services;
  final Future<void> Function(BuildContext context, ServiceItem service)
  onServiceSelected;

  @override
  State<AllServicesPage> createState() => _AllServicesPageState();
}

class _AllServicesPageState extends State<AllServicesPage> {
  _Filter _filter = _Filter.all;

  List<ServiceItem> _where(_Filter filter) => switch (filter) {
    _Filter.all => widget.services,
    _Filter.instant => widget.services.where((s) => s.supportsInstant).toList(),
    _Filter.scheduled =>
      widget.services.where((s) => !s.supportsInstant).toList(),
  };

  ServiceItem? get _inspection {
    for (final s in widget.services) {
      if (s.title.toLowerCase().contains('inspection')) return s;
    }
    return null;
  }

  void _open(ServiceItem service) => widget.onServiceSelected(context, service);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 560 ? 3 : 2;
    final visible = _where(_filter);
    final inspection = _filter == _Filter.scheduled || _filter == _Filter.all
        ? _inspection
        : null;

    return Scaffold(
      backgroundColor: _pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: _AnimatedHeader.expandedHeight,
              backgroundColor: _brandTeal,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () {
                  AppHaptics.press();
                  Navigator.of(context).pop();
                },
                icon: const Icon(LucideIcons.arrowLeft, size: 22),
                tooltip: 'Back',
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              flexibleSpace: _AnimatedHeader(
                count: widget.services.length,
                topInset: MediaQuery.paddingOf(context).top,
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    for (final f in _Filter.values) ...[
                      _FilterChip(
                        label: switch (f) {
                          _Filter.all => 'All',
                          _Filter.instant => 'Instant',
                          _Filter.scheduled => 'Scheduled',
                        },
                        icon: switch (f) {
                          _Filter.all => LucideIcons.layoutGrid,
                          _Filter.instant => LucideIcons.zap,
                          _Filter.scheduled => LucideIcons.calendarClock,
                        },
                        count: _where(f).length,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (inspection != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: StaggerIn(
                    index: 0,
                    child: _InspectionPromo(
                      service: inspection,
                      onTap: () => _open(inspection),
                    ),
                  ),
                ),
              ),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'No services here yet',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverGrid.builder(
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 262,
                  ),
                  itemBuilder: (context, index) {
                    final service = visible[index];
                    return StaggerIn(
                      key: ValueKey('${_filter.name}-${service.title}'),
                      index: index + 1,
                      child: _ServiceTile(
                        service: service,
                        onTap: () => _open(service),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Collapsing header with ambient motion: trade tokens bob on an arc, dashed
/// rings turn slowly and the tagline cycles through trades. One 9s loop drives
/// everything; it pauses once the header is collapsed and holds a still frame
/// under reduced motion.
class _AnimatedHeader extends StatefulWidget {
  const _AnimatedHeader({required this.count, required this.topInset});

  static const expandedHeight = 200.0;

  final int count;
  final double topInset;

  @override
  State<_AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends State<_AnimatedHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  bool _reduce = false;

  static const _trades = [
    'plumbing',
    'electrical',
    'painting',
    'carpentry',
    'AC service',
  ];

  static const _tokens = [
    (LucideIcons.wrench, Color(0xFF0B7480), Offset(0.70, 0.28), 0.0),
    (LucideIcons.zap, Color(0xFF1D4FC4), Offset(0.86, 0.14), 1.3),
    (LucideIcons.paintRoller, Color(0xFF7438C2), Offset(0.93, 0.48), 2.6),
    (LucideIcons.hammer, Color(0xFF9C5317), Offset(0.81, 0.66), 3.9),
    (LucideIcons.snowflake, Color(0xFF0A8FB8), Offset(0.67, 0.72), 5.2),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _sync(true);
  }

  void _sync(bool expanded) {
    if (_reduce) {
      _loop.stop();
      _loop.value = 0.12;
    } else if (expanded && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!expanded && _loop.isAnimating) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = kToolbarHeight + widget.topInset;
        final maxH = _AnimatedHeader.expandedHeight + widget.topInset;
        final t = ((constraints.maxHeight - minH) / (maxH - minH)).clamp(
          0.0,
          1.0,
        );
        // Avoid ticking behind a collapsed bar.
        _sync(t > 0.05);
        final reveal = Curves.easeOut.transform(
          ((t - 0.35) / 0.65).clamp(0, 1),
        );

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_brandTeal, Color(0xFF02343B)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _OrbitPainter(clock: _loop, fade: t),
                    ),
                  ),
                ),
                if (t > 0.05)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: widget.topInset,
                    bottom: 0,
                    child: Opacity(
                      opacity: reveal,
                      child: LayoutBuilder(
                        builder: (context, box) => AnimatedBuilder(
                          animation: _loop,
                          builder: (context, _) => Stack(
                            children: [
                              for (final (icon, color, at, phase) in _tokens)
                                _token(box.biggest, icon, color, at, phase),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Expanded title + rotating tagline.
                Positioned(
                  left: 20,
                  bottom: 22,
                  right: 140,
                  child: Opacity(
                    opacity: reveal,
                    child: Transform.translate(
                      offset: Offset(0, (1 - reveal) * 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'All services',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.count} categories · verified pros for',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height: 24,
                            child: AnimatedBuilder(
                              animation: _loop,
                              builder: (context, _) {
                                final i =
                                    (_loop.value * _trades.length).floor() %
                                    _trades.length;
                                return _TradeSwitcher(
                                  word: _trades[i],
                                  reduce: _reduce,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Collapsed title in the toolbar.
                Positioned(
                  left: 56,
                  top: widget.topInset,
                  height: kToolbarHeight,
                  child: Opacity(
                    opacity: (1 - t * 2.5).clamp(0, 1),
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All services',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _token(
    Size area,
    IconData icon,
    Color color,
    Offset at,
    double phase,
  ) {
    final angle = _loop.value * 2 * math.pi + phase;
    const size = 40.0;
    return Positioned(
      left: area.width * at.dx - size / 2,
      top: area.height * at.dy - size / 2 + math.sin(angle) * 5,
      child: Transform.rotate(
        angle: math.sin(angle + 1) * 0.12,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

/// Gold trade word that rolls up when it changes.
class _TradeSwitcher extends StatelessWidget {
  const _TradeSwitcher({required this.word, required this.reduce});

  final String word;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: reduce ? 0 : 420),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(word);
          final offset = Tween(
            begin: Offset(0, incoming ? 1 : -1),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: Text(
          word,
          key: ValueKey(word),
          style: const TextStyle(
            color: AppColors.brandGold,
            fontSize: 17,
            height: 1.3,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Dashed rings turning around the token cluster, plus twinkling dots.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.clock, required this.fade})
    : super(repaint: clock);

  final Animation<double> clock;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (fade <= 0.02) return;
    final center = Offset(size.width * 0.76, size.height * 0.55);
    final spin = clock.value * 2 * math.pi;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (var ring = 0; ring < 3; ring++) {
      final r = 58.0 + ring * 38;
      paint.color = Colors.white.withValues(alpha: (0.13 - ring * 0.03) * fade);
      final dir = ring.isEven ? 1 : -1;
      const dashes = 28;
      for (var i = 0; i < dashes; i++) {
        final a = i / dashes * 2 * math.pi + spin * dir / (ring + 1);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          a,
          math.pi / dashes,
          false,
          paint,
        );
      }
    }
    final dot = Paint();
    for (var i = 0; i < 9; i++) {
      final seed = i * 1.618;
      final p = Offset(
        size.width * (0.08 + (seed * 0.37) % 0.9),
        size.height * (0.12 + (seed * 0.53) % 0.8),
      );
      final tw = 0.5 + 0.5 * math.sin(spin * 2 + seed * 4);
      dot.color = Colors.white.withValues(alpha: 0.28 * tw * fade);
      canvas.drawCircle(p, 1.2 + tw * 1.3, dot);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.fade != fade;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.brandForest;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: () {
          AppHaptics.press();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandForest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandForest : const Color(0xFFE6E2D6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected && icon == LucideIcons.zap
                    ? AppColors.brandGold
                    : fg,
              ),
              const SizedBox(width: 6),
              Text(
                '$label $count',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionPromo extends StatelessWidget {
  const _InspectionPromo({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringPressable(
      onTap: onTap,
      child: Container(
        height: 132,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.brandForest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'NEW HOME?',
                      style: TextStyle(
                        color: AppColors.brandGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Get a deep inspection before you move in',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandGold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'From ₹${service.price}',
                            style: const TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.brandForest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 118,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.35],
                ).createShader(bounds),
                child: ServicePhoto(
                  service: service,
                  accent: serviceAccent(service.title),
                  iconSize: 44,
                  cacheWidth: 360,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = serviceAccent(service.title);
    return Semantics(
      button: true,
      label: '${service.title}, from ${service.price} rupees',
      child: SpringPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 124,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ServicePhoto(
                        service: service,
                        accent: accent,
                        iconSize: 46,
                        cacheWidth: 420,
                      ),
                      if (service.supportsInstant)
                        const Positioned(
                          left: 8,
                          top: 8,
                          child: InstantTag(scale: 1.1),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 4,
                        child: ColoredBox(color: accent),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          service.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${service.price}',
                                    style: const TextStyle(
                                      color: AppColors.brandForest,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    service.duration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.arrowRight,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

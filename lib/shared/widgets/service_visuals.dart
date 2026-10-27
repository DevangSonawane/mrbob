import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/service_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_haptics.dart';

/// Shared service visuals used by home, bookings and the all-services page:
/// category photos and accents, the caps divider header, spring press
/// feedback and shimmer skeletons. Motion here is one-shot or loading-only
/// and respects reduced motion.

String? categoryAssetPathForTitle(String title) {
  return switch (_normalizeTitle(title)) {
    'plumber' || 'plumbing' => 'assets/service_cat/plumbing.png',
    'electrician' || 'electrical' => 'assets/service_cat/electrician.png',
    'painting' || 'paintings' => 'assets/service_cat/painting.png',
    'civiltouchups' || 'ceiling' => 'assets/service_cat/ceiling.png',
    'carpenter' || 'carpentry' => 'assets/service_cat/carpenting.png',
    'deepinspection' || 'inspection' => 'assets/service_cat/inspection.png',
    'ac' => 'assets/mrbob_onboarding/MrBob HVAC Ductwork Installation.png',
    _ => null,
  };
}

String _normalizeTitle(String title) => title
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '')
    .replaceAll('repair', '')
    .replaceAll('fixes', '')
    .replaceAll('snags', '')
    .replaceAll('servicing', '')
    .replaceAll('service', '');

/// Short tile label for a category title.
String shortServiceTitle(String title) => switch (title) {
  'Civil touch-ups' => 'Civil',
  'Plumbing fixes' => 'Plumbing',
  'Electrical snags' => 'Electrical',
  'Painting repairs' => 'Painting',
  'Carpentry fixes' => 'Carpentry',
  'Deep inspection' => 'Inspection',
  'AC servicing' => 'AC Service',
  'Appliance repair' => 'Appliance',
  _ => title,
};

/// Per-category accent, matched to the hero banner's trade colours.
Color serviceAccent(String title) {
  final key = _normalizeTitle(title);
  bool has(String s) => key.contains(s);
  if (has('plumb')) return const Color(0xFF0B7480);
  if (has('electric')) return const Color(0xFF1D4FC4);
  if (has('paint')) return const Color(0xFF7438C2);
  if (has('carpent')) return const Color(0xFF9C5317);
  if (has('inspect')) return const Color(0xFF035864);
  if (key == 'ac' || has('hvac') || has('cool')) {
    return const Color(0xFF0A8FB8);
  }
  if (has('applian')) return const Color(0xFF2E8B57);
  if (has('civil') || has('ceiling')) return const Color(0xFFD9822B);
  return AppColors.brandForest;
}

class CapsSectionHeader extends StatelessWidget {
  const CapsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    Widget line(bool leading) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brandForest.withValues(alpha: leading ? 0 : 0.16),
              AppColors.brandForest.withValues(alpha: leading ? 0.16 : 0),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      header: true,
      child: Row(
        children: [
          line(true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: AppColors.brandForest.withValues(alpha: 0.62),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ),
          line(false),
        ],
      ),
    );
  }
}

class InstantTag extends StatelessWidget {
  const InstantTag({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        4 * scale,
        1.5 * scale,
        6 * scale,
        1.5 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandGold,
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, size: 9 * scale, color: AppColors.brandForest),
          SizedBox(width: 2 * scale),
          Text(
            'INSTANT',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 8 * scale,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Category photo: API image, then bundled asset, then the service icon on
/// an accent wash.
class ServicePhoto extends StatelessWidget {
  const ServicePhoto({
    super.key,
    required this.service,
    required this.accent,
    required this.iconSize,
    required this.cacheWidth,
  });

  final ServiceItem service;
  final Color accent;
  final double iconSize;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Color.alphaBlend(accent.withValues(alpha: 0.14), Colors.white),
      child: Center(
        child: Icon(service.icon, color: accent, size: iconSize),
      ),
    );
    final url = service.imageUrl;
    if (url != null) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: _fadeIn,
      );
    }
    final asset = service.usesApiImage
        ? null
        : categoryAssetPathForTitle(service.title);
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        frameBuilder: _fadeIn,
      );
    }
    return fallback;
  }

  static Widget _fadeIn(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

/// Spring press feedback: scales down while held, springs back on release.
class SpringPressable extends StatefulWidget {
  const SpringPressable({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends State<SpringPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        AppHaptics.press();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down && !reduce ? 0.94 : 1,
        duration: Duration(milliseconds: _down ? 90 : 320),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    required this.width,
    required this.height,
    this.radius = 6,
  }) : _circle = false;

  const SkeletonBone.circle(double size, {super.key})
    : width = size,
      height = size,
      radius = 0,
      _circle = true;

  final double width;
  final double height;
  final double radius;
  final bool _circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: _circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Sweeps a soft highlight across [SkeletonBone] placeholders (painted white, then
/// tinted through the gradient mask). Static under reduced motion.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, required this.child});

  final Widget child;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFF1EEE6);
    const highlight = Color(0xFFFBFAF6);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final dx = _c.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(dx - 1, -0.3),
            end: Alignment(dx + 1, 0.3),
            colors: const [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// One-shot fade + rise for list items, staggered by [index]. Skipped under
/// reduced motion.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index.clamp(0, 6)) * 55;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 460 + delay),
    );
    final start = delay / (460 + delay);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * 18),
          child: child,
        ),
      ),
    );
  }
}

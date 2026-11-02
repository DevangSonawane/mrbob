import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/service_visuals.dart';

/// Home body sections below the hero header, in the food/quick-commerce
/// idiom (Swiggy "What's on your mind?", Zomato dividers, Instamart ADD
/// buttons):
/// - [CapsSectionHeader]: centred caps title between fading hairlines.
/// - [HomeCategoryRail]: 3-column grid of five image tiles plus See all.
/// - [HomePopularRail]: tall offer cards with an overlapping BOOK button.
///
/// Motion is one-shot only (a staggered pop-in when data arrives, a spring
/// press scale, a shimmer while loading) and is skipped under reduced motion.

const _ratingGreen = Color(0xFF1C8A3A);
const _bookTeal = Color(0xFF035864);

/// The home rail shows a fixed handful of categories; the rest live on the
/// all-categories page.
const _homeCategoryCount = 5;
const _homeColumns = 3;

/// Home tile artwork; categories without their own image use the AC unit.
String _categoryImage(ServiceItem service) {
  final title = service.title.toLowerCase();
  if (title.contains('paint')) return 'assets/fixing/painting.png';
  if (title.contains('pest')) return 'assets/fixing/pestcontrol.png';
  if (title.contains('carpent')) return 'assets/fixing/carpenter.png';
  if (title.contains('electric')) return 'assets/fixing/electricity.png';
  if (title.contains('ac repair') || title.contains('ac servic')) {
    return 'assets/fixing/appliancerepair.png';
  }
  if (title.contains('applian')) return 'assets/fixing/appliancerepair.png';
  return 'assets/service_cat/ac_unit.png';
}

/// The categories featured on home: pest control takes appliance repair's
/// slot, then the first [_homeCategoryCount] in catalogue order.
List<ServiceItem> _homeCategories(List<ServiceItem> services) {
  bool isPest(ServiceItem s) => s.title.toLowerCase().contains('pest');
  bool isAppliance(ServiceItem s) => s.title.toLowerCase().contains('applian');
  final pest = services.where(isPest).firstOrNull;
  return [
    for (final service in services)
      if (isAppliance(service)) ?pest else if (!isPest(service)) service,
  ].take(_homeCategoryCount).toList();
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

class HomeCategoryRail extends StatefulWidget {
  const HomeCategoryRail({
    super.key,
    required this.services,
    required this.loading,
    required this.scale,
    required this.horizontalInset,
    required this.onTap,
    required this.onSeeAll,
    required this.onRetry,
  });

  final List<ServiceItem> services;
  final bool loading;
  final double scale;
  final double horizontalInset;
  final ValueChanged<ServiceItem> onTap;
  final VoidCallback onSeeAll;
  final VoidCallback onRetry;

  @override
  State<HomeCategoryRail> createState() => _HomeCategoryRailState();
}

class _HomeCategoryRailState extends State<HomeCategoryRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeEnter();
  }

  @override
  void didUpdateWidget(HomeCategoryRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeEnter();
  }

  void _maybeEnter() {
    if (widget.loading || widget.services.isEmpty) return;
    if (_enter.status != AnimationStatus.dismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final imageHeight = 72.0 * s;
    final rowSpacing = 18.0 * s;
    final columnSpacing = 10.0 * s;
    final padding = EdgeInsets.symmetric(horizontal: widget.horizontalInset);

    // Lays [cells] out row-major, _homeColumns per row.
    Widget grid(List<Widget> cells) => Padding(
      padding: padding,
      child: Column(
        children: [
          for (var row = 0; row * _homeColumns < cells.length; row++) ...[
            if (row > 0) SizedBox(height: rowSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < _homeColumns; col++) ...[
                  if (col > 0) SizedBox(width: columnSpacing),
                  Expanded(
                    child: row * _homeColumns + col < cells.length
                        ? cells[row * _homeColumns + col]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (widget.loading) {
      return ShimmerBox(
        child: grid([
          for (var i = 0; i <= _homeCategoryCount; i++)
            Column(
              children: [
                SkeletonBone(
                  width: double.infinity,
                  height: imageHeight,
                  radius: 14 * s,
                ),
                SizedBox(height: 10 * s),
                SkeletonBone(width: 56 * s, height: 10 * s),
              ],
            ),
        ]),
      );
    }

    if (widget.services.isEmpty) {
      return Padding(
        padding: padding,
        child: _LoadError(scale: s, onRetry: widget.onRetry),
      );
    }

    final shown = _homeCategories(widget.services);
    return grid([
      for (var index = 0; index < shown.length; index++)
        _staggered(
          index,
          _CategoryTile(
            service: shown[index],
            scale: s,
            imageHeight: imageHeight,
            onTap: () => widget.onTap(shown[index]),
          ),
        ),
      _staggered(
        shown.length,
        _SeeAllTile(scale: s, size: imageHeight, onTap: widget.onSeeAll),
      ),
    ]);
  }

  /// Row-major pop-in so the grid fills left to right, top to bottom.
  Widget _staggered(int index, Widget tile) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, start + 0.4, curve: Curves.easeOutBack),
    );
    final fade = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, start + 0.25, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(anim),
        child: tile,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.service,
    required this.scale,
    required this.imageHeight,
    required this.onTap,
  });

  final ServiceItem service;
  final double scale;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final label = shortServiceTitle(service.title);

    return Semantics(
      button: true,
      label: service.supportsInstant ? '$label, instant' : label,
      child: SpringPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            children: [
              SizedBox(
                height: imageHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.16,
                      child: Image.asset(
                        _categoryImage(service),
                        fit: BoxFit.contain,
                        // Decode at the tile's real pixel height: the 1600px
                        // sources are wasteful at full size, and a fixed small
                        // cache upscales blurry on 3x screens.
                        cacheHeight:
                            (imageHeight *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    if (service.supportsInstant)
                      Positioned(
                        bottom: -4 * s,
                        child: InstantTag(scale: s),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 10 * s),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 12.5 * s,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllTile extends StatelessWidget {
  const _SeeAllTile({
    required this.scale,
    required this.size,
    required this.onTap,
  });

  final double scale;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      button: true,
      label: 'See all categories',
      child: SpringPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceTint,
                  border: Border.all(
                    color: AppColors.brandGold.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowRight,
                  color: AppColors.brandForest,
                  size: 24 * s,
                ),
              ),
              SizedBox(height: 10 * s),
              Text(
                'See all',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 12.5 * s,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Popular services
// ---------------------------------------------------------------------------

class HomePopularRail extends StatelessWidget {
  const HomePopularRail({
    super.key,
    required this.services,
    required this.loading,
    required this.scale,
    required this.horizontalInset,
    required this.onTap,
  });

  final List<ServiceItem> services;
  final bool loading;
  final double scale;
  final double horizontalInset;
  final ValueChanged<ServiceItem> onTap;

  static double heightFor(double scale) => 278 * scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final cardWidth = 164.0 * s;
    final padding = EdgeInsets.fromLTRB(
      horizontalInset,
      2 * s,
      horizontalInset,
      10 * s,
    );

    if (!loading && services.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: heightFor(s),
      child: loading
          ? ShimmerBox(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: padding,
                itemCount: 3,
                separatorBuilder: (_, _) => SizedBox(width: 14 * s),
                itemBuilder: (_, _) => SizedBox(
                  width: cardWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBone(
                        width: cardWidth,
                        height: 146 * s,
                        radius: 18 * s,
                      ),
                      SizedBox(height: 24 * s),
                      SkeletonBone(width: cardWidth * 0.8, height: 12 * s),
                      SizedBox(height: 10 * s),
                      SkeletonBone(width: cardWidth * 0.5, height: 10 * s),
                      SizedBox(height: 10 * s),
                      SkeletonBone(width: cardWidth * 0.6, height: 10 * s),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: padding,
              itemCount: services.length,
              separatorBuilder: (_, _) => SizedBox(width: 14 * s),
              itemBuilder: (context, index) => _PopularCard(
                service: services[index],
                width: cardWidth,
                scale: s,
                onTap: () => onTap(services[index]),
              ),
            ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.service,
    required this.width,
    required this.scale,
    required this.onTap,
  });

  final ServiceItem service;
  final double width;
  final double scale;
  final VoidCallback onTap;

  /// Discount shown against the struck-through list price.
  static const _offAmount = 200;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final accent = serviceAccent(service.title);
    final imageHeight = 146.0 * s;
    final radius = 18.0 * s;

    return Semantics(
      button: true,
      label:
          '${service.title}, rated 4.8, ${service.duration}, '
          'rupees ${service.price}, $_offAmount off',
      child: SpringPressable(
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: imageHeight,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 14 * s,
                            offset: Offset(0, 6 * s),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ServicePhoto(
                              service: service,
                              accent: accent,
                              iconSize: 56 * s,
                              cacheWidth: 480,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.45, 1],
                                  colors: [
                                    Colors.transparent,
                                    Color(0xC7000000),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10 * s,
                              top: 10 * s,
                              child: _BadgePill(text: service.badge, scale: s),
                            ),
                            if (service.supportsInstant)
                              Positioned(
                                right: 10 * s,
                                top: 10 * s,
                                child: Container(
                                  width: 24 * s,
                                  height: 24 * s,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandGold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.zap,
                                    size: 13 * s,
                                    color: AppColors.brandForest,
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 11 * s,
                              right: 10 * s,
                              bottom: 26 * s,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹$_offAmount OFF',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19 * s,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                      height: 1,
                                    ),
                                  ),
                                  SizedBox(height: 3 * s),
                                  Text(
                                    'ON THIS SERVICE',
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                      fontSize: 8.5 * s,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8 * s,
                      bottom: -15 * s,
                      child: _BookButton(scale: s),
                    ),
                  ],
                ),
                SizedBox(height: 22 * s),
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 6 * s),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5 * s,
                        vertical: 2 * s,
                      ),
                      decoration: BoxDecoration(
                        color: _ratingGreen,
                        borderRadius: BorderRadius.circular(5 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5 * s,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(width: 2 * s),
                          Icon(
                            Icons.star_rounded,
                            size: 10 * s,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    Icon(
                      LucideIcons.clock3,
                      size: 12 * s,
                      color: AppColors.mutedText,
                    ),
                    SizedBox(width: 3 * s),
                    Flexible(
                      child: Text(
                        service.duration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11.5 * s,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5 * s),
                Text(
                  service.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11.5 * s,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 7 * s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹${service.price}',
                      style: TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 5 * s),
                    Text(
                      '₹${service.price + _offAmount}',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 11.5 * s,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.text, required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 110 * scale),
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.brandForest,
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32 * scale,
      padding: EdgeInsets.symmetric(horizontal: 14 * scale),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(color: _bookTeal.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: Text(
        'BOOK',
        style: TextStyle(
          color: _bookTeal,
          fontSize: 13 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _LoadError extends StatelessWidget {
  const _LoadError({required this.scale, required this.onRetry});

  final double scale;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.wifiOff,
            color: AppColors.mutedText,
            size: 20 * scale,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              "Couldn't load services",
              style: TextStyle(
                color: AppColors.brandForest,
                fontSize: 13.5 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: _bookTeal),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

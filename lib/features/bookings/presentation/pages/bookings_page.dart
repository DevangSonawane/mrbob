import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/service_visuals.dart';
import '../widgets/booking_card.dart';
import 'booking_detail_page.dart';

const _pageBg = Color(0xFFF6F5F1);

class BookingsPage extends StatefulWidget {
  const BookingsPage({
    super.key,
    required this.bookings,
    this.isLoading = false,
    this.onBrowse,
    this.onChanged,
  });

  final List<Booking> bookings;
  final bool isLoading;
  final VoidCallback? onBrowse;

  /// Reloads the bookings list after pull-to-refresh
  /// or a detail-page status transition.
  final Future<void> Function()? onChanged;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  int _filterIndex = 0;

  static const _filters = ['All', 'Instant', 'Scheduled', 'Completed'];

  List<Booking> get _filtered {
    return switch (_filterIndex) {
      1 => widget.bookings.where((b) => b.mode == 'Instant').toList(),
      2 => widget.bookings.where((b) => b.mode == 'Scheduled').toList(),
      3 =>
        widget.bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList(),
      _ => widget.bookings,
    };
  }

  Future<void> _refreshBookings() async {
    AppHaptics.press();
    await widget.onChanged?.call();
  }

  void _openDetail(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BookingDetailPage(booking: booking, onChanged: widget.onChanged),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final active = filtered.where((b) => b.status.isActive).toList();
    final past = filtered.where((b) => !b.status.isActive).toList();
    var index = 0;

    Widget card(Booking booking) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StaggerIn(
        // Re-key per filter so switching segments replays the entrance.
        key: ValueKey('$_filterIndex-${identityHashCode(booking)}'),
        index: index++,
        child: BookingCard(
          booking: booking,
          onTap: () => _openDetail(booking),
          onRate:
              booking.status == BookingStatus.completed && booking.id.isNotEmpty
              ? (star) => _openRatingSheet(booking, star)
              : null,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandForest,
          onRefresh: _refreshBookings,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                sliver: SliverToBoxAdapter(
                  child: _Header(bookings: widget.bookings),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  filters: _filters,
                  counts: [for (var i = 0; i < _filters.length; i++) _count(i)],
                  selectedIndex: _filterIndex,
                  onSelected: (index) {
                    if (index == _filterIndex) return;
                    AppHaptics.press();
                    setState(() => _filterIndex = index);
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
                sliver: SliverList.list(
                  children: [
                    if (widget.isLoading)
                      const _BookingsLoadingState()
                    else if (filtered.isEmpty)
                      _EmptyState(onBrowse: widget.onBrowse)
                    else ...[
                      if (active.isNotEmpty) ...[
                        const CapsSectionHeader(title: 'Ongoing'),
                        const SizedBox(height: 14),
                        for (final booking in active) card(booking),
                      ],
                      if (past.isNotEmpty) ...[
                        if (active.isNotEmpty) const SizedBox(height: 10),
                        const CapsSectionHeader(title: 'Past bookings'),
                        const SizedBox(height: 14),
                        for (final booking in past) card(booking),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _count(int index) {
    final saved = _filterIndex;
    _filterIndex = index;
    final n = _filtered.length;
    _filterIndex = saved;
    return n;
  }

  Future<void> _openRatingSheet(Booking booking, int initialRating) async {
    if (booking.id.isEmpty) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _VendorRatingSheet(booking: booking, initialRating: initialRating),
    );
    if (submitted == true) await widget.onChanged?.call();
  }
}

class _VendorRatingSheet extends StatefulWidget {
  const _VendorRatingSheet({required this.booking, this.initialRating});

  final Booking booking;
  final int? initialRating;

  @override
  State<_VendorRatingSheet> createState() => _VendorRatingSheetState();
}

class _VendorRatingSheetState extends State<_VendorRatingSheet> {
  late int _rating = widget.initialRating ?? widget.booking.customerRating ?? 0;
  late final TextEditingController _comment = TextEditingController(
    text: widget.booking.customerRatingComment ?? '',
  );
  bool _isSubmitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _isSubmitting = true);
    try {
      await BookingService.instance.rateVendor(
        bookingId: widget.booking.id,
        rating: _rating,
        comment: _comment.text,
      );
      if (!mounted) return;
      AppHaptics.success();
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.booking.customerRating == null
                  ? 'Rate your vendor'
                  : 'Update your rating',
              style: const TextStyle(
                color: AppColors.brandForest,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How was your ${widget.booking.service.title} service?',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: star <= _rating
                          ? AppColors.brandGold
                          : const Color(0xFFD8D3C8),
                      size: 32,
                    ),
                    tooltip: '$star star${star == 1 ? '' : 's'}',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share feedback (optional)',
                filled: true,
                fillColor: Color(0xFFFAFAF7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting || _rating == 0 ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandForest,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.booking.customerRating == null
                            ? 'Submit rating'
                            : 'Update rating',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsLoadingState extends StatelessWidget {
  const _BookingsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: i == 0 ? 210 : 96,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBone(width: 54, height: 54, radius: 14),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBone(width: 150, height: 13),
                      SizedBox(height: 10),
                      SkeletonBone(width: 100, height: 10),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final active = bookings.where((b) => b.status.isActive).length;
    final done = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My bookings',
                style: TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bookings.isEmpty
                    ? 'Your visits will show up here'
                    : '$active ongoing · $done done',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (active > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
            decoration: BoxDecoration(
              color: AppColors.brandGold,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.radio,
                  size: 14,
                  color: AppColors.brandForest,
                ),
                const SizedBox(width: 5),
                Text(
                  '$active live',
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const _FilterBarDelegate({
    required this.filters,
    required this.counts,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final List<int> counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _height = 60.0;

  static const _icons = [
    LucideIcons.layers,
    LucideIcons.zap,
    LucideIcons.calendarClock,
    LucideIcons.circleCheck,
  ];

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _pageBg,
        boxShadow: overlapsContent || shrinkOffset > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _FilterPill(
          key: ValueKey('filter-${filters[i]}'),
          label: filters[i],
          icon: _icons[i % _icons.length],
          count: counts[i],
          selected: i == selectedIndex,
          onTap: () => onSelected(i),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate old) =>
      old.selectedIndex != selectedIndex ||
      old.counts.join() != counts.join() ||
      old.onSelected != onSelected;
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    super.key,
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
      label: '$label, $count',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(11, 0, 6, 0),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandForest : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brandForest : const Color(0xFFE6E2D6),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandForest.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected && icon == LucideIcons.zap
                      ? AppColors.brandGold
                      : fg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandGold
                        : const Color(0xFFF1EFE8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.brandForest,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          SizedBox(
            width: 120,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandGold.withValues(alpha: 0.16),
                  ),
                ),
                Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: 64,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.calendarPlus,
                      color: Color(0xFF035864),
                      size: 30,
                    ),
                  ),
                ),
                const Positioned(
                  right: 6,
                  top: 10,
                  child: Icon(
                    LucideIcons.sparkles,
                    color: AppColors.brandGold,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No bookings here',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Services you book will appear here. '
            'Tap below to plan your first visit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          if (onBrowse != null)
            FilledButton(
              onPressed: () {
                AppHaptics.press();
                onBrowse?.call();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandForest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Browse services',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}

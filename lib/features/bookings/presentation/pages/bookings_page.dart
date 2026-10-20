import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../widgets/booking_card.dart';
import 'booking_detail_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brandForest,
          onRefresh: _refreshBookings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
            children: [
              const _Header(),
              const SizedBox(height: 18),
              _GlassFilterBar(
                filters: _filters,
                selectedIndex: _filterIndex,
                onSelected: (index) => setState(() => _filterIndex = index),
              ),
              const SizedBox(height: 20),
              if (widget.isLoading)
                const _BookingsLoadingState()
              else if (filtered.isEmpty)
                _EmptyState(onBrowse: widget.onBrowse)
              else
                Column(
                  children: [
                    for (final booking in filtered) ...[
                      GestureDetector(
                        onTap: () {
                          AppHaptics.press();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailPage(
                                booking: booking,
                                onChanged: widget.onChanged,
                              ),
                            ),
                          );
                        },
                        child: BookingCard(
                          booking: booking,
                          onRate: booking.status == BookingStatus.completed
                              ? () => _openRatingSheet(booking)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRatingSheet(Booking booking) async {
    if (booking.id.isEmpty) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VendorRatingSheet(booking: booking),
    );
    if (submitted == true) await widget.onChanged?.call();
  }
}

class _VendorRatingSheet extends StatefulWidget {
  const _VendorRatingSheet({required this.booking});

  final Booking booking;

  @override
  State<_VendorRatingSheet> createState() => _VendorRatingSheetState();
}

class _VendorRatingSheetState extends State<_VendorRatingSheet> {
  late int _rating = widget.booking.customerRating ?? 0;
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.brandForest,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'My bookings',
      style: TextStyle(
        color: AppColors.brandForest,
        fontSize: 23,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _GlassFilterBar extends StatelessWidget {
  const _GlassFilterBar({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // Real segmented control (SKILL.md §4 substitution table): fluid glass
    // indicator with jelly physics and built-in drag-to-select
    // (SegmentDragBehavior.selectIndicator). Never wrapped in glass (Rule 2).
    return GlassSegmentedControl(
      segments: [for (final label in filters) GlassSegment(label: label)],
      selectedIndex: selectedIndex,
      onSegmentSelected: onSelected,
      height: 42,
      backgroundColor: AppColors.brandForest,
      indicatorColor: AppColors.brandGold,
      selectedTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
      unselectedTextStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
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
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDE4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.packageOpen,
              color: Color(0xFF9BA09A),
              size: 30,
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

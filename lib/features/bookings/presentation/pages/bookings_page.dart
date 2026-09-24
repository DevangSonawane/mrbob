import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/booking_card.dart';
import 'booking_detail_page.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.bookings, this.onBrowse});

  final List<Booking> bookings;
  final VoidCallback? onBrowse;

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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
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
            if (filtered.isEmpty)
              _EmptyState(onBrowse: widget.onBrowse)
            else
              Column(
                children: [
                  for (final booking in filtered) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BookingDetailPage(booking: booking),
                        ),
                      ),
                      child: BookingCard(booking: booking),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
          ],
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
              onPressed: onBrowse,
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

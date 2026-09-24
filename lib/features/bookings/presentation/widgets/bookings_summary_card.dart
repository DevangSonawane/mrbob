import 'package:flutter/material.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';

class BookingsSummaryCard extends StatelessWidget {
  const BookingsSummaryCard({super.key, required this.bookings});

  final List<Booking> bookings;

  int get _activeCount => bookings.where((b) => b.status.isActive).length;
  int get _completedCount =>
      bookings.where((b) => b.status == BookingStatus.completed).length;
  int get _totalSpent => bookings.fold(
    0,
    (sum, b) => sum + (b.status == BookingStatus.completed ? b.total : 0),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _Stat(value: '$_activeCount', label: 'Active now'),
          _Stat(value: '$_completedCount', label: 'Completed'),
          _Stat(value: 'Rs $_totalSpent', label: 'Total spent'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.brandForest,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
    );
  }
}

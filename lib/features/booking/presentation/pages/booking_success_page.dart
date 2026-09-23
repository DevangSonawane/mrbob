import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  size: 62,
                  color: AppColors.brandForest,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking confirmed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${booking.service.title} is booked for ${booking.slot}. Share OTP 4821 when your pro arrives.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, booking),
                icon: const Icon(LucideIcons.receiptText),
                label: const Text('View my bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

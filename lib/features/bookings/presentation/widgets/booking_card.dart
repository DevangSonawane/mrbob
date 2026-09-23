import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final accent = Color.lerp(
      booking.service.color,
      AppColors.brandForest,
      0.24,
    )!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(width: 5, color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(booking: booking),
                  const SizedBox(height: 14),
                  _InfoRow(icon: LucideIcons.calendar, text: booking.slot),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoRow(
                        icon: booking.mode == 'Instant'
                            ? LucideIcons.bolt
                            : LucideIcons.clock3,
                        text: booking.mode,
                      ),
                      if (booking.paysOnDelivery) ...[
                        const Spacer(),
                        const _OtpPill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: const Color(0xFFEFEDE6)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoRow(
                          icon: booking.paysOnDelivery
                              ? LucideIcons.truck
                              : LucideIcons.creditCard,
                          text: booking.payment,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs ${booking.total}',
                            style: const TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'incl. taxes',
                            style: TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: booking.service.color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: booking.service.color.withValues(alpha: 0.6),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            booking.service.icon,
            color: AppColors.brandForest,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.service.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                booking.service.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusPill(status: booking.status),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  (Color, Color) get _scheme => switch (status) {
    BookingStatus.confirmed => (const Color(0xFFEAF3EA), AppColors.brandForest),
    BookingStatus.inService => (
      const Color(0xFFFBEFDC),
      const Color(0xFF8A5A00),
    ),
    BookingStatus.completed => (
      const Color(0xFFEEF0EC),
      const Color(0xFF6E756E),
    ),
    BookingStatus.cancelled => (
      const Color(0xFFFBEAEA),
      const Color(0xFFB3261E),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _scheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F1E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: AppColors.brandForest),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3E463E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpPill extends StatelessWidget {
  const _OtpPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.keyRound, size: 12, color: AppColors.brandForest),
          SizedBox(width: 5),
          Text(
            'OTP 4821',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

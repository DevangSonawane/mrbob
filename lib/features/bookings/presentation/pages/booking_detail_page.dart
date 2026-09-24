import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';

/// Booking detail, matching the payment-failed reference screen exactly:
/// pink header zone with back button, red scalloped seal + title, and a
/// white sheet with the refund note, slot/address card and action rows.
class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking});

  final Booking booking;

  static const _pinkBg = Color(0xFFF9ECEC);
  static const _sealRed = Color(0xFFCE2E30);
  static const _ink = Color(0xFF212121);
  static const _pink = Color(0xFFEC407A);
  static const _pinkSoft = Color(0xFFFCE7F1);
  static const _greyText = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _pinkBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _pinkBg),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ---- Pink header zone ----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: _ink,
                    iconSize: 22,
                    tooltip: 'Back',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 104,
                height: 104,
                child: CustomPaint(painter: _SealPainter()),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment failed',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 22),
              // ---- White sheet ----
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      24 + bottomInset,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: _pinkSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.hourglass,
                                color: _pink,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'In case any amount was deducted for this '
                                'booking, any deducted amount will be '
                                'refunded back to your original payment '
                                'source',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 13.5,
                                  height: 1.38,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendarDays,
                                  color: _pink,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${booking.slot} • '
                                    '${booking.service.duration} visit',
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    LucideIcons.mapPin,
                                    color: _pink,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'home | 2nd Floor, Green Heights, Andheri '
                                    'East, Mumbai, Maharashtra 400069, India',
                                    style: TextStyle(
                                      color: _ink,
                                      fontSize: 14,
                                      height: 1.42,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.1,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        child: Column(
                          children: [
                            _ActionRow(
                              icon: LucideIcons.indianRupee,
                              title: 'Payment Details',
                              subtitle: 'View detailed price summary',
                              onTap: () =>
                                  _showPriceSummary(context, booking),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _ActionRow(
                              icon: LucideIcons.headset,
                              title: 'Contact Support',
                              subtitle: 'Get quick help for your queries',
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Connecting you to support…',
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceSummary(BuildContext context, Booking booking) {
    final serviceCharge = booking.total - 29;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final inset = MediaQuery.paddingOf(context).bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + inset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Price summary',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              _priceRow('Service charge', 'Rs $serviceCharge'),
              const SizedBox(height: 10),
              _priceRow('Platform fee', 'Rs 29'),
              const Divider(height: 28),
              _priceRow('Total', 'Rs ${booking.total}', isTotal: true),
            ],
          ),
        );
      },
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? _ink : _greyText,
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _ink,
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: BookingDetailPage._pink, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: BookingDetailPage._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: BookingDetailPage._greyText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: BookingDetailPage._greyText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Red scalloped seal with a rounded white X, as in the reference.
class _SealPainter extends CustomPainter {
  const _SealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.width / 2;
    const bumps = 22;
    final path = Path();
    for (var i = 0; i <= bumps * 12; i++) {
      final angle = i / (bumps * 12) * 2 * math.pi;
      final radius = base * 0.90 + base * 0.10 * math.sin(angle * bumps);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = BookingDetailPage._sealRed,
    );

    final arm = base * 0.24;
    final xPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = base * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + Offset(-arm, -arm),
      center + Offset(arm, arm),
      xPaint,
    );
    canvas.drawLine(
      center + Offset(-arm, arm),
      center + Offset(arm, -arm),
      xPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

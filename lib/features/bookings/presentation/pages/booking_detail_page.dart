import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/api/api_booking.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/service_visuals.dart';
import '../../../invoices/presentation/pages/invoice_page.dart';
import '../widgets/booking_card.dart';

const _pageBg = Color(0xFFF6F5F1);
const _divider = Color(0xFFEFEDE6);

/// Booking detail: a status-coloured hero with an animated seal, a tracker,
/// the service, visit and payment cards, and the status actions pinned to
/// the bottom while the booking is active.
class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.booking, this.onChanged});

  final Booking booking;

  /// Called after a status transition succeeds, so the
  /// bookings list behind this page reloads.
  final Future<void> Function()? onChanged;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = booking.status;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    var i = 0;

    return Scaffold(
      backgroundColor: _pageBg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(booking: booking)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              sliver: SliverList.list(
                children: [
                  if (status == BookingStatus.cancelled)
                    _section(
                      i++,
                      _Card(
                        color: status.tint,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.hourglass,
                              color: status.color,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'If any amount was deducted for this booking, '
                                'it will be refunded to your original payment '
                                'source.',
                                style: TextStyle(
                                  color: AppColors.brandForest,
                                  fontSize: 13.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _section(
                      i++,
                      _Card(
                        title: 'Progress',
                        child: BookingProgress(status: status),
                      ),
                    ),
                  _section(i++, _ServiceCard(booking: booking)),
                  _section(
                    i++,
                    _Card(
                      title: 'Visit',
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: LucideIcons.calendarDays,
                            title: booking.slot,
                            subtitle: '${booking.service.duration} visit',
                          ),
                          const Divider(height: 24, color: _divider),
                          const _InfoRow(
                            icon: LucideIcons.mapPin,
                            title: 'Home',
                            subtitle:
                                '2nd Floor, Green Heights, Andheri East, '
                                'Mumbai, Maharashtra 400069',
                          ),
                        ],
                      ),
                    ),
                  ),
                  _section(i++, _paymentCard(booking)),
                  _section(
                    i++,
                    _Card(
                      title: 'Help',
                      child: Column(
                        children: [
                          if (status == BookingStatus.completed &&
                              booking.id.isNotEmpty) ...[
                            _ActionRow(
                              icon: LucideIcons.receiptText,
                              title: 'View invoice',
                              subtitle: 'Final bill and payment status',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      InvoicePage(bookingId: booking.id),
                                ),
                              ),
                            ),
                            const Divider(height: 20, color: _divider),
                          ],
                          _ActionRow(
                            icon: LucideIcons.headset,
                            title: 'Contact support',
                            subtitle: 'Get quick help with this booking',
                            onTap: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Connecting you to support…'),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: status.isActive ? _actionBar(bottomInset) : null,
    );
  }

  Widget _section(int index, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: StaggerIn(index: index, child: child),
  );

  Widget _paymentCard(Booking booking) {
    return _Card(
      title: 'Payment',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: AppColors.brandForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      rupees(booking.total),
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.payment,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (booking.hasPaymentDetails) ...[
            const Divider(height: 24, color: _divider),
            _ActionRow(
              icon: LucideIcons.indianRupee,
              title: 'Price breakdown',
              subtitle: 'Service charge and fees',
              onTap: () => _showPriceSummary(context, booking),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBar(double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isBusy
                  ? null
                  : () => _transitionStatus(ApiBookingStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: BookingStatus.cancelled.color,
                side: BorderSide(
                  color: BookingStatus.cancelled.color.withValues(alpha: 0.4),
                ),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Cancel booking',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isBusy
                  ? null
                  : () => _transitionStatus(ApiBookingStatus.completed),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandForest,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Mark completed',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// `PATCH /bookings/{id}/status` — transitions the
  /// booking on the backend, then refreshes the list
  /// behind this page.
  Future<void> _transitionStatus(ApiBookingStatus status) async {
    AppHaptics.press();
    final id = widget.booking.id;
    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo booking — no server copy to update.'),
        ),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await BookingService.instance.updateStatus(id, status);
      AppHaptics.success();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ${status.value.toLowerCase()}.')),
      );
      await widget.onChanged?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
                  color: AppColors.brandForest,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              _priceRow('Service charge', rupees(serviceCharge)),
              const SizedBox(height: 10),
              _priceRow('Platform fee', rupees(29)),
              const Divider(height: 28),
              _priceRow('Total', rupees(booking.total), isTotal: true),
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
              color: isTotal ? AppColors.brandForest : AppColors.mutedText,
              fontSize: isTotal ? 15 : 13.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.brandForest,
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.booking});

  final Booking booking;

  String get _heading => switch (booking.status) {
    BookingStatus.confirmed => 'Booking confirmed',
    BookingStatus.inService => 'Your pro is on it',
    BookingStatus.completed => 'Service completed',
    BookingStatus.cancelled => 'Booking cancelled',
  };

  String get _subheading => switch (booking.status) {
    BookingStatus.confirmed => 'A verified pro is lined up for ${booking.slot}',
    BookingStatus.inService => 'Work is in progress at your home',
    BookingStatus.completed => 'Hope everything is fixed. Thanks for booking!',
    BookingStatus.cancelled => 'This visit will not go ahead',
  };

  @override
  Widget build(BuildContext context) {
    final color = booking.status.color;
    final top = MediaQuery.paddingOf(context).top;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final id = booking.id;

    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 4, 8, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.30)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HeroRingsPainter()),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      AppHaptics.press();
                      Navigator.of(context).pop();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                    ),
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: Colors.white,
                    iconSize: 20,
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  if (id.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _IdChip(id: id),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(
                  scale: 0.5 + 0.5 * t,
                  child: Transform.rotate(angle: (1 - t) * -0.6, child: child),
                ),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: CustomPaint(
                    painter: _SealPainter(status: booking.status),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _subheading,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final short = id.length > 8 ? id.substring(0, 8) : id;
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          AppHaptics.press();
          Clipboard.setData(ClipboardData(text: id));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking ID copied')));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${short.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(LucideIcons.copy, size: 13, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final service = booking.service;
    return _Card(
      child: Row(
        children: [
          BookingThumb(booking: booking, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 17,
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
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                BookingModeChip(mode: booking.mode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.title, this.color = Colors.white});

  final Widget child;
  final String? title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: TextStyle(
                color: AppColors.brandForest.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBubble(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.brandForest,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: AppColors.brandForest, size: 18),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              AppHaptics.press();
              onTap!();
            },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.brandForest,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            color: AppColors.mutedText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Soft concentric rings behind the hero seal.
class _HeroRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.08);
    for (var r = 70.0; r < size.width; r += 46) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroRingsPainter oldDelegate) => false;
}

/// Scalloped white seal with a status-coloured mark: tick for completed,
/// X for cancelled, clock otherwise.
class _SealPainter extends CustomPainter {
  const _SealPainter({required this.status});

  final BookingStatus status;

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
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);

    final markPaint = Paint()
      ..color = status.color
      ..strokeWidth = base * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    switch (status) {
      case BookingStatus.completed:
        canvas.drawLine(
          center + Offset(-base * .28, 0),
          center + Offset(-base * .06, base * .22),
          markPaint,
        );
        canvas.drawLine(
          center + Offset(-base * .06, base * .22),
          center + Offset(base * .31, -base * .20),
          markPaint,
        );
      case BookingStatus.cancelled:
        final arm = base * .24;
        canvas.drawLine(
          center + Offset(-arm, -arm),
          center + Offset(arm, arm),
          markPaint,
        );
        canvas.drawLine(
          center + Offset(-arm, arm),
          center + Offset(arm, -arm),
          markPaint,
        );
      case BookingStatus.confirmed || BookingStatus.inService:
        canvas.drawCircle(center, base * .30, markPaint);
        canvas.drawLine(center, center + Offset(0, -base * .17), markPaint);
        canvas.drawLine(
          center,
          center + Offset(base * .13, base * .08),
          markPaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _SealPainter oldDelegate) =>
      oldDelegate.status != status;
}

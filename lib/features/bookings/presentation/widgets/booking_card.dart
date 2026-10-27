import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/booking.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/service_visuals.dart';

/// Status colours and icons shared by the bookings list and detail page.
extension BookingStatusStyle on BookingStatus {
  Color get color => switch (this) {
    BookingStatus.confirmed => const Color(0xFF035864),
    BookingStatus.inService => const Color(0xFFB86E00),
    BookingStatus.completed => const Color(0xFF1F9D55),
    BookingStatus.cancelled => const Color(0xFFCE2E30),
  };

  Color get tint =>
      Color.alphaBlend(color.withValues(alpha: 0.10), Colors.white);

  IconData get icon => switch (this) {
    BookingStatus.confirmed => LucideIcons.calendarCheck,
    BookingStatus.inService => LucideIcons.wrench,
    BookingStatus.completed => LucideIcons.circleCheck,
    BookingStatus.cancelled => LucideIcons.circleX,
  };

  /// Index of the reached step in [BookingProgress] (0 booked, 1 at work,
  /// 2 done).
  int get step => switch (this) {
    BookingStatus.confirmed || BookingStatus.cancelled => 0,
    BookingStatus.inService => 1,
    BookingStatus.completed => 2,
  };
}

String rupees(int amount) => '₹$amount';

/// Booking row for the list: a tall tracker card while the booking is
/// active, a compact history card once it is completed or cancelled.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onRate,
  });

  final Booking booking;
  final VoidCallback onTap;

  /// Opens the rating sheet with the tapped star preselected.
  final ValueChanged<int>? onRate;

  @override
  Widget build(BuildContext context) {
    return booking.status.isActive
        ? _LiveCard(booking: booking, onTap: onTap)
        : _PastCard(booking: booking, onTap: onTap, onRate: onRate);
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final dark = Color.lerp(status.color, Colors.black, 0.32)!;
    return SpringPressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [status.color, dark],
          ),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: _Rings(color: Colors.white.withValues(alpha: 0.09)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _LiveDot(),
                                const SizedBox(width: 6),
                                Text(
                                  status.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          BookingModeChip(mode: booking.mode, onDark: true),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: BookingThumb(booking: booking, size: 58),
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
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock3,
                                      size: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        booking.slot,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    children: [
                      BookingProgress(status: status),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            rupees(booking.total),
                            style: const TextStyle(
                              color: AppColors.brandForest,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              booking.payment,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                            decoration: BoxDecoration(
                              color: status.color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Track',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final size in const [170.0, 120.0, 70.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.3),
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PastCard extends StatelessWidget {
  const _PastCard({required this.booking, required this.onTap, this.onRate});

  final Booking booking;
  final VoidCallback onTap;
  final ValueChanged<int>? onRate;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final cancelled = status == BookingStatus.cancelled;
    final canRate = status == BookingStatus.completed && onRate != null;
    return SpringPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  ColorFiltered(
                    colorFilter: cancelled
                        ? const ColorFilter.matrix(_greyscale)
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: BookingThumb(booking: booking, size: 56),
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
                          style: TextStyle(
                            color: AppColors.brandForest,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            decoration: cancelled
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          booking.slot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _StatusPill(status: status),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rupees(booking.total),
                        style: TextStyle(
                          color: cancelled
                              ? AppColors.mutedText
                              : AppColors.brandForest,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const _DashedLine(),
            if (canRate)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.customerRating == null
                            ? 'How was your pro?'
                            : 'You rated',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.brandForest,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (var star = 1; star <= 5; star++)
                      _StarButton(
                        star: star,
                        filled: star <= (booking.customerRating ?? 0),
                        onTap: () => onRate!(star),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                child: Row(
                  children: [
                    Icon(
                      cancelled ? LucideIcons.undo2 : LucideIcons.receiptText,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cancelled
                            ? 'Any amount paid goes back to the source'
                            : 'Invoice and visit details inside',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

const _greyscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 0.6, 0,
];

/// Receipt-style dashed separator.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 9).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < count; i++)
                Container(width: 5, height: 1, color: const Color(0xFFE2DED3)),
            ],
          );
        },
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.star,
    required this.filled,
    required this.onTap,
  });

  final int star;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$star star${star == 1 ? '' : 's'}',
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 22,
            color: filled ? AppColors.brandGold : const Color(0xFFCFCAB9),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
        color: status.tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingModeChip extends StatelessWidget {
  const BookingModeChip({super.key, required this.mode, this.onDark = false});

  final String mode;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final instant = mode == 'Instant';
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: instant
            ? AppColors.brandGold
            : (onDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFF1EFE8)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            instant ? LucideIcons.zap : LucideIcons.calendarClock,
            size: 12,
            color: instant || !onDark ? AppColors.brandForest : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            instant ? 'INSTANT' : 'SCHEDULED',
            style: TextStyle(
              color: instant || !onDark ? AppColors.brandForest : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded service photo for a booking.
class BookingThumb extends StatelessWidget {
  const BookingThumb({super.key, required this.booking, required this.size});

  final Booking booking;
  final double size;

  @override
  Widget build(BuildContext context) {
    final item = booking.service;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: SizedBox(
        width: size,
        height: size,
        child: ServicePhoto(
          service: item,
          accent: serviceAccent(item.title),
          iconSize: size * 0.44,
          cacheWidth: (size * 3).round(),
        ),
      ),
    );
  }
}

/// Three-step tracker: Booked → Pro at work → Done.
class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.status});

  final BookingStatus status;

  static const _labels = ['Booked', 'Pro at work', 'Done'];

  @override
  Widget build(BuildContext context) {
    final reached = status.step;
    final color = status.color;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              _Node(done: i <= reached, current: i == reached, color: color),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i < reached ? color : const Color(0xFFE9E6DD),
                    ),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: Text(
                  _labels[i],
                  textAlign: switch (i) {
                    0 => TextAlign.left,
                    1 => TextAlign.center,
                    _ => TextAlign.right,
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: i <= reached
                        ? AppColors.brandForest
                        : AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: i == reached
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.done, required this.current, required this.color});

  final bool done;
  final bool current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.white,
        border: Border.all(
          color: done ? color : const Color(0xFFD9D5CA),
          width: 2,
        ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: done && !current
          ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

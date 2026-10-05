import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/data/booking_mapper.dart';
import '../../../../core/models/api/api_booking.dart';
import '../../../../core/models/api/review.dart';
import '../../../../core/models/booking.dart';
import '../../../../core/services/api_exception.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/review_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';

/// Customer reviews: rate a completed booking
/// (`POST /reviews`) and browse a professional's
/// reviews (`GET /reviews/professional/{id}`).
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  List<Booking> _completed = const [];
  bool _isLoading = true;
  String? _error;

  Booking? _selectedBooking;
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  List<Review> _professionalReviews = const [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Completed bookings are the rateable set.
  Future<void> _loadCompleted() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bookings = await BookingService.instance.list();
      if (!mounted) return;
      setState(() {
        _completed = bookings
            .where((b) => b.status == ApiBookingStatus.completed)
            .map(mapApiBooking)
            .toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  /// `POST /reviews` — submit a rating for a
  /// completed booking.
  Future<void> _submitReview() async {
    final booking = _selectedBooking;
    if (booking == null || booking.id.isEmpty) {
      _showMessage('Pick a completed booking to rate.');
      return;
    }
    if (_rating == 0) {
      _showMessage('Tap the stars to rate your experience.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ReviewService.instance.create(
        bookingId: booking.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      AppHaptics.success();
      if (!mounted) return;
      _showMessage('Thanks! Your review is live.');
      setState(() {
        _rating = 0;
        _commentController.clear();
        _selectedBooking = null;
      });
      _loadCompleted();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// `GET /reviews/professional/{id}` — browse a
  /// professional's reviews.
  Future<void> _loadProfessionalReviews(String professionalId) async {
    setState(() {
      _isLoadingReviews = true;
      _professionalReviews = const [];
    });
    try {
      final reviews =
          await ReviewService.instance.listForProfessional(professionalId);
      if (!mounted) return;
      setState(() {
        _professionalReviews = reviews;
        _isLoadingReviews = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _professionalReviews = const [];
        _isLoadingReviews = false;
      });
      _showMessage(e.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandForest,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            const _SectionTitle('Rate a completed service'),
            const SizedBox(height: 12),
            _RateCard(
              completed: _completed,
              isLoading: _isLoading,
              error: _error,
              selected: _selectedBooking,
              rating: _rating,
              commentController: _commentController,
              isSubmitting: _isSubmitting,
              onSelect: (booking) {
                AppHaptics.tick();
                setState(() => _selectedBooking = booking);
              },
              onRate: (value) {
                AppHaptics.tick();
                setState(() => _rating = value);
              },
              onSubmit: _submitReview,
              onRetry: _loadCompleted,
            ),
            const SizedBox(height: 26),
            const _SectionTitle('Professional reviews'),
            const SizedBox(height: 12),
            _ProfessionalReviewsCard(
              reviews: _professionalReviews,
              isLoading: _isLoadingReviews,
              onLookup: _loadProfessionalReviews,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.brandForest,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.completed,
    required this.isLoading,
    required this.error,
    required this.selected,
    required this.rating,
    required this.commentController,
    required this.isSubmitting,
    required this.onSelect,
    required this.onRate,
    required this.onSubmit,
    required this.onRetry,
  });

  final List<Booking> completed;
  final bool isLoading;
  final String? error;
  final Booking? selected;
  final int rating;
  final TextEditingController commentController;
  final bool isSubmitting;
  final ValueChanged<Booking> onSelect;
  final ValueChanged<int> onRate;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.brandForest),
        ),
      );
    }

    if (error != null) {
      return _MessageBlock(
        icon: LucideIcons.wifiOff,
        text: error!,
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (completed.isEmpty) {
      return const _MessageBlock(
        icon: LucideIcons.badgeCheck,
        text: 'Completed services will appear here so you can rate them.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which service?',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final booking in completed)
                  ChoiceChip(
                    label: Text(
                      booking.service.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selected?.id == booking.id,
                    onSelected: (_) => onSelect(booking),
                    showCheckmark: false,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          const Text(
            'Your rating',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                GestureDetector(
                  onTap: () => onRate(star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      star <= rating
                          ? LucideIcons.star
                          : LucideIcons.star,
                      size: 34,
                      color: star <= rating
                          ? AppColors.brandGold
                          : const Color(0xFFD8D3C8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: commentController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What went well? (optional)',
              hintStyle: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAF7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.brandForest, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandForest,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalReviewsCard extends StatefulWidget {
  const _ProfessionalReviewsCard({
    required this.reviews,
    required this.isLoading,
    required this.onLookup,
  });

  final List<Review> reviews;
  final bool isLoading;
  final ValueChanged<String> onLookup;

  @override
  State<_ProfessionalReviewsCard> createState() =>
      _ProfessionalReviewsCardState();
}

class _ProfessionalReviewsCardState extends State<_ProfessionalReviewsCard> {
  final _idController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse a professional\'s reviews',
            style: TextStyle(
              color: AppColors.brandForest,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    hintText: 'Professional id',
                    hintStyle: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.brandForest,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _idController.text.trim().isEmpty
                      ? null
                      : () => widget.onLookup(_idController.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandForest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.brandForest,
                ),
              ),
            )
          else if (widget.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No reviews to show yet.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Column(
              children: [
                for (final review in widget.reviews) ...[
                  _ReviewTile(review: review),
                  if (review != widget.reviews.last)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: AppColors.borderSubtle),
                    ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.surfaceTint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.brandForest,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    Icon(
                      LucideIcons.star,
                      size: 13,
                      color: star <= review.rating
                          ? AppColors.brandGold
                          : const Color(0xFFD8D3C8),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      review.customerName ?? 'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brandForest,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (review.comment != null) ...[
                const SizedBox(height: 4),
                Text(
                  review.comment!,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({required this.icon, required this.text, this.actionLabel, this.onAction});

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: AppColors.mutedText, size: 32),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandForest,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

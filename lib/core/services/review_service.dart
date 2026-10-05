import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/review.dart';

/// Reviews module.
///
/// Customer-facing: submit a review for a completed booking and
/// browse a professional's reviews. The "list all reviews"
/// variant is admin-only and intentionally absent.
class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final _api = ApiClient.instance;

  /// `POST /reviews` — review a completed booking.
  ///
  /// The OpenAPI spec defines no request body schema; the
  /// conventional shape (bookingId + rating + optional comment)
  /// is sent.
  Future<Review> create({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final data = await _api.post(
      '/reviews',
      body: {
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected review response');
    }
    return Review.fromJson(data);
  }

  /// `GET /reviews/professional/{professionalId}` — paginated
  /// reviews for a professional (public).
  Future<List<Review>> listForProfessional(String professionalId) async {
    final data = await _api.get(
      '/reviews/professional/$professionalId',
    );
    return parseReviewList(data);
  }
}

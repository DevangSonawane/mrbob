import 'dart:async';

import 'api_client.dart';
import 'api_exception.dart';
import '../models/api/booking_draft.dart';

/// Booking assistant — turns the customer's own words into a booking
/// draft via `POST /bookings/draft`. Nothing is booked by this call.
class BookingAssistantService {
  BookingAssistantService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  static final BookingAssistantService instance = BookingAssistantService();

  static const minMessageLength = 3;
  static const maxMessageLength = 2000;
  static const timeout = Duration(seconds: 15);

  final ApiClient _api;

  /// `POST /bookings/draft`.
  ///
  /// A timeout or network failure is reported the same way as the server's
  /// 503 `ASSISTANT_UNAVAILABLE`, so callers handle one fallback path.
  Future<BookingDraft> draft({
    required String message,
    DraftSource source = DraftSource.text,
    List<DraftAnswer> answers = const [],
  }) async {
    dynamic data;
    try {
      data = await _api
          .post(
            '/bookings/draft',
            body: {
              'message': message,
              'source': source.value,
              if (answers.isNotEmpty)
                'answers': answers.take(4).map((a) => a.toJson()).toList(),
            },
          )
          .timeout(timeout);
    } on ApiException {
      rethrow;
    } catch (_) {
      // TimeoutException, SocketException, ClientException…
      throw const ApiException(
        'The assistant is not responding right now.',
        statusCode: 503,
        code: 'ASSISTANT_UNAVAILABLE',
      );
    }
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Sorry, we couldn\'t understand that.',
        statusCode: 422,
        code: 'ASSISTANT_NO_DRAFT',
      );
    }
    return BookingDraft.fromJson(data);
  }
}

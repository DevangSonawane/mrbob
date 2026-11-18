import 'service_category.dart';

/// What `POST /bookings/draft` decided about the customer's message.
enum BookingDraftStatus {
  /// A service was picked and the draft can be confirmed as is.
  ready,

  /// The assistant is unsure — show [BookingDraft.questions] and the
  /// service options.
  needsInfo,

  /// None of the services fits the message.
  notOffered;

  static BookingDraftStatus parse(String? value) => switch (value) {
    'READY' => BookingDraftStatus.ready,
    'NOT_OFFERED' => BookingDraftStatus.notOffered,
    _ => BookingDraftStatus.needsInfo,
  };
}

enum BookingUrgency {
  emergency,
  soon,
  flexible;

  static BookingUrgency? parse(String? value) => switch (value) {
    'EMERGENCY' => BookingUrgency.emergency,
    'SOON' => BookingUrgency.soon,
    'FLEXIBLE' => BookingUrgency.flexible,
    _ => null,
  };
}

/// How the message was entered. `VOICE` lets the assistant allow for
/// transcription mistakes.
enum DraftSource {
  text('TEXT'),
  voice('VOICE');

  const DraftSource(this.value);

  final String value;
}

/// One answer to a `NEEDS_INFO` question, re-sent on the next draft call.
class DraftAnswer {
  const DraftAnswer(this.question, this.answer);

  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

/// Response of `POST /bookings/draft`. Nothing is booked yet — the
/// customer reviews this and then books with `POST /bookings`.
class BookingDraft {
  const BookingDraft({
    required this.status,
    this.service,
    this.alternatives = const [],
    this.description,
    this.urgency,
    this.suggestedScheduledAt,
    this.questions = const [],
    this.safetyAdvice,
    this.price,
  });

  final BookingDraftStatus status;
  final ServiceCategory? service;
  final List<ServiceCategory> alternatives;
  final String? description;
  final BookingUrgency? urgency;

  /// UTC from the server; shown and edited in local time.
  final DateTime? suggestedScheduledAt;
  final List<String> questions;
  final String? safetyAdvice;
  final int? price;

  factory BookingDraft.fromJson(Map<String, dynamic> json) {
    final serviceJson = json['service'];
    final alternativesJson = json['alternatives'];
    final questionsJson = json['questions'];
    final advice = json['safetyAdvice']?.toString().trim();
    return BookingDraft(
      status: BookingDraftStatus.parse(json['status']?.toString()),
      service: serviceJson is Map<String, dynamic>
          ? ServiceCategory.fromJson(serviceJson)
          : null,
      alternatives: alternativesJson is List
          ? alternativesJson
                .whereType<Map<String, dynamic>>()
                .map(ServiceCategory.fromJson)
                .toList()
          : const [],
      description: json['description']?.toString(),
      urgency: BookingUrgency.parse(json['urgency']?.toString()),
      suggestedScheduledAt: DateTime.tryParse(
        json['suggestedScheduledAt']?.toString() ?? '',
      ),
      questions: questionsJson is List
          ? questionsJson
                .map((q) => q?.toString() ?? '')
                .where((q) => q.trim().isNotEmpty)
                .toList()
          : const [],
      safetyAdvice: advice == null || advice.isEmpty ? null : advice,
      price: json['price'] is num
          ? (json['price'] as num).toInt()
          : int.tryParse(json['price']?.toString() ?? ''),
    );
  }
}

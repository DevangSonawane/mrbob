class DisputeCategory {
  const DisputeCategory({required this.key, required this.label});
  final String key;
  final String label;
  factory DisputeCategory.fromJson(Map<String, dynamic> json) =>
      DisputeCategory(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
      );
}

class CustomerDispute {
  const CustomerDispute({
    required this.id,
    required this.reference,
    required this.type,
    required this.category,
    required this.categoryLabel,
    required this.subject,
    required this.description,
    required this.status,
    required this.messageCount,
    required this.canReply,
    required this.canClose,
    this.resolution,
    this.bookingId,
    this.bookingNumber,
    this.serviceName,
    this.messages = const [],
  });
  final String id,
      reference,
      type,
      category,
      categoryLabel,
      subject,
      description,
      status;
  final int messageCount;
  final bool canReply, canClose;
  final String? resolution, bookingId, bookingNumber, serviceName;
  final List<DisputeMessage> messages;

  factory CustomerDispute.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'];
    final actions = json['actions'];
    final rawMessages = json['messages'];
    return CustomerDispute(
      id: json['id']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DISPUTE',
      category: json['category']?.toString() ?? '',
      categoryLabel: json['categoryLabel']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      canReply: actions is Map<String, dynamic> && actions['canReply'] == true,
      canClose: actions is Map<String, dynamic> && actions['canClose'] == true,
      resolution: json['resolution']?.toString(),
      bookingId: booking is Map<String, dynamic>
          ? booking['id']?.toString()
          : null,
      bookingNumber: booking is Map<String, dynamic>
          ? booking['bookingNumber']?.toString()
          : null,
      serviceName:
          booking is Map<String, dynamic> &&
              booking['service'] is Map<String, dynamic>
          ? (booking['service'] as Map<String, dynamic>)['name']?.toString()
          : null,
      messages: rawMessages is List
          ? rawMessages
                .whereType<Map<String, dynamic>>()
                .map(DisputeMessage.fromJson)
                .toList()
          : const [],
    );
  }
}

class DisputeMessage {
  const DisputeMessage({
    required this.id,
    required this.body,
    required this.mine,
    this.authorName,
  });
  final String id, body;
  final bool mine;
  final String? authorName;
  factory DisputeMessage.fromJson(Map<String, dynamic> json) => DisputeMessage(
    id: json['id']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    mine: json['mine'] == true,
    authorName: json['authorName']?.toString(),
  );
}

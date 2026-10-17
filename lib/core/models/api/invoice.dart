/// Customer invoice returned for a completed booking.
class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.items,
    this.issuedAt,
    this.payment,
    this.pdfPath,
  });

  final String id;
  final String invoiceNumber;
  final String status;
  final String currency;
  final num subtotal;
  final num tax;
  final num total;
  final List<InvoiceItem> items;
  final DateTime? issuedAt;
  final InvoicePayment? payment;
  final String? pdfPath;

  bool get isPaid => status.toUpperCase() == 'PAID';
  num get balanceDue => total - (payment?.amountPaid ?? 0);

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InvoiceItem.fromJson)
        .toList();
    final paymentJson = json['payment'];
    return Invoice(
      id: (json['id'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      status: (json['status'] ?? 'UNPAID').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      subtotal: _number(json['subtotal']),
      tax: _number(json['tax']),
      total: _number(json['total']),
      items: items,
      issuedAt: DateTime.tryParse((json['issuedAt'] ?? '').toString()),
      payment: paymentJson is Map<String, dynamic>
          ? InvoicePayment.fromJson(paymentJson)
          : null,
      pdfPath: json['pdf']?.toString(),
    );
  }
}

class InvoiceItem {
  const InvoiceItem({required this.description, required this.amount});
  final String description;
  final num amount;
  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    description: (json['description'] ?? 'Service').toString(),
    amount: _number(json['amount']),
  );
}

class InvoicePayment {
  const InvoicePayment({required this.amountPaid, this.mode, this.method});
  final num amountPaid;
  final String? mode;
  final String? method;
  factory InvoicePayment.fromJson(Map<String, dynamic> json) => InvoicePayment(
    amountPaid: _number(json['amountPaid']),
    mode: json['mode']?.toString(),
    method: json['method']?.toString(),
  );
}

num _number(dynamic value) =>
    value is num ? value : num.tryParse('$value') ?? 0;

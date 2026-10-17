import '../models/api/invoice.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Customer invoices are issued only once a booking is completed.
class InvoiceService {
  InvoiceService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  static final InvoiceService instance = InvoiceService();
  final ApiClient _api;

  Future<Invoice> getForBooking(String bookingId) async {
    final data = await _api.get('/customer/bookings/$bookingId/invoice');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected invoice response');
    }
    return Invoice.fromJson(data);
  }

  Future<List<int>> downloadPdf(String bookingId) =>
      _api.getBytes('/customer/bookings/$bookingId/invoice/pdf');
}

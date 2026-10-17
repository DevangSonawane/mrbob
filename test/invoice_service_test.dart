import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/api_config.dart';
import 'package:mrbob/core/services/invoice_service.dart';

void main() {
  test(
    'InvoiceService fetches and parses a completed booking invoice',
    () async {
      http.Request? request;
      final service = InvoiceService(
        api: ApiClient(
          client: MockClient((value) async {
            request = value;
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 'invoice-1',
                  'invoiceNumber': 'INV-000042',
                  'status': 'UNPAID',
                  'subtotal': 349,
                  'tax': 0,
                  'total': 349,
                  'items': [
                    {'description': 'Plumber', 'amount': 349},
                  ],
                  'payment': {'mode': 'PAY_AFTER_SERVICE', 'amountPaid': 0},
                },
              }),
              200,
            );
          }),
        ),
      );

      final invoice = await service.getForBooking('booking-1');

      expect(
        request?.url.toString(),
        '${ApiConfig.effectiveBaseUrl}/customer/bookings/booking-1/invoice',
      );
      expect(invoice.invoiceNumber, 'INV-000042');
      expect(invoice.balanceDue, 349);
      expect(invoice.payment?.mode, 'PAY_AFTER_SERVICE');
    },
  );
}

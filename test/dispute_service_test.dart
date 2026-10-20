import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mrbob/core/services/api_client.dart';
import 'package:mrbob/core/services/api_config.dart';
import 'package:mrbob/core/services/dispute_service.dart';

void main() {
  test('DisputeService sends customer help and dispute requests', () async {
    final requests = <http.Request>[];
    final service = DisputeService(
      api: ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/categories')) {
            return _json({
              'success': true,
              'data': [
                {'key': 'REFUND', 'label': 'A refund'},
              ],
            });
          }
          if (request.method == 'GET') {
            if (request.url.path.endsWith('/disputes'))
              return _json({
                'success': true,
                'items': [_dispute()],
              });
            return _json({'success': true, 'data': _dispute(messages: true)});
          }
          return _json({'success': true, 'data': _dispute(messages: true)});
        }),
      ),
    );
    final categories = await service.categories();
    final created = await service.create(
      type: 'DISPUTE',
      category: 'REFUND',
      subject: ' Refund missing ',
      description: ' Still waiting ',
      bookingId: 'booking-1',
    );
    final listed = await service.list(status: 'OPEN', type: 'DISPUTE');
    final detail = await service.get('dispute-1');
    await service.reply('dispute-1', ' Please update me ');
    await service.close('dispute-1');

    expect(categories.single.key, 'REFUND');
    expect(created.id, 'dispute-1');
    expect(listed.single.reference, 'DSP-000042');
    expect(detail.messages.single.body, 'Support reply');
    expect(
      requests[0].url.toString(),
      '${ApiConfig.effectiveBaseUrl}/customer/disputes/categories',
    );
    expect(requests[1].method, 'POST');
    expect(jsonDecode(requests[1].body), {
      'type': 'DISPUTE',
      'category': 'REFUND',
      'subject': 'Refund missing',
      'description': 'Still waiting',
      'bookingId': 'booking-1',
    });
    expect(requests[2].url.queryParameters, {
      'page': '1',
      'limit': '20',
      'status': 'OPEN',
      'type': 'DISPUTE',
    });
    expect(
      requests[4].url.path,
      '/api/v1/customer/disputes/dispute-1/messages',
    );
    expect(jsonDecode(requests[4].body), {'message': 'Please update me'});
    expect(requests[5].url.path, '/api/v1/customer/disputes/dispute-1/close');
  });
}

Map<String, dynamic> _dispute({bool messages = false}) => {
  'id': 'dispute-1',
  'reference': 'DSP-000042',
  'type': 'DISPUTE',
  'category': 'REFUND',
  'categoryLabel': 'A refund',
  'subject': 'Refund missing',
  'description': 'Still waiting',
  'status': 'OPEN',
  'messageCount': messages ? 1 : 0,
  'actions': {'canReply': true, 'canClose': true},
  if (messages)
    'messages': [
      {
        'id': 'message-1',
        'body': 'Support reply',
        'mine': false,
        'authorName': 'Support',
      },
    ],
};
http.Response _json(Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

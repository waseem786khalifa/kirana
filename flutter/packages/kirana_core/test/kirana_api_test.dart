import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_core/kirana_core.dart';

void main() {
  test(
    'decodes data envelopes and emits snake_case query parameters',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seenUri = Completer<Uri>();
      server.listen((request) async {
        seenUri.complete(request.uri);
        await _jsonResponse(request.response, {
          'data': [
            {
              'id': 11,
              'store_id': 7,
              'name_en': 'Atta',
              'name_hi': 'आटा',
              'name_mrw': 'Aato',
              'category': 'Staples',
              'pack_size': '5 kg',
              'mrp': 260,
              'selling_price': 240,
              'stock': 12,
              'image': '',
              'available_for_online': true,
              'is_hidden': false,
            },
          ],
          'meta': {'count': 1},
        });
      });
      final api = KiranaApi(baseUrl: 'http://127.0.0.1:${server.port}/api');

      try {
        final products = await api.getProducts(
          storeId: 7,
          availableOnline: true,
        );
        final uri = await seenUri.future;

        expect(uri.path, '/api/products');
        expect(uri.queryParameters['store_id'], '7');
        expect(uri.queryParameters['available_online'], '1');
        expect(products.single.nameEn, 'Atta');
        expect(products.single.sellingPrice, 240);
      } finally {
        api.close(force: true);
        await server.close(force: true);
      }
    },
  );

  test('maps structured backend errors to ApiException', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await _jsonResponse(request.response, {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Please correct the highlighted fields.',
          'details': {
            'mobile': ['Mobile must contain 10 digits.'],
          },
        },
      }, statusCode: HttpStatus.unprocessableEntity);
    });
    final api = KiranaApi(baseUrl: 'http://127.0.0.1:${server.port}');

    try {
      await expectLater(
        api.getCustomers(storeId: 7),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having((error) => error.code, 'code', 'VALIDATION_ERROR')
              .having((error) => error.messagesFor('mobile'), 'mobile errors', [
                'Mobile must contain 10 digits.',
              ]),
        ),
      );
    } finally {
      api.close(force: true);
      await server.close(force: true);
    }
  });

  test('login stores bearer token for subsequent requests', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final loginBody = Completer<Map<String, dynamic>>();
    final authorization = Completer<String?>();
    server.listen((request) async {
      if (request.uri.path == '/delivery-staff/login') {
        loginBody.complete(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        await _jsonResponse(request.response, {
          'data': {
            'token': 'signed-token',
            'token_type': 'Bearer',
            'expires_at': '2026-08-09T10:00:00Z',
            'staff': {
              'id': 8,
              'store_id': 7,
              'name': 'Mohan',
              'mobile': '9876543210',
              'is_active': true,
              'assigned_orders_count': 2,
              'cash_collected_today': 450,
            },
          },
        });
        return;
      }

      authorization.complete(
        request.headers.value(HttpHeaders.authorizationHeader),
      );
      await _jsonResponse(request.response, {'data': <Object?>[]});
    });
    final api = KiranaApi(baseUrl: 'http://127.0.0.1:${server.port}');

    try {
      final login = await api.loginDeliveryStaff(
        storeId: 7,
        mobile: '9876543210',
        pin: '1234',
      );
      await api.getOrders(deliveryStaffId: login.staff.id);

      expect(login.staff.name, 'Mohan');
      expect(api.bearerToken, 'signed-token');
      expect(await loginBody.future, {
        'store_id': 7,
        'mobile': '9876543210',
        'pin': '1234',
      });
      expect(await authorization.future, 'Bearer signed-token');
    } finally {
      api.close(force: true);
      await server.close(force: true);
    }
  });
}

Future<void> _jsonResponse(
  HttpResponse response,
  Object body, {
  int statusCode = HttpStatus.ok,
}) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

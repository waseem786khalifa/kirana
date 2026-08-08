import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_exception.dart';
import 'enums.dart';
import 'json_utils.dart';
import 'models.dart';

class KiranaApi {
  KiranaApi({
    String? baseUrl,
    String? bearerToken,
    this.timeout = const Duration(seconds: 15),
    HttpClient? httpClient,
  }) : _baseUri = _parseBaseUrl(baseUrl ?? defaultBaseUrl),
       _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null {
    this.bearerToken = bearerToken;
  }

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2/kirana_api/public',
  );

  final Uri _baseUri;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  final Duration timeout;
  String? _bearerToken;
  bool _closed = false;

  String get baseUrl => _baseUri.toString();

  String? get bearerToken => _bearerToken;

  set bearerToken(String? value) {
    _bearerToken = value?.trim().isEmpty ?? true ? null : value!.trim();
  }

  Future<bool> healthCheck() async {
    final data = await _request('GET', const ['health']);
    final health = jsonMap(data, context: 'health response');
    return stringValue(health['status']).toLowerCase() == 'ok';
  }

  Future<List<Store>> getStores({bool? nearby, String? pincode}) async {
    final data = await _request(
      'GET',
      const ['stores'],
      query: {'nearby': nearby, 'pincode': pincode},
    );
    return _decodeList(data, Store.fromJson, context: 'stores');
  }

  Future<Store> getStoreByCode(String code) async {
    final data = await _request('GET', ['stores', 'by-code', code]);
    return Store.fromJson(jsonMap(data, context: 'store'));
  }

  Future<List<Product>> getProducts({
    required int storeId,
    bool? availableOnline,
  }) async {
    final data = await _request(
      'GET',
      const ['products'],
      query: {'store_id': storeId, 'available_online': availableOnline},
    );
    return _decodeList(data, Product.fromJson, context: 'products');
  }

  Future<Product> createProduct(Map<String, dynamic> product) async {
    final data = await _request('POST', const ['products'], body: product);
    return Product.fromJson(jsonMap(data, context: 'product'));
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> product) async {
    final data = await _request('PUT', ['products', '$id'], body: product);
    return Product.fromJson(jsonMap(data, context: 'product'));
  }

  Future<List<Customer>> getCustomers({
    required int storeId,
    String? mobile,
  }) async {
    final data = await _request(
      'GET',
      const ['customers'],
      query: {'store_id': storeId, 'mobile': mobile},
    );
    return _decodeList(data, Customer.fromJson, context: 'customers');
  }

  Future<List<Order>> getOrders({
    int? storeId,
    String? customerPhone,
    int? deliveryStaffId,
    OrderStatus? status,
  }) async {
    final data = await _request(
      'GET',
      const ['orders'],
      query: {
        'store_id': storeId,
        'customer_phone': customerPhone,
        'delivery_staff_id': deliveryStaffId,
        'status': status?.apiValue,
      },
    );
    return _decodeList(data, Order.fromJson, context: 'orders');
  }

  Future<Order> getOrder(int id) async {
    final data = await _request('GET', ['orders', '$id']);
    return Order.fromJson(jsonMap(data, context: 'order'));
  }

  Future<Order> createOrder(CreateOrderRequest order) async {
    final data = await _request('POST', const ['orders'], body: order.toJson());
    return Order.fromJson(jsonMap(data, context: 'order'));
  }

  Future<Order> updateOrderStatus(
    int id,
    OrderStatus status, {
    int? deliveryStaffId,
    String? rejectionReason,
  }) async {
    final body = <String, dynamic>{'status': status.apiValue};
    if (deliveryStaffId != null) {
      body['delivery_staff_id'] = deliveryStaffId;
    }
    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      body['rejection_reason'] = rejectionReason;
    }
    final data = await _request('PATCH', [
      'orders',
      '$id',
      'status',
    ], body: body);
    return Order.fromJson(jsonMap(data, context: 'order'));
  }

  Future<List<DeliveryStaff>> getDeliveryStaff({required int storeId}) async {
    final data = await _request(
      'GET',
      const ['delivery-staff'],
      query: {'store_id': storeId},
    );
    return _decodeList(data, DeliveryStaff.fromJson, context: 'delivery staff');
  }

  Future<DeliveryLoginResult> loginDeliveryStaff({
    int? storeId,
    required String mobile,
    required String pin,
  }) async {
    final body = <String, dynamic>{'mobile': mobile, 'pin': pin};
    if (storeId != null) body['store_id'] = storeId;
    final data = await _request('POST', const [
      'delivery-staff',
      'login',
    ], body: body);
    final result = DeliveryLoginResult.fromJson(
      jsonMap(data, context: 'delivery login'),
    );
    bearerToken = result.token;
    return result;
  }

  Future<DeliveryStaff> createDeliveryStaff(Map<String, dynamic> staff) async {
    final data = await _request('POST', const ['delivery-staff'], body: staff);
    return DeliveryStaff.fromJson(jsonMap(data, context: 'delivery staff'));
  }

  Future<List<KhataEntry>> getKhata({
    required int storeId,
    int? customerId,
  }) async {
    final data = await _request(
      'GET',
      const ['khata'],
      query: {'store_id': storeId, 'customer_id': customerId},
    );
    return _decodeList(data, KhataEntry.fromJson, context: 'khata entries');
  }

  Future<KhataEntry> addKhataPayment({
    required int storeId,
    required int customerId,
    required double amount,
    String? note,
  }) async {
    final data = await _request(
      'POST',
      const ['khata'],
      body: {
        'store_id': storeId,
        'customer_id': customerId,
        'type': KhataEntryType.credit.apiValue,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return KhataEntry.fromJson(jsonMap(data, context: 'khata entry'));
  }

  Future<ReportSummary> getReports({
    required int storeId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final data = await _request(
      'GET',
      const ['reports'],
      query: {
        'store_id': storeId,
        'date_from': dateFrom == null ? null : _dateOnly(dateFrom),
        'date_to': dateTo == null ? null : _dateOnly(dateTo),
      },
    );
    return ReportSummary.fromJson(jsonMap(data, context: 'report'));
  }

  void close({bool force = false}) {
    if (_closed) return;
    _closed = true;
    if (_ownsHttpClient) _httpClient.close(force: force);
  }

  Future<Object?> _request(
    String method,
    List<String> pathSegments, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    if (_closed) {
      throw StateError('KiranaApi has already been closed.');
    }

    final uri = _buildUri(pathSegments, query);
    try {
      final request = await _httpClient.openUrl(method, uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      final token = _bearerToken;
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decoder
          .bind(response)
          .join()
          .timeout(timeout);
      final decoded = _decodeResponseBody(
        responseText,
        response.statusCode,
        uri,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _apiError(response.statusCode, decoded, uri);
      }
      return _unwrapData(decoded);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        code: 'TIMEOUT',
        message: 'The server did not respond in time.',
        uri: uri,
        cause: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'Unable to connect to the server.',
        uri: uri,
        cause: error,
      );
    } on HandshakeException catch (error) {
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'A secure connection to the server could not be established.',
        uri: uri,
        cause: error,
      );
    } on HttpException catch (error) {
      throw ApiException(
        code: 'NETWORK_ERROR',
        message: error.message,
        uri: uri,
        cause: error,
      );
    } on FormatException catch (error) {
      throw ApiException(
        code: 'INVALID_RESPONSE',
        message: error.message,
        uri: uri,
        cause: error,
      );
    }
  }

  Object? _decodeResponseBody(String body, int statusCode, Uri uri) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException catch (error) {
      throw ApiException(
        code: 'INVALID_RESPONSE',
        message: 'Server returned malformed JSON.',
        statusCode: statusCode,
        uri: uri,
        cause: error,
      );
    }
  }

  Object? _unwrapData(Object? decoded) {
    if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
    return decoded;
  }

  ApiException _apiError(int statusCode, Object? decoded, Uri uri) {
    var code = _defaultErrorCode(statusCode);
    var message = 'Request failed with status $statusCode.';
    var details = <String, dynamic>{};

    if (decoded is Map) {
      final envelope = jsonMap(decoded);
      final rawError = envelope['error'];
      if (rawError is Map) {
        final error = jsonMap(rawError, context: 'error');
        code = stringValue(error['code'], fallback: code);
        message = stringValue(error['message'], fallback: message);
        if (error['details'] is Map) {
          details = jsonMap(error['details'], context: 'error details');
        }
      } else {
        code = stringValue(envelope['code'], fallback: code);
        message = stringValue(envelope['message'], fallback: message);
        if (envelope['details'] is Map) {
          details = jsonMap(envelope['details'], context: 'error details');
        }
      }
    }

    return ApiException(
      code: code,
      message: message,
      statusCode: statusCode,
      uri: uri,
      details: details,
    );
  }

  Uri _buildUri(List<String> pathSegments, Map<String, Object?> query) {
    final queryParameters = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null || (value is String && value.trim().isEmpty)) continue;
      queryParameters[entry.key] = value is bool
          ? (value ? '1' : '0')
          : value.toString();
    }

    return _baseUri.replace(
      pathSegments: [
        ..._baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        ...pathSegments,
      ],
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      fragment: '',
    );
  }

  static Uri _parseBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'Must be an absolute HTTP or HTTPS URL.',
      );
    }
    return uri.replace(query: null, fragment: '');
  }
}

List<T> _decodeList<T>(
  Object? data,
  T Function(JsonMap json) decode, {
  required String context,
}) {
  return List.unmodifiable(
    jsonList(
      data,
      context: context,
    ).map((item) => decode(jsonMap(item, context: '$context item'))),
  );
}

String _defaultErrorCode(int statusCode) => switch (statusCode) {
  400 || 422 => 'VALIDATION_ERROR',
  401 || 403 => 'UNAUTHORIZED',
  404 => 'NOT_FOUND',
  409 => 'CONFLICT',
  _ => 'HTTP_ERROR',
};

String _dateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

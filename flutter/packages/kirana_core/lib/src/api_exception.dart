import 'dart:collection';

/// A typed failure returned by [KiranaApi] or its underlying transport.
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.uri,
    Map<String, dynamic>? details,
    this.cause,
  }) : details = UnmodifiableMapView(details ?? const {});

  final String code;
  final String message;
  final int? statusCode;
  final Uri? uri;
  final Map<String, dynamic> details;
  final Object? cause;

  bool get isNetworkError => code == 'NETWORK_ERROR' || code == 'TIMEOUT';
  bool get isUnauthorized => statusCode == 401 || code == 'UNAUTHORIZED';
  bool get isValidationError => statusCode == 422 || code == 'VALIDATION_ERROR';
  bool get isNotFound => statusCode == 404 || code == 'NOT_FOUND';
  bool get isConflict => statusCode == 409 || code == 'CONFLICT';

  List<String> messagesFor(String field) {
    final value = details[field];
    if (value is List) return value.map((item) => item.toString()).toList();
    if (value == null) return const [];
    return [value.toString()];
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$status [$code]: $message';
  }
}

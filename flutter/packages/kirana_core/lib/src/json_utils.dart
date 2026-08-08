typedef JsonMap = Map<String, dynamic>;

JsonMap jsonMap(Object? value, {String context = 'value'}) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw FormatException('Expected $context to be a JSON object.');
}

List<Object?> jsonList(Object? value, {String context = 'value'}) {
  if (value is List) return value.cast<Object?>();
  throw FormatException('Expected $context to be a JSON array.');
}

String stringValue(Object? value, {String fallback = ''}) {
  return value == null ? fallback : value.toString();
}

int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? nullableIntValue(Object? value) {
  if (value == null || value == '') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? nullableDoubleValue(Object? value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' || 'yes' || 'y' => true,
      'false' || '0' || 'no' || 'n' => false,
      _ => fallback,
    };
  }
  return fallback;
}

DateTime? dateTimeValue(Object? value) {
  if (value == null || value == '') return null;
  return DateTime.tryParse(value.toString());
}

Object? firstPresent(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  return null;
}

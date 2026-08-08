abstract final class KiranaFormatters {
  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String currency(
    num amount, {
    int decimalDigits = 0,
    String symbol = '₹',
  }) {
    final negative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final grouped = _indianGrouping(parts.first);
    final decimals = parts.length == 2 ? '.${parts.last}' : '';
    return '${negative ? '-' : ''}$symbol$grouped$decimals';
  }

  static String compactCurrency(num amount, {String symbol = '₹'}) {
    final absolute = amount.abs();
    final prefix = amount < 0 ? '-$symbol' : symbol;
    if (absolute >= 10000000) {
      return '$prefix${_trimDecimal(absolute / 10000000)}Cr';
    }
    if (absolute >= 100000) {
      return '$prefix${_trimDecimal(absolute / 100000)}L';
    }
    if (absolute >= 1000) {
      return '$prefix${_trimDecimal(absolute / 1000)}K';
    }
    return currency(amount, symbol: symbol);
  }

  static String date(DateTime? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    return '${value.day.toString().padLeft(2, '0')} '
        '${_shortMonths[value.month - 1]} ${value.year}';
  }

  static String dateTime(DateTime? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '${date(value)} · $hour:$minute $period';
  }

  static String phone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    if (digits.length != 10) return value;
    return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
  }

  static String orderNumber(Object value) {
    final normalized = value.toString().trim();
    return normalized.startsWith('#') ? normalized : '#$normalized';
  }

  static String distance(num kilometers) {
    if (kilometers < 1) return '${(kilometers * 1000).round()} m';
    return '${_trimDecimal(kilometers)} km';
  }

  static String _indianGrouping(String digits) {
    if (digits.length <= 3) return digits;
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    return '${groups.join(',')},$tail';
  }

  static String _trimDecimal(num value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}

String formatCurrency(
  num amount, {
  int decimalDigits = 0,
  String symbol = '₹',
}) => KiranaFormatters.currency(
  amount,
  decimalDigits: decimalDigits,
  symbol: symbol,
);

String formatCompactCurrency(num amount, {String symbol = '₹'}) =>
    KiranaFormatters.compactCurrency(amount, symbol: symbol);

String formatDate(DateTime? value, {String fallback = '—'}) =>
    KiranaFormatters.date(value, fallback: fallback);

String formatDateTime(DateTime? value, {String fallback = '—'}) =>
    KiranaFormatters.dateTime(value, fallback: fallback);

String formatPhone(String value) => KiranaFormatters.phone(value);

String formatOrderNumber(Object value) => KiranaFormatters.orderNumber(value);

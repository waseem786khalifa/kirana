import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_core/kirana_core.dart';

void main() {
  test('formats Indian currency and customer-facing values', () {
    expect(formatCurrency(1234567), '₹12,34,567');
    expect(formatCurrency(-42.5, decimalDigits: 2), '-₹42.50');
    expect(formatCompactCurrency(250000), '₹2.5L');
    expect(formatCompactCurrency(-125000), '-₹1.3L');
    expect(formatPhone('919876543210'), '+91 98765 43210');
    expect(formatOrderNumber('KS1001'), '#KS1001');
    expect(formatDate(DateTime(2026, 8, 8)), '08 Aug 2026');
  });

  test('KiranaTheme exposes Material 3 light and dark themes', () {
    expect(KiranaTheme.lightTheme.useMaterial3, isTrue);
    expect(KiranaTheme.lightTheme.brightness, Brightness.light);
    expect(KiranaTheme.darkTheme.useMaterial3, isTrue);
    expect(KiranaTheme.darkTheme.brightness, Brightness.dark);
  });
}

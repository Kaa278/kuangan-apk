import 'package:flutter_test/flutter_test.dart';
import 'package:kuangan/shared/utils/currency.dart';

void main() {
  group('Currency Formatting Tests', () {
    test('formatIDR formats correctly without compact', () {
      expect(formatIDR(1000), 'Rp 1.000');
      expect(formatIDR(500000), 'Rp 500.000');
      expect(formatIDR(0), 'Rp 0');
    });

    test('formatIDR formats correctly with compact', () {
      expect(formatIDR(1500000, compact: true), 'Rp 1.5jt');
      expect(formatIDR(2000000, compact: true), 'Rp 2jt');
      expect(formatIDR(500000, compact: true), 'Rp 500.000'); // < 1M
    });

    test('formatIDRSigned formats with correct signs', () {
      expect(formatIDRSigned(150000), '+Rp 150.000');
      expect(formatIDRSigned(-50000), '-Rp 50.000');
      expect(formatIDRSigned(0), '+Rp 0');
    });
  });
}

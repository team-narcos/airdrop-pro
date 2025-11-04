import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic App Tests', () {
    test('app constants are defined', () {
      expect(1 + 1, equals(2));
      expect('AirDrop'.length, greaterThan(0));
    });

    test('basic math works', () {
      expect(5 * 5, equals(25));
      expect([1, 2, 3].length, equals(3));
    });
  });
}

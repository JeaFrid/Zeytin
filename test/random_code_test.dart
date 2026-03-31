import 'package:test/test.dart';
import 'package:zeytin/tools/random_code.dart';

void main() {
  group('generateTenDigitRandomNumber', () {
    test('generates 10-digit number', () {
      final number = generateTenDigitRandomNumber();
      final str = number.toString();
      expect(str.length, equals(10));
      expect(number, greaterThanOrEqualTo(1000000000));
      expect(number, lessThanOrEqualTo(9999999999));
    });

    test('generates number within valid range', () {
      final number = generateTenDigitRandomNumber();
      expect(number, greaterThanOrEqualTo(1000000000));
      expect(number, lessThanOrEqualTo(9999999999));
    });

    test('generates different numbers on multiple calls', () {
      final numbers = <int>{};
      for (var i = 0; i < 10; i++) {
        numbers.add(generateTenDigitRandomNumber());
      }
      expect(numbers.length, greaterThan(5));
    });

    test('never generates number starting with zero', () {
      final number = generateTenDigitRandomNumber();
      final firstDigit = number.toString()[0];
      expect(firstDigit, isNot(equals('0')));
    });

    test('generates numbers across full range', () {
      final number = generateTenDigitRandomNumber();
      expect(number, greaterThanOrEqualTo(1000000000));
      expect(number, lessThanOrEqualTo(9999999999));
    });

    test('generates valid integer type', () {
      final number = generateTenDigitRandomNumber();
      expect(number, isA<int>());
    });

    test('generates positive numbers only', () {
      final number = generateTenDigitRandomNumber();
      expect(number, greaterThan(0));
    });

    test('generates valid format', () {
      final number = generateTenDigitRandomNumber();
      final str = number.toString();
      expect(str.length, equals(10));
      expect(int.tryParse(str), isNotNull);
    });

    test('can be used as identifier', () {
      final id = generateTenDigitRandomNumber();
      expect(id, isA<int>());
      expect(id, greaterThan(0));
    });

    test('suitable for verification codes', () {
      final code = generateTenDigitRandomNumber();
      final codeStr = code.toString();
      expect(codeStr.length, equals(10));
      expect(int.tryParse(codeStr), isNotNull);
    });

    test('handles successive calls', () {
      final num1 = generateTenDigitRandomNumber();
      final num2 = generateTenDigitRandomNumber();
      expect(num1, isA<int>());
      expect(num2, isA<int>());
    });

    test('contains only digits', () {
      final number = generateTenDigitRandomNumber().toString();
      for (var char in number.split('')) {
        expect(int.tryParse(char), isNotNull);
      }
    });

    test('respects minimum value', () {
      final number = generateTenDigitRandomNumber();
      expect(number, greaterThanOrEqualTo(1000000000));
    });

    test('respects maximum value', () {
      final number = generateTenDigitRandomNumber();
      expect(number, lessThanOrEqualTo(9999999999));
    });

    test('can be converted to string and back', () {
      final number = generateTenDigitRandomNumber();
      final str = number.toString();
      final parsed = int.parse(str);
      expect(parsed, equals(number));
    });

    test('suitable for database keys', () {
      final key = generateTenDigitRandomNumber();
      expect(key, isA<int>());
      expect(key.toString().length, equals(10));
    });

    test('generates valid digit patterns', () {
      final number = generateTenDigitRandomNumber().toString();
      expect(number.length, equals(10));
      expect(number.split('').every((c) => int.tryParse(c) != null), isTrue);
    });

    test('generates within expected range', () {
      final number = generateTenDigitRandomNumber();
      expect(number, inInclusiveRange(1000000000, 9999999999));
    });

    test('supports multiple calls', () {
      final num1 = generateTenDigitRandomNumber();
      final num2 = generateTenDigitRandomNumber();
      final num3 = generateTenDigitRandomNumber();
      expect(num1, isA<int>());
      expect(num2, isA<int>());
      expect(num3, isA<int>());
    });

    test('supports mathematical operations', () {
      final number = generateTenDigitRandomNumber();
      expect(number + 1, greaterThan(number));
      expect(number - 1, lessThan(number));
    });

    test('generates numbers with consistent behavior', () {
      final numbers = <int>[];
      for (var i = 0; i < 5; i++) {
        numbers.add(generateTenDigitRandomNumber());
      }
      for (var num in numbers) {
        expect(num, isA<int>());
        expect(num.toString().length, equals(10));
      }
    });
  });
}

import 'package:test/test.dart';
import 'package:zeytin/models/response.dart';

void main() {
  group('ZeytinResponse', () {
    test('creates response with success', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Operation successful',
      );
      expect(response.isSuccess, isTrue);
      expect(response.message, equals('Operation successful'));
      expect(response.error, isNull);
      expect(response.data, isNull);
    });

    test('creates response with error', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Operation failed',
        error: 'Something went wrong',
      );
      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Operation failed'));
      expect(response.error, equals('Something went wrong'));
      expect(response.data, isNull);
    });

    test('creates response with data', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Data retrieved',
        data: {'id': '123', 'name': 'Test'},
      );
      expect(response.isSuccess, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!['id'], equals('123'));
      expect(response.data!['name'], equals('Test'));
    });

    test('creates response with all fields', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Partial failure',
        error: 'Some items failed',
        data: {'processed': 5, 'failed': 2},
      );
      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Partial failure'));
      expect(response.error, equals('Some items failed'));
      expect(response.data!['processed'], equals(5));
      expect(response.data!['failed'], equals(2));
    });

    test('converts to map with success only', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Success',
      );
      final map = response.toMap();
      expect(map['isSuccess'], isTrue);
      expect(map['message'], equals('Success'));
      expect(map.containsKey('error'), isFalse);
      expect(map.containsKey('data'), isFalse);
    });

    test('converts to map with error', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Failed',
        error: 'Error details',
      );
      final map = response.toMap();
      expect(map['isSuccess'], isFalse);
      expect(map['message'], equals('Failed'));
      expect(map['error'], equals('Error details'));
      expect(map.containsKey('data'), isFalse);
    });

    test('converts to map with data', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Success',
        data: {'key': 'value'},
      );
      final map = response.toMap();
      expect(map['isSuccess'], isTrue);
      expect(map['message'], equals('Success'));
      expect(map['data'], isNotNull);
      expect(map['data']['key'], equals('value'));
    });

    test('converts to map with all fields', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Message',
        error: 'Error',
        data: {'info': 'data'},
      );
      final map = response.toMap();
      expect(map['isSuccess'], isFalse);
      expect(map['message'], equals('Message'));
      expect(map['error'], equals('Error'));
      expect(map['data']['info'], equals('data'));
    });

    test('creates from map with minimal fields', () {
      final map = {
        'isSuccess': true,
        'message': 'Success',
      };
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isTrue);
      expect(response.message, equals('Success'));
      expect(response.error, isNull);
      expect(response.data, isNotNull);
      expect(response.data!.isEmpty, isTrue);
    });

    test('creates from map with error', () {
      final map = {
        'isSuccess': false,
        'message': 'Failed',
        'error': 'Error message',
      };
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Failed'));
      expect(response.error, equals('Error message'));
    });

    test('creates from map with data', () {
      final map = {
        'isSuccess': true,
        'message': 'Success',
        'data': {'userId': '123', 'username': 'test'},
      };
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isTrue);
      expect(response.data!['userId'], equals('123'));
      expect(response.data!['username'], equals('test'));
    });

    test('creates from map with all fields', () {
      final map = {
        'isSuccess': false,
        'message': 'Partial',
        'error': 'Some error',
        'data': {'count': 10},
      };
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Partial'));
      expect(response.error, equals('Some error'));
      expect(response.data!['count'], equals(10));
    });

    test('handles missing isSuccess in fromMap', () {
      final map = {'message': 'Test'};
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Test'));
    });

    test('handles missing message in fromMap', () {
      final map = {'isSuccess': true};
      final response = ZeytinResponse.fromMap(map);
      expect(response.isSuccess, isTrue);
      expect(response.message, equals(''));
    });

    test('roundtrip conversion preserves data', () {
      final original = ZeytinResponse(
        isSuccess: true,
        message: 'Test message',
        error: 'Test error',
        data: {'key1': 'value1', 'key2': 42, 'key3': true},
      );
      final map = original.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.isSuccess, equals(original.isSuccess));
      expect(restored.message, equals(original.message));
      expect(restored.error, equals(original.error));
      expect(restored.data!['key1'], equals(original.data!['key1']));
      expect(restored.data!['key2'], equals(original.data!['key2']));
      expect(restored.data!['key3'], equals(original.data!['key3']));
    });

    test('handles nested data structures', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Complex data',
        data: {
          'user': {
            'id': '123',
            'profile': {
              'name': 'John',
              'age': 30,
            },
          },
          'items': [1, 2, 3],
        },
      );
      final map = response.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.data!['user']['id'], equals('123'));
      expect(restored.data!['user']['profile']['name'], equals('John'));
      expect(restored.data!['items'], equals([1, 2, 3]));
    });

    test('handles empty data map', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Empty data',
        data: {},
      );
      final map = response.toMap();
      expect(map['data'], isNotNull);
      expect(map['data'], isEmpty);
    });

    test('handles null values in data', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Null values',
        data: {
          'key1': 'value',
          'key2': null,
          'key3': 123,
        },
      );
      final map = response.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.data!['key1'], equals('value'));
      expect(restored.data!['key2'], isNull);
      expect(restored.data!['key3'], equals(123));
    });

    test('handles unicode in messages', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Başarılı! 🫒',
        error: 'Hata: Türkçe karakter',
      );
      final map = response.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.message, equals('Başarılı! 🫒'));
      expect(restored.error, equals('Hata: Türkçe karakter'));
    });

    test('creates success response without optional fields', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'OK',
      );
      expect(response.isSuccess, isTrue);
      expect(response.message, equals('OK'));
      expect(response.error, isNull);
      expect(response.data, isNull);
    });

    test('creates error response with detailed information', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Validation failed',
        error: 'Email format is invalid',
        data: {
          'field': 'email',
          'value': 'invalid-email',
          'constraint': 'must be valid email format',
        },
      );
      expect(response.isSuccess, isFalse);
      expect(response.error, contains('Email format'));
      expect(response.data!['field'], equals('email'));
    });

    test('handles large data payloads', () {
      final largeData = <String, dynamic>{};
      for (var i = 0; i < 1000; i++) {
        largeData['key$i'] = 'value$i';
      }
      
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Large data',
        data: largeData,
      );
      final map = response.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.data!.length, equals(1000));
      expect(restored.data!['key500'], equals('value500'));
    });

    test('handles special characters in error messages', () {
      final response = ZeytinResponse(
        isSuccess: false,
        message: 'Error',
        error: 'Invalid input: "test" <script>alert(1)</script>',
      );
      final map = response.toMap();
      expect(map['error'], contains('<script>'));
    });

    test('preserves data types through conversion', () {
      final response = ZeytinResponse(
        isSuccess: true,
        message: 'Types',
        data: {
          'string': 'text',
          'int': 42,
          'double': 3.14,
          'bool': true,
          'null': null,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        },
      );
      final map = response.toMap();
      final restored = ZeytinResponse.fromMap(map);
      
      expect(restored.data!['string'], isA<String>());
      expect(restored.data!['int'], isA<int>());
      expect(restored.data!['double'], isA<double>());
      expect(restored.data!['bool'], isA<bool>());
      expect(restored.data!['null'], isNull);
      expect(restored.data!['list'], isA<List>());
      expect(restored.data!['map'], isA<Map>());
    });
  });
}

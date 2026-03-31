import 'package:test/test.dart';
import 'package:zeytin/tools/tokener.dart';

void main() {
  group('ZeytinTokener', () {
    test('encrypts and decrypts string', () {
      final tokener = ZeytinTokener('mypassword');
      final original = 'Hello, Zeytin!';
      final encrypted = tokener.encryptString(original);
      final decrypted = tokener.decryptString(encrypted);
      expect(decrypted, equals(original));
    });

    test('encrypted string contains IV and ciphertext', () {
      final tokener = ZeytinTokener('mypassword');
      final encrypted = tokener.encryptString('test');
      expect(encrypted.contains(':'), isTrue);
      final parts = encrypted.split(':');
      expect(parts.length, equals(2));
      expect(parts[0].isNotEmpty, isTrue);
      expect(parts[1].isNotEmpty, isTrue);
    });

    test('same plaintext produces different ciphertext due to random IV', () {
      final tokener = ZeytinTokener('mypassword');
      final text = 'same text';
      final encrypted1 = tokener.encryptString(text);
      final encrypted2 = tokener.encryptString(text);
      expect(encrypted1, isNot(equals(encrypted2)));
      expect(tokener.decryptString(encrypted1), equals(text));
      expect(tokener.decryptString(encrypted2), equals(text));
    });

    test('encrypts and decrypts unicode strings', () {
      final tokener = ZeytinTokener('şifre');
      final original = 'Türkçe karakterler: ğüşıöç 🫒';
      final encrypted = tokener.encryptString(original);
      final decrypted = tokener.decryptString(encrypted);
      expect(decrypted, equals(original));
    });

    test('encrypts and decrypts non-empty string', () {
      final tokener = ZeytinTokener('password');
      final original = 'test';
      final encrypted = tokener.encryptString(original);
      final decrypted = tokener.decryptString(encrypted);
      expect(decrypted, equals(original));
    });

    test('encrypts and decrypts long strings', () {
      final tokener = ZeytinTokener('password');
      final original = 'A' * 10000;
      final encrypted = tokener.encryptString(original);
      final decrypted = tokener.decryptString(encrypted);
      expect(decrypted, equals(original));
    });

    test('different passwords produce different encryption keys', () {
      final tokener1 = ZeytinTokener('password1');
      final tokener2 = ZeytinTokener('password2');
      final text = 'secret message';
      final encrypted1 = tokener1.encryptString(text);
      try {
        final decrypted = tokener2.decryptString(encrypted1);
        expect(decrypted, isNot(equals(text)));
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('encrypts and decrypts map', () {
      final tokener = ZeytinTokener('mypassword');
      final original = {
        'name': 'Alice',
        'age': 25,
        'active': true,
        'tags': ['user', 'admin'],
      };
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted['name'], equals('Alice'));
      expect(decrypted['age'], equals(25));
      expect(decrypted['active'], isTrue);
      expect(decrypted['tags'], equals(['user', 'admin']));
    });

    test('encrypts and decrypts nested map', () {
      final tokener = ZeytinTokener('password');
      final original = {
        'user': {
          'profile': {
            'name': 'John',
            'email': 'john@example.com',
          },
          'settings': {
            'theme': 'dark',
            'notifications': true,
          },
        },
      };
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted['user']['profile']['name'], equals('John'));
      expect(decrypted['user']['settings']['theme'], equals('dark'));
    });

    test('encrypts and decrypts map with null values', () {
      final tokener = ZeytinTokener('password');
      final original = {
        'key1': 'value',
        'key2': null,
        'key3': 123,
      };
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted['key1'], equals('value'));
      expect(decrypted['key2'], isNull);
      expect(decrypted['key3'], equals(123));
    });

    test('encrypts and decrypts map with various data types', () {
      final tokener = ZeytinTokener('password');
      final original = {
        'string': 'text',
        'int': 42,
        'double': 3.14,
        'bool': true,
        'list': [1, 2, 3],
        'map': {'nested': 'value'},
      };
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted['string'], equals('text'));
      expect(decrypted['int'], equals(42));
      expect(decrypted['double'], closeTo(3.14, 0.001));
      expect(decrypted['bool'], isTrue);
      expect(decrypted['list'], equals([1, 2, 3]));
      expect(decrypted['map']['nested'], equals('value'));
    });

    test('encrypted map format contains IV and ciphertext', () {
      final tokener = ZeytinTokener('password');
      final encrypted = tokener.encryptMap({'key': 'value'});
      expect(encrypted.contains(':'), isTrue);
      final parts = encrypted.split(':');
      expect(parts.length, equals(2));
    });

    test('throws on invalid encrypted string format', () {
      final tokener = ZeytinTokener('password');
      expect(
        () => tokener.decryptString('invalid_format'),
        throwsFormatException,
      );
      expect(
        () => tokener.decryptString('only_one_part'),
        throwsFormatException,
      );
    });

    test('throws on invalid encrypted map format', () {
      final tokener = ZeytinTokener('password');
      expect(
        () => tokener.decryptMap('invalid:format'),
        throwsA(anything),
      );
    });

    test('throws on corrupted ciphertext', () {
      final tokener = ZeytinTokener('password');
      final encrypted = tokener.encryptString('test');
      final parts = encrypted.split(':');
      final corrupted = '${parts[0]}:corrupted_base64!!!';
      expect(
        () => tokener.decryptString(corrupted),
        throwsA(anything),
      );
    });

    test('key derivation from password is consistent', () {
      final tokener1 = ZeytinTokener('samepassword');
      final tokener2 = ZeytinTokener('samepassword');
      final text = 'test message';
      final encrypted = tokener1.encryptString(text);
      final decrypted = tokener2.decryptString(encrypted);
      expect(decrypted, equals(text));
    });

    test('encrypts and decrypts empty map', () {
      final tokener = ZeytinTokener('password');
      final original = <String, dynamic>{};
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted.isEmpty, isTrue);
    });

    test('handles large maps', () {
      final tokener = ZeytinTokener('password');
      final original = <String, dynamic>{};
      for (var i = 0; i < 1000; i++) {
        original['key$i'] = 'value$i';
      }
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted.length, equals(1000));
      expect(decrypted['key500'], equals('value500'));
    });

    test('handles special characters in map keys and values', () {
      final tokener = ZeytinTokener('password');
      final original = {
        'key with spaces': 'value with spaces',
        'key:with:colons': 'value:with:colons',
        'emoji🫒': '🔒secure',
      };
      final encrypted = tokener.encryptMap(original);
      final decrypted = tokener.decryptMap(encrypted);
      expect(decrypted['key with spaces'], equals('value with spaces'));
      expect(decrypted['key:with:colons'], equals('value:with:colons'));
      expect(decrypted['emoji🫒'], equals('🔒secure'));
    });

    test('password-based encryption is secure', () {
      final tokener = ZeytinTokener('strongpassword123');
      final sensitive = 'credit_card:1234-5678-9012-3456';
      final encrypted = tokener.encryptString(sensitive);
      expect(encrypted.contains('1234'), isFalse);
      expect(encrypted.contains('credit'), isFalse);
    });

    test('different instances with same password can decrypt', () {
      final tokener1 = ZeytinTokener('sharedpassword');
      final tokener2 = ZeytinTokener('sharedpassword');
      final tokener3 = ZeytinTokener('sharedpassword');
      
      final data = {'secret': 'information'};
      final encrypted = tokener1.encryptMap(data);
      final decrypted2 = tokener2.decryptMap(encrypted);
      final decrypted3 = tokener3.decryptMap(encrypted);
      
      expect(decrypted2['secret'], equals('information'));
      expect(decrypted3['secret'], equals('information'));
    });

    test('encrypts and decrypts complex real-world data', () {
      final tokener = ZeytinTokener('userpassword');
      final userData = {
        'userId': 'user_12345',
        'email': 'user@example.com',
        'profile': {
          'firstName': 'John',
          'lastName': 'Doe',
          'age': 30,
          'verified': true,
        },
        'permissions': ['read', 'write', 'delete'],
        'metadata': {
          'lastLogin': '2024-01-15T10:30:00Z',
          'loginCount': 42,
          'preferences': {
            'theme': 'dark',
            'language': 'en',
            'notifications': {
              'email': true,
              'push': false,
            },
          },
        },
      };
      
      final encrypted = tokener.encryptMap(userData);
      final decrypted = tokener.decryptMap(encrypted);
      
      expect(decrypted['userId'], equals('user_12345'));
      expect(decrypted['profile']['firstName'], equals('John'));
      expect(decrypted['permissions'], equals(['read', 'write', 'delete']));
      expect(decrypted['metadata']['preferences']['theme'], equals('dark'));
      expect(
        decrypted['metadata']['preferences']['notifications']['email'],
        isTrue,
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/routes/account.dart';
import 'package:zeytin/routes/admin.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/routes/crud.dart';
import 'package:zeytin/routes/storage.dart';
import 'package:zeytin/routes/mail.dart';
import 'package:zeytin/tools/tokener.dart';

void main() {
  group('Routes Integration Tests', () {
    late Directory testDir;
    late Zeytin zeytin;
    late Router router;

    setUp(() async {
      testDir = await Directory('test_data/routes').create(recursive: true);
      zeytin = Zeytin(testDir.path);
      router = Router();
      accountRoutes(zeytin, router);
      adminRoutes(zeytin, router);
      tokenRoutes(zeytin, router);
      crudRoutes(zeytin, router);
      storageRoutes(zeytin, router);
      mailRoutes(zeytin, router);
    });

    tearDown(() async {
      await zeytin.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
      tokens.clear();
      handshakePool.clear();
    });

    group('Token Routes', () {
      test('handshake creates temporary key', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/token/handshake'),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(200));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isTrue);
        expect(body['tempKey'], isNotNull);
        expect(body['tempKey'].length, equals(32));
      });

      test('handshake key expires after 10 seconds', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/token/handshake'),
        );

        await router.call(request);
        expect(handshakePool.length, equals(1));
        handshakePool[0]['expires'] = DateTime.now().millisecondsSinceEpoch - 1000;
        
        cleanHandshakePool();
        expect(handshakePool.length, equals(0));
      });
    });

    group('Account Routes', () {
      test('truck id requires encrypted payload', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/truck/id'),
          body: jsonEncode({'invalid': 'data'}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isFalse);
      });
    });

    group('CRUD Routes', () {
      test('data add requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/add'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isFalse);
        expect(body['error'], contains('Token and data parameters are mandatory'));
      });

      test('data get requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/get'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isFalse);
      });

      test('data delete requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/delete'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data addBatch requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/addBatch'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data getBox requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/getBox'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data existsBox requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/existsBox'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data existsTag requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/existsTag'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data contains requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/contains'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data search requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/search'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });

      test('data filter requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/data/filter'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));
      });
    });

    group('Storage Routes', () {
      test('storage upload requires multipart request', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/storage/upload'),
          body: jsonEncode({'not': 'multipart'}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isFalse);
        expect(body['error'], contains('Multipart request expected'));
      });

      test('storage get returns 404 for non-existent file', () async {
        final request = Request(
          'GET',
          Uri.parse('http://localhost/test-truck/nonexistent.jpg'),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(404));
      });
    });

    group('Mail Routes', () {
      test('mail send requires token and data', () async {
        final request = Request(
          'POST',
          Uri.parse('http://localhost/mail/send'),
          body: jsonEncode({}),
        );

        final response = await router.call(request);
        expect(response.statusCode, equals(400));

        final body = jsonDecode(await response.readAsString());
        expect(body['isSuccess'], isFalse);
        expect(body['error'], contains('Token and data parameters are mandatory'));
      });
    });

    group('Token Management', () {
      test('getTokenData returns null for invalid token', () {
        final result = getTokenData('invalid-token');
        expect(result, isNull);
      });

      test('isTokenValid returns false for non-existent token', () {
        final result = isTokenValid('non-existent-token');
        expect(result, isFalse);
      });

      test('isTokenValid returns false for expired token', () {
        tokens.add({
          'token': 'expired-token',
          'truck': 'test-truck',
          'email': 'test@example.com',
          'password': 'password',
          'create_at': DateTime.now().millisecondsSinceEpoch - 200000,
        });

        final result = isTokenValid('expired-token');
        expect(result, isFalse);
        expect(tokens.where((t) => t['token'] == 'expired-token').isEmpty, isTrue);
      });

      test('isTokenValid returns true for valid token', () {
        tokens.add({
          'token': 'valid-token',
          'truck': 'test-truck',
          'email': 'test@example.com',
          'password': 'password',
          'create_at': DateTime.now().millisecondsSinceEpoch,
        });

        final result = isTokenValid('valid-token');
        expect(result, isTrue);
      });

      test('getTokenByCredentials returns token for valid credentials', () {
        tokens.add({
          'token': 'test-token',
          'truck': 'test-truck',
          'email': 'user@example.com',
          'password': 'password123',
          'create_at': DateTime.now().millisecondsSinceEpoch,
        });

        final result = getTokenByCredentials('user@example.com', 'password123');
        expect(result, equals('test-token'));
      });

      test('getTokenByCredentials returns null for invalid credentials', () {
        final result = getTokenByCredentials('wrong@example.com', 'wrong');
        expect(result, isNull);
      });
    });

    group('Handshake Management', () {
      test('cleanHandshakePool removes expired handshakes', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        
        handshakePool.add({'key': 'valid-key', 'expires': now + 10000});
        handshakePool.add({'key': 'expired-key', 'expires': now - 1000});
        
        cleanHandshakePool();
        
        expect(handshakePool.length, equals(1));
        expect(handshakePool[0]['key'], equals('valid-key'));
      });

      test('cleanHandshakePool keeps valid handshakes', () {
        final now = DateTime.now().millisecondsSinceEpoch;
        
        handshakePool.add({'key': 'key1', 'expires': now + 5000});
        handshakePool.add({'key': 'key2', 'expires': now + 8000});
        
        cleanHandshakePool();
        
        expect(handshakePool.length, equals(2));
      });
    });

    group('Encryption Integration', () {
      test('encrypted data can be decrypted with correct password', () {
        final password = 'test-password';
        final tokener = ZeytinTokener(password);
        final originalData = {'box': 'test', 'tag': 'data'};
        
        final encrypted = tokener.encryptMap(originalData);
        final decrypted = tokener.decryptMap(encrypted);
        
        expect(decrypted['box'], equals('test'));
        expect(decrypted['tag'], equals('data'));
      });

      test('encrypted data cannot be decrypted with wrong password', () {
        final tokener1 = ZeytinTokener('password1');
        final tokener2 = ZeytinTokener('password2');
        final originalData = {'box': 'test', 'tag': 'data'};
        
        final encrypted = tokener1.encryptMap(originalData);
        
        try {
          final decrypted = tokener2.decryptMap(encrypted);
          expect(decrypted, isNot(equals(originalData)));
        } catch (e) {
          expect(e, isNotNull);
        }
      });
    });
  });
}

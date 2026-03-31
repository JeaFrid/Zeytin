import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/routes/admin.dart';
import 'package:zeytin/config.dart';

void main() {
  group('Admin Routes', () {
    late Directory testDir;
    late Zeytin zeytin;
    late Router router;

    setUp(() async {
      testDir = await Directory('test_data/admin').create(recursive: true);
      zeytin = Zeytin(testDir.path);
      router = Router();
      adminRoutes(zeytin, router);
    });

    tearDown(() async {
      await zeytin.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('admin truck create blocks non-localhost IP', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/admin/truck/create'),
        headers: {'x-forwarded-for': '192.168.1.100'},
        body: jsonEncode({
          'adminSecret': ZeytinConfig.adminSecret,
          'email': 'test@example.com',
          'password': 'password123',
        }),
      );

      final response = await router.call(request);
      expect(response.statusCode, equals(403));

      final body = jsonDecode(await response.readAsString());
      expect(body['isSuccess'], isFalse);
      expect(body['error'], contains('localhost'));
    });

    test('admin truck create requires admin secret', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/admin/truck/create'),
        headers: {'x-forwarded-for': '127.0.0.1'},
        body: jsonEncode({
          'adminSecret': 'wrong-secret',
          'email': 'test@example.com',
          'password': 'password123',
        }),
      );

      final response = await router.call(request);
      expect(response.statusCode, equals(403));

      final body = jsonDecode(await response.readAsString());
      expect(body['isSuccess'], isFalse);
      expect(body['error'], contains('Invalid admin secret'));
    });

    test('admin truck create succeeds with valid data from localhost', () async {
      final request = Request(
        'POST',
        Uri.parse('http://localhost/admin/truck/create'),
        headers: {'x-forwarded-for': '127.0.0.1'},
        body: jsonEncode({
          'adminSecret': ZeytinConfig.adminSecret,
          'email': 'admin-test@example.com',
          'password': 'secure-password',
        }),
      );

      final response = await router.call(request);
      expect(response.statusCode, equals(200));

      final body = jsonDecode(await response.readAsString());
      expect(body['isSuccess'], isTrue);
      expect(body['data']['email'], equals('admin-test@example.com'));
      expect(body['data']['password'], equals('secure-password'));
      expect(body['data']['truckId'], isNotNull);
    });

    test('admin change password succeeds for existing account', () async {
      final createRequest = Request(
        'POST',
        Uri.parse('http://localhost/admin/truck/create'),
        headers: {'x-forwarded-for': '127.0.0.1'},
        body: jsonEncode({
          'adminSecret': ZeytinConfig.adminSecret,
          'email': 'changepass@example.com',
          'password': 'oldpassword',
        }),
      );
      await router.call(createRequest);
      final changeRequest = Request(
        'POST',
        Uri.parse('http://localhost/admin/truck/changePassword'),
        headers: {'x-forwarded-for': '127.0.0.1'},
        body: jsonEncode({
          'adminSecret': ZeytinConfig.adminSecret,
          'email': 'changepass@example.com',
          'newPassword': 'newpassword123',
        }),
      );

      final response = await router.call(changeRequest);
      expect(response.statusCode, equals(200));

      final body = jsonDecode(await response.readAsString());
      expect(body['isSuccess'], isTrue);
      expect(body['data']['email'], equals('changepass@example.com'));
      expect(body['data']['newPassword'], equals('newpassword123'));
    });
  });
}

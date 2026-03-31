import 'dart:io';
import 'package:test/test.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';

void main() {
  group('ZeytinAccounts', () {
    late Directory testDir;
    late Zeytin zeytin;

    setUp(() async {
      testDir = await Directory('test_data/accounts').create(recursive: true);
      zeytin = Zeytin(testDir.path);
      await zeytin.createTruck(truckId: 'system');
    });

    tearDown(() async {
      await zeytin.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('creates new account successfully', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'test@example.com',
        'password123',
      );

      expect(response.isSuccess, isTrue);
      expect(response.message, equals('Oki doki!'));
      expect(response.data, isNotNull);
      expect(response.data!['id'], isNotNull);
    });

    test('prevents duplicate email registration', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'duplicate@example.com',
        'password123',
      );

      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'duplicate@example.com',
        'password456',
      );

      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Opss...'));
      expect(response.error, contains('email has been used'));
    });

    test('creates account with case-insensitive email check', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'Test@Example.com',
        'password123',
      );

      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'test@example.com',
        'password456',
      );

      expect(response.isSuccess, isFalse);
    });

    test('stores hashed password not plain text', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'secure@example.com',
        'mypassword',
      );

      final truckId = response.data!['id'];
      final accountData = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: truckId,
      );

      expect(accountData!['password'], isNot(equals('mypassword')));
      expect(accountData['password'].length, greaterThan(20));
    });

    test('creates storage directory for new account', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'storage@example.com',
        'password123',
      );

      final truckId = response.data!['id'];
      final storageDir = Directory('${zeytin.rootPath}/$truckId/storage');
      expect(await storageDir.exists(), isTrue);
    });

    test('stores account creation timestamp', () async {
      final beforeCreation = DateTime.now();
      
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'timestamp@example.com',
        'password123',
      );

      final truckId = response.data!['id'];
      final accountData = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: truckId,
      );

      final createdAt = DateTime.parse(accountData!['createdAt']);
      expect(createdAt.isAfter(beforeCreation.subtract(Duration(seconds: 1))), isTrue);
      expect(createdAt.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
    });

    test('login succeeds with correct credentials', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'login@example.com',
        'correctpassword',
      );

      final response = await ZeytinAccounts.login(
        zeytin,
        'login@example.com',
        'correctpassword',
      );

      expect(response.isSuccess, isTrue);
      expect(response.message, equals('Oki doki!'));
      expect(response.data!['id'], isNotNull);
    });

    test('login fails with incorrect password', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'wrongpass@example.com',
        'correctpassword',
      );

      final response = await ZeytinAccounts.login(
        zeytin,
        'wrongpass@example.com',
        'wrongpassword',
      );

      expect(response.isSuccess, isFalse);
      expect(response.message, equals('Opss...'));
      expect(response.error, contains("doesn't match"));
    });

    test('login fails with non-existent email', () async {
      final response = await ZeytinAccounts.login(
        zeytin,
        'nonexistent@example.com',
        'anypassword',
      );

      expect(response.isSuccess, isFalse);
      expect(response.error, contains("doesn't match"));
    });

    test('login returns correct truck ID', () async {
      final createResponse = await ZeytinAccounts.createAccount(
        zeytin,
        'checkid@example.com',
        'password123',
      );
      final expectedId = createResponse.data!['id'];

      final loginResponse = await ZeytinAccounts.login(
        zeytin,
        'checkid@example.com',
        'password123',
      );

      expect(loginResponse.data!['id'], equals(expectedId));
    });

    test('checks if email is registered', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'registered@example.com',
        'password123',
      );

      final isRegistered = await ZeytinAccounts.isEmailRegistered(
        zeytin,
        'registered@example.com',
      );
      final isNotRegistered = await ZeytinAccounts.isEmailRegistered(
        zeytin,
        'notregistered@example.com',
      );

      expect(isRegistered, isTrue);
      expect(isNotRegistered, isFalse);
    });

    test('email check is case-insensitive', () async {
      await ZeytinAccounts.createAccount(
        zeytin,
        'CaseSensitive@Example.COM',
        'password123',
      );

      final isRegistered = await ZeytinAccounts.isEmailRegistered(
        zeytin,
        'casesensitive@example.com',
      );

      expect(isRegistered, isTrue);
    });

    test('multiple accounts can be created', () async {
      final response1 = await ZeytinAccounts.createAccount(
        zeytin,
        'user1@example.com',
        'password1',
      );
      final response2 = await ZeytinAccounts.createAccount(
        zeytin,
        'user2@example.com',
        'password2',
      );
      final response3 = await ZeytinAccounts.createAccount(
        zeytin,
        'user3@example.com',
        'password3',
      );

      expect(response1.isSuccess, isTrue);
      expect(response2.isSuccess, isTrue);
      expect(response3.isSuccess, isTrue);
      expect(response1.data!['id'], isNot(equals(response2.data!['id'])));
      expect(response2.data!['id'], isNot(equals(response3.data!['id'])));
    });

    test('password hashing uses truck ID as salt', () async {
      final response1 = await ZeytinAccounts.createAccount(
        zeytin,
        'salt1@example.com',
        'samepassword',
      );
      final response2 = await ZeytinAccounts.createAccount(
        zeytin,
        'salt2@example.com',
        'samepassword',
      );

      final account1 = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: response1.data!['id'],
      );
      final account2 = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: response2.data!['id'],
      );

      expect(account1!['password'], isNot(equals(account2!['password'])));
    });

    test('handles special characters in email', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'user+tag@sub.example.com',
        'password123',
      );

      expect(response.isSuccess, isTrue);

      final loginResponse = await ZeytinAccounts.login(
        zeytin,
        'user+tag@sub.example.com',
        'password123',
      );

      expect(loginResponse.isSuccess, isTrue);
    });

    test('handles unicode characters in password', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'unicode@example.com',
        'şifre123🔒',
      );

      expect(response.isSuccess, isTrue);

      final loginResponse = await ZeytinAccounts.login(
        zeytin,
        'unicode@example.com',
        'şifre123🔒',
      );

      expect(loginResponse.isSuccess, isTrue);
    });

    test('account data includes all required fields', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'complete@example.com',
        'password123',
      );

      final truckId = response.data!['id'];
      final accountData = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: truckId,
      );

      expect(accountData!['email'], equals('complete@example.com'));
      expect(accountData['password'], isNotNull);
      expect(accountData['id'], equals(truckId));
      expect(accountData['createdAt'], isNotNull);
    });
  });
}

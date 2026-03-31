import 'dart:io';
import 'package:test/test.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/account.dart';

void main() {
  group('DB Manager Essential Functions', () {
    late Directory testDir;
    late Zeytin zeytin;

    setUp(() async {
      testDir = await Directory('test_data/db_simple').create(recursive: true);
      zeytin = Zeytin(testDir.path);
      await zeytin.createTruck(truckId: 'system');
    });

    tearDown(() async {
      await zeytin.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('create and retrieve account', () async {
      final response = await ZeytinAccounts.createAccount(
        zeytin,
        'test@example.com',
        'password123',
      );

      expect(response.isSuccess, isTrue);
      final truckId = response.data!['id'];

      final data = await zeytin.get(
        truckId: 'system',
        boxId: 'trucks',
        tag: truckId,
      );

      expect(data, isNotNull);
      expect(data!['email'], equals('test@example.com'));
    });

    test('add and retrieve data from box', () async {
      final account = await ZeytinAccounts.createAccount(
        zeytin,
        'user@test.com',
        'pass',
      );
      final truckId = account.data!['id'];

      await zeytin.put(
        truckId: truckId,
        boxId: 'testbox',
        tag: 'item1',
        value: {'name': 'Test Item', 'value': 100},
      );

      final data = await zeytin.get(
        truckId: truckId,
        boxId: 'testbox',
        tag: 'item1',
      );

      expect(data, isNotNull);
      expect(data!['name'], equals('Test Item'));
      expect(data['value'], equals(100));
    });

    test('delete data from box', () async {
      final account = await ZeytinAccounts.createAccount(
        zeytin,
        'delete@test.com',
        'pass',
      );
      final truckId = account.data!['id'];

      await zeytin.put(
        truckId: truckId,
        boxId: 'deletebox',
        tag: 'item',
        value: {'data': 'test'},
      );

      var exists = await zeytin.existsTag(
        truckId: truckId,
        boxId: 'deletebox',
        tag: 'item',
      );
      expect(exists, isTrue);

      await zeytin.delete(
        truckId: truckId,
        boxId: 'deletebox',
        tag: 'item',
      );

      exists = await zeytin.existsTag(
        truckId: truckId,
        boxId: 'deletebox',
        tag: 'item',
      );
      expect(exists, isFalse);
    });

    test('search data in box', () async {
      final account = await ZeytinAccounts.createAccount(
        zeytin,
        'search@test.com',
        'pass',
      );
      final truckId = account.data!['id'];

      await zeytin.put(
        truckId: truckId,
        boxId: 'searchbox',
        tag: 'user1',
        value: {'name': 'Alice', 'age': 30},
      );
      await zeytin.put(
        truckId: truckId,
        boxId: 'searchbox',
        tag: 'user2',
        value: {'name': 'Bob', 'age': 25},
      );

      final results = await zeytin.search(
        truckId,
        'searchbox',
        'name',
        'A',
      );

      expect(results, isNotEmpty);
      expect(results.any((r) => r['name'] == 'Alice'), isTrue);
    });

    test('filter data with predicate', () async {
      final account = await ZeytinAccounts.createAccount(
        zeytin,
        'filter@test.com',
        'pass',
      );
      final truckId = account.data!['id'];

      await zeytin.put(
        truckId: truckId,
        boxId: 'filterbox',
        tag: 'item1',
        value: {'price': 100, 'inStock': true},
      );
      await zeytin.put(
        truckId: truckId,
        boxId: 'filterbox',
        tag: 'item2',
        value: {'price': 50, 'inStock': false},
      );

      final results = await zeytin.filter(
        truckId,
        'filterbox',
        (data) => data['inStock'] == true,
      );

      expect(results.length, equals(1));
      expect(results[0]['price'], equals(100));
    });
  });
}

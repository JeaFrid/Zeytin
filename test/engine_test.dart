import 'dart:io';
import 'package:test/test.dart';
import 'package:zeytin/logic/engine.dart';

void main() {
  group('BinaryEncoder', () {
    test('encodes and decodes null value', () {
      final data = {'key': null};
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['key'], isNull);
    });

    test('encodes and decodes boolean values', () {
      final data = {'isActive': true, 'isDeleted': false};
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['isActive'], isTrue);
      expect(decoded['isDeleted'], isFalse);
    });

    test('encodes and decodes integer values', () {
      final data = {'count': 42, 'negative': -100, 'large': 9223372036854775807};
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['count'], equals(42));
      expect(decoded['negative'], equals(-100));
      expect(decoded['large'], equals(9223372036854775807));
    });

    test('encodes and decodes double values', () {
      final data = {'pi': 3.14159, 'negative': -2.5};
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['pi'], closeTo(3.14159, 0.00001));
      expect(decoded['negative'], closeTo(-2.5, 0.00001));
    });

    test('encodes and decodes string values', () {
      final data = {
        'name': 'Zeytin',
        'emoji': '🫒',
        'unicode': 'Türkçe karakterler: ğüşıöç',
      };
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['name'], equals('Zeytin'));
      expect(decoded['emoji'], equals('🫒'));
      expect(decoded['unicode'], equals('Türkçe karakterler: ğüşıöç'));
    });

    test('encodes and decodes list values', () {
      final data = {
        'numbers': [1, 2, 3],
        'mixed': ['text', 42, true, null],
      };
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['numbers'], equals([1, 2, 3]));
      expect(decoded['mixed'], equals(['text', 42, true, null]));
    });

    test('encodes and decodes nested map values', () {
      final data = {
        'user': {
          'name': 'John',
          'age': 30,
          'settings': {'theme': 'dark', 'notifications': true},
        },
      };
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(decoded['user']['name'], equals('John'));
      expect(decoded['user']['age'], equals(30));
      expect(decoded['user']['settings']['theme'], equals('dark'));
      expect(decoded['user']['settings']['notifications'], isTrue);
    });

    test('encodes and decodes DateTime values', () {
      final now = DateTime.now();
      final data = {'timestamp': now};
      final encoded = BinaryEncoder.encodeMap(data);
      final decoded = BinaryEncoder.decodeMap(encoded);
      expect(
        decoded['timestamp'].millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test('encodes complete data block with magic byte', () {
      final encoded = BinaryEncoder.encode(
        'testBox',
        'testTag',
        {'value': 'test'},
      );
      expect(encoded[0], equals(BinaryEncoder.magicByte));
    });
  });

  group('LRUCache', () {
    test('stores and retrieves values', () {
      final cache = LRUCache<String, int>(3);
      cache.put('a', 1);
      cache.put('b', 2);
      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), equals(2));
    });

    test('evicts least recently used item when full', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
      expect(cache.get('c'), equals(3));
    });

    test('updates access order on get', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.get('a');
      cache.put('c', 3);
      expect(cache.get('a'), equals(1));
      expect(cache.get('b'), isNull);
    });

    test('updates existing values', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      cache.put('a', 10);
      expect(cache.get('a'), equals(10));
    });

    test('checks if key exists', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('b'), isFalse);
    });

    test('removes specific key', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.remove('a');
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), equals(2));
    });

    test('clears all entries', () {
      final cache = LRUCache<String, int>(2);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.clear();
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
    });
  });

  group('PersistentIndex', () {
    late Directory testDir;
    late String indexPath;

    setUp(() async {
      testDir = await Directory('test_data/index').create(recursive: true);
      indexPath = '${testDir.path}/test.idx';
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('creates new index file', () async {
      final index = PersistentIndex(indexPath);
      await index.load();
      expect(File(indexPath).existsSync(), isFalse);
    });

    test('updates and retrieves index entries', () async {
      final index = PersistentIndex(indexPath);
      await index.load();
      index.update('box1', 'tag1', 0, 100);
      final result = index.get('box1', 'tag1');
      expect(result, equals([0, 100]));
    });

    test('saves and loads index from disk', () async {
      final index1 = PersistentIndex(indexPath);
      await index1.load();
      index1.update('box1', 'tag1', 0, 100);
      index1.update('box1', 'tag2', 100, 200);
      await index1.save();

      final index2 = PersistentIndex(indexPath);
      await index2.load();
      expect(index2.get('box1', 'tag1'), equals([0, 100]));
      expect(index2.get('box1', 'tag2'), equals([100, 200]));
    });

    test('retrieves entire box', () async {
      final index = PersistentIndex(indexPath);
      await index.load();
      index.update('box1', 'tag1', 0, 100);
      index.update('box1', 'tag2', 100, 200);
      final box = index.getBox('box1');
      expect(box, isNotNull);
      expect(box!.length, equals(2));
      expect(box['tag1'], equals([0, 100]));
      expect(box['tag2'], equals([100, 200]));
    });

    test('calculates max indexed offset', () async {
      final index = PersistentIndex(indexPath);
      await index.load();
      index.update('box1', 'tag1', 0, 100);
      index.update('box1', 'tag2', 100, 200);
      index.update('box2', 'tag3', 300, 150);
      expect(index.getMaxIndexedOffset(), equals(450));
    });
  });

  group('Truck', () {
    late Directory testDir;
    late String truckPath;
    late Truck truck;

    setUp(() async {
      testDir = await Directory('test_data/trucks').create(recursive: true);
      truckPath = testDir.path;
      truck = Truck('test_truck', truckPath);
      await truck.initialize();
    });

    tearDown(() async {
      await truck.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('writes and reads data', () async {
      await truck.write('users', 'user1', {'name': 'Alice', 'age': 25});
      final data = await truck.read('users', 'user1');
      expect(data, isNotNull);
      expect(data!['name'], equals('Alice'));
      expect(data['age'], equals(25));
    });

    test('updates existing data', () async {
      await truck.write('users', 'user1', {'name': 'Alice', 'age': 25});
      await truck.write('users', 'user1', {'name': 'Alice', 'age': 26});
      final data = await truck.read('users', 'user1');
      expect(data!['age'], equals(26));
    });

    test('writes batch data', () async {
      await truck.batch('products', {
        'prod1': {'name': 'Laptop', 'price': 1000},
        'prod2': {'name': 'Mouse', 'price': 50},
        'prod3': {'name': 'Keyboard', 'price': 100},
      });
      final data1 = await truck.read('products', 'prod1');
      final data2 = await truck.read('products', 'prod2');
      expect(data1!['name'], equals('Laptop'));
      expect(data2!['price'], equals(50));
    });

    test('reads entire box', () async {
      await truck.write('settings', 'theme', {'mode': 'dark'});
      await truck.write('settings', 'language', {'code': 'en'});
      final box = await truck.readBox('settings');
      expect(box.length, equals(2));
      expect(box['theme']!['mode'], equals('dark'));
      expect(box['language']!['code'], equals('en'));
    });

    test('removes tag', () async {
      await truck.write('users', 'user1', {'name': 'Alice'});
      await truck.removeTag('users', 'user1');
      final data = await truck.read('users', 'user1');
      expect(data, isNull);
    });

    test('removes entire box', () async {
      await truck.write('temp', 'item1', {'value': 1});
      await truck.write('temp', 'item2', {'value': 2});
      await truck.removeBox('temp');
      final box = await truck.readBox('temp');
      expect(box.isEmpty, isTrue);
    });

    test('checks if data contains tag', () async {
      await truck.write('users', 'user1', {'name': 'Alice'});
      final exists = await truck.read('users', 'user1');
      expect(exists, isNotNull);
      final notExists = await truck.read('users', 'user2');
      expect(notExists, isNull);
    });

    test('performs prefix search', () async {
      await truck.write('users', 'user1', {'name': 'Alice', 'city': 'Amsterdam'});
      await truck.write('users', 'user2', {'name': 'Bob', 'city': 'Berlin'});
      await truck.write('users', 'user3', {'name': 'Charlie', 'city': 'Amsterdam'});
      
      final results = await truck.query('users', 'city', 'Amster');
      expect(results.length, equals(2));
      expect(results.any((r) => r['name'] == 'Alice'), isTrue);
      expect(results.any((r) => r['name'] == 'Charlie'), isTrue);
    });

    test('handles complex nested data', () async {
      final complexData = {
        'user': {
          'profile': {
            'name': 'John',
            'contacts': ['email@test.com', 'phone'],
          },
          'settings': {
            'notifications': true,
            'theme': 'dark',
          },
        },
        'metadata': {
          'created': DateTime.now().toIso8601String(),
          'version': 1,
        },
      };
      await truck.write('complex', 'data1', complexData);
      final retrieved = await truck.read('complex', 'data1');
      expect(retrieved!['user']['profile']['name'], equals('John'));
      expect(retrieved['user']['settings']['theme'], equals('dark'));
    });
  });

  group('TruckProxy', () {
    late Directory testDir;
    late TruckProxy proxy;

    setUp(() async {
      testDir = await Directory('test_data/proxy').create(recursive: true);
      proxy = TruckProxy('proxy_test', testDir.path);
      await proxy.initialize();
    });

    tearDown(() async {
      await proxy.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('writes and reads through isolate', () async {
      await proxy.write('box1', 'tag1', {'value': 'test'});
      final data = await proxy.read('box1', 'tag1');
      expect(data!['value'], equals('test'));
    });

    test('performs batch operations through isolate', () async {
      await proxy.batch('items', {
        'item1': {'name': 'First'},
        'item2': {'name': 'Second'},
      });
      final data1 = await proxy.read('items', 'item1');
      final data2 = await proxy.read('items', 'item2');
      expect(data1!['name'], equals('First'));
      expect(data2!['name'], equals('Second'));
    });

    test('checks contains through isolate', () async {
      await proxy.write('box1', 'tag1', {'value': 'test'});
      final exists = await proxy.contains('box1', 'tag1');
      final notExists = await proxy.contains('box1', 'tag2');
      expect(exists, isTrue);
      expect(notExists, isFalse);
    });
  });

  group('Zeytin', () {
    late Directory testDir;
    late Zeytin zeytin;

    setUp(() async {
      testDir = await Directory('test_data/zeytin').create(recursive: true);
      zeytin = Zeytin(testDir.path, cacheSize: 100);
    });

    tearDown(() async {
      await zeytin.close();
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('creates truck automatically on first access', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
        value: {'data': 'test'},
      );
      final data = await zeytin.get(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
      );
      expect(data!['data'], equals('test'));
    });

    test('handles multiple trucks', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
        value: {'user': 'Alice'},
      );
      await zeytin.put(
        truckId: 'truck2',
        boxId: 'box1',
        tag: 'tag1',
        value: {'user': 'Bob'},
      );
      
      final data1 = await zeytin.get(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
      );
      final data2 = await zeytin.get(
        truckId: 'truck2',
        boxId: 'box1',
        tag: 'tag1',
      );
      
      expect(data1!['user'], equals('Alice'));
      expect(data2!['user'], equals('Bob'));
    });

    test('uses memory cache for repeated reads', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
        value: {'cached': true},
      );
      
      final data1 = await zeytin.get(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
      );
      final data2 = await zeytin.get(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
      );
      
      expect(data1!['cached'], isTrue);
      expect(data2!['cached'], isTrue);
    });

    test('performs batch operations', () async {
      await zeytin.putBatch(
        truckId: 'truck1',
        boxId: 'products',
        entries: {
          'prod1': {'name': 'Item1', 'price': 100},
          'prod2': {'name': 'Item2', 'price': 200},
          'prod3': {'name': 'Item3', 'price': 300},
        },
      );
      
      final box = await zeytin.getBox(truckId: 'truck1', boxId: 'products');
      expect(box.length, equals(3));
      expect(box['prod2']!['price'], equals(200));
    });

    test('checks if box exists', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'existing',
        tag: 'tag1',
        value: {'data': 'test'},
      );
      
      final exists = await zeytin.existsBox(
        truckId: 'truck1',
        boxId: 'existing',
      );
      final notExists = await zeytin.existsBox(
        truckId: 'truck1',
        boxId: 'nonexistent',
      );
      
      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test('checks if tag exists', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'existing',
        value: {'data': 'test'},
      );
      
      final exists = await zeytin.existsTag(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'existing',
      );
      final notExists = await zeytin.existsTag(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'nonexistent',
      );
      
      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test('deletes tag', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
        value: {'data': 'test'},
      );
      await zeytin.delete(truckId: 'truck1', boxId: 'box1', tag: 'tag1');
      
      final data = await zeytin.get(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
      );
      expect(data, isNull);
    });

    test('deletes entire box', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'temp',
        tag: 'tag1',
        value: {'data': '1'},
      );
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'temp',
        tag: 'tag2',
        value: {'data': '2'},
      );
      await zeytin.deleteBox(truckId: 'truck1', boxId: 'temp');
      
      final box = await zeytin.getBox(truckId: 'truck1', boxId: 'temp');
      expect(box.isEmpty, isTrue);
    });

    test('performs search with prefix', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user1',
        value: {'email': 'alice@example.com'},
      );
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user2',
        value: {'email': 'alice@test.com'},
      );
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user3',
        value: {'email': 'bob@example.com'},
      );
      
      final results = await zeytin.search('truck1', 'users', 'email', 'alice');
      expect(results.length, equals(2));
    });

    test('filters data with predicate', () async {
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user1',
        value: {'name': 'Alice', 'age': 25},
      );
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user2',
        value: {'name': 'Bob', 'age': 30},
      );
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'users',
        tag: 'user3',
        value: {'name': 'Charlie', 'age': 20},
      );
      
      final results = await zeytin.filter(
        'truck1',
        'users',
        (data) => (data['age'] as int) >= 25,
      );
      
      expect(results.length, equals(2));
      expect(results.any((r) => r['name'] == 'Alice'), isTrue);
      expect(results.any((r) => r['name'] == 'Bob'), isTrue);
    });

    test('emits change events', () async {
      final events = <Map<String, dynamic>>[];
      zeytin.changes.listen(events.add);
      
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'box1',
        tag: 'tag1',
        value: {'data': 'test'},
      );
      
      await Future.delayed(Duration(milliseconds: 100));
      
      expect(events.length, greaterThan(0));
      expect(events.first['op'], equals('PUT'));
      expect(events.first['truckId'], equals('truck1'));
    });

    test('creates and retrieves trucks', () async {
      await zeytin.createTruck(truckId: 'truck1');
      await zeytin.createTruck(truckId: 'truck2');
      await zeytin.put(
        truckId: 'truck1',
        boxId: 'test',
        tag: 'data',
        value: {'test': 'value'},
      );
      
      final trucks = zeytin.getAllTruck();
      expect(trucks.isNotEmpty, isTrue);
    });
  });
}

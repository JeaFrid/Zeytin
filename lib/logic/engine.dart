import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';

class LRUCache<K, V> {
  final int maxSize;
  final Map<K, _Node<V>> _map = {};
  _Node<V>? _head;
  _Node<V>? _tail;
  int _size = 0;

  LRUCache(this.maxSize);

  V? get(K key) {
    final node = _map[key];
    if (node == null) return null;
    _moveToHead(node);
    return node.value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      final node = _map[key]!;
      node.value = value;
      _moveToHead(node);
    } else {
      final node = _Node<V>(key, value);
      _map[key] = node;
      _addToHead(node);
      _size++;
      if (_size > maxSize) {
        _removeTail();
      }
    }
  }

  bool contains(K key) => _map.containsKey(key);

  void remove(K key) {
    final node = _map[key];
    if (node != null) {
      _removeNode(node);
      _map.remove(key);
      _size--;
    }
  }

  void clear() {
    _map.clear();
    _head = _tail = null;
    _size = 0;
  }

  void _moveToHead(_Node<V> node) {
    if (node == _head) return;
    _removeNode(node);
    _addToHead(node);
  }

  void _addToHead(_Node<V> node) {
    node.prev = null;
    node.next = _head;
    if (_head != null) _head!.prev = node;
    _head = node;
    _tail ??= node;
  }

  void _removeNode(_Node<V> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }
    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
    node.prev = null;
    node.next = null;
  }

  void _removeTail() {
    if (_tail != null) {
      final key = _tail!.key;
      _removeNode(_tail!);
      _map.remove(key);
      _size--;
    }
  }
}

class _Node<V> {
  final dynamic key;
  V value;
  _Node<V>? prev;
  _Node<V>? next;
  _Node(this.key, this.value);
}

class BinaryEncoder {
  static const int typeNULL = 0;
  static const int typeBOOL = 1;
  static const int typeINT = 2;
  static const int typeDOUBLE = 3;
  static const int typeSTRING = 4;
  static const int typeLIST = 5;
  static const int typeMAP = 6;
  static const int magicByte = 0xDB;

  static Uint8List encode(String boxId, String tag, Map<String, dynamic> data) {
    final builder = BytesBuilder();
    builder.addByte(magicByte);
    final boxBytes = utf8.encode(boxId);
    _encodeRawLength(builder, boxBytes.length);
    builder.add(boxBytes);
    final tagBytes = utf8.encode(tag);
    _encodeRawLength(builder, tagBytes.length);
    builder.add(tagBytes);
    final dataBytes = _encodeMap(data);
    _encodeRawLength(builder, dataBytes.length);
    builder.add(dataBytes);
    return builder.toBytes();
  }

  static Uint8List _encodeMap(Map<String, dynamic> data) {
    final builder = BytesBuilder();
    _encodeValue(builder, data);
    return builder.toBytes();
  }

  static Map<String, dynamic> decodeValue(Uint8List bytes) {
    final reader = ByteData.view(bytes.buffer);
    return _decodeValue(reader, 0).value as Map<String, dynamic>;
  }

  static void _encodeValue(BytesBuilder builder, dynamic value) {
    if (value == null) {
      builder.addByte(typeNULL);
    } else if (value is bool) {
      builder.addByte(typeBOOL);
      builder.addByte(value ? 1 : 0);
    } else if (value is int) {
      builder.addByte(typeINT);
      final bytes = ByteData(8);
      bytes.setInt64(0, value, Endian.little);
      builder.add(bytes.buffer.asUint8List());
    } else if (value is double) {
      builder.addByte(typeDOUBLE);
      final bytes = ByteData(8);
      bytes.setFloat64(0, value, Endian.little);
      builder.add(bytes.buffer.asUint8List());
    } else if (value is String) {
      builder.addByte(typeSTRING);
      final utf8Bytes = utf8.encode(value);
      _encodeRawLength(builder, utf8Bytes.length);
      builder.add(utf8Bytes);
    } else if (value is List) {
      builder.addByte(typeLIST);
      _encodeRawLength(builder, value.length);
      for (var item in value) {
        _encodeValue(builder, item);
      }
    } else if (value is Map<String, dynamic>) {
      builder.addByte(typeMAP);
      _encodeRawLength(builder, value.length);
      for (var entry in value.entries) {
        _encodeValue(builder, entry.key);
        _encodeValue(builder, entry.value);
      }
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  static MapEntry<int, dynamic> _decodeValue(ByteData reader, int offset) {
    final type = reader.getUint8(offset++);
    switch (type) {
      case typeNULL:
        return MapEntry(offset, null);
      case typeBOOL:
        return MapEntry(offset + 1, reader.getUint8(offset) == 1);
      case typeINT:
        return MapEntry(offset + 8, reader.getInt64(offset, Endian.little));
      case typeDOUBLE:
        return MapEntry(offset + 8, reader.getFloat64(offset, Endian.little));
      case typeSTRING:
        final len = reader.getUint32(offset, Endian.little);
        offset += 4;
        final val = utf8.decode(
          Uint8List.view(reader.buffer, reader.offsetInBytes + offset, len),
        );
        return MapEntry(offset + len, val);
      case typeLIST:
        final len = reader.getUint32(offset, Endian.little);
        offset += 4;
        final list = [];
        for (var i = 0; i < len; i++) {
          final res = _decodeValue(reader, offset);
          offset = res.key;
          list.add(res.value);
        }
        return MapEntry(offset, list);
      case typeMAP:
        final len = reader.getUint32(offset, Endian.little);
        offset += 4;
        final map = <String, dynamic>{};
        for (var i = 0; i < len; i++) {
          final kRes = _decodeValue(reader, offset);
          final vRes = _decodeValue(reader, kRes.key);
          offset = vRes.key;
          map[kRes.value as String] = vRes.value;
        }
        return MapEntry(offset, map);
      default:
        throw FormatException('Unknown type: $type');
    }
  }

  static void _encodeRawLength(BytesBuilder builder, int length) {
    final bytes = ByteData(4);
    bytes.setUint32(0, length, Endian.little);
    builder.add(bytes.buffer.asUint8List());
  }
}

class PersistentIndex {
  final File _file;
  Map<String, Map<String, List<int>>> _index = {};

  PersistentIndex(String path) : _file = File(path);

  Future<void> load() async {
    if (await _file.exists()) {
      final bytes = await _file.readAsBytes();
      if (bytes.isNotEmpty) _index = _deserializeIndex(bytes);
    }
  }

  Future<void> save() async {
    final bytes = _serializeIndex(_index);
    await _file.writeAsBytes(bytes);
  }

  void update(String boxId, String tag, int offset, int length) {
    _index[boxId] ??= {};
    _index[boxId]![tag] = [offset, length];
  }

  List<int>? get(String boxId, String tag) => _index[boxId]?[tag];
  Map<String, List<int>>? getBox(String boxId) => _index[boxId];

  int getLastOffset() {
    int maxOffset = 0;
    for (var box in _index.values) {
      for (var addr in box.values) {
        if (addr[0] + addr[1] > maxOffset) maxOffset = addr[0] + addr[1];
      }
    }
    return maxOffset;
  }

  Uint8List _serializeIndex(Map<String, Map<String, List<int>>> index) {
    final builder = BytesBuilder();
    final boxIds = index.keys.toList();
    final bCount = ByteData(4)..setUint32(0, boxIds.length, Endian.little);
    builder.add(bCount.buffer.asUint8List());
    for (var bId in boxIds) {
      final bBytes = utf8.encode(bId);
      builder.add(
        (ByteData(
          4,
        )..setUint32(0, bBytes.length, Endian.little)).buffer.asUint8List(),
      );
      builder.add(bBytes);
      final tags = index[bId]!;
      builder.add(
        (ByteData(
          4,
        )..setUint32(0, tags.length, Endian.little)).buffer.asUint8List(),
      );
      for (var entry in tags.entries) {
        final tBytes = utf8.encode(entry.key);
        builder.add(
          (ByteData(
            4,
          )..setUint32(0, tBytes.length, Endian.little)).buffer.asUint8List(),
        );
        builder.add(tBytes);
        final addr = ByteData(8);
        addr.setUint32(0, entry.value[0], Endian.little);
        addr.setUint32(4, entry.value[1], Endian.little);
        builder.add(addr.buffer.asUint8List());
      }
    }
    return builder.toBytes();
  }

  Map<String, Map<String, List<int>>> _deserializeIndex(Uint8List bytes) {
    final res = <String, Map<String, List<int>>>{};
    final reader = ByteData.view(bytes.buffer);
    int offset = 0;
    if (bytes.length < 4) return res;
    final bCount = reader.getUint32(offset, Endian.little);
    offset += 4;
    for (var i = 0; i < bCount; i++) {
      final bLen = reader.getUint32(offset, Endian.little);
      offset += 4;
      final bId = utf8.decode(
        Uint8List.view(reader.buffer, reader.offsetInBytes + offset, bLen),
      );
      offset += bLen;
      final tCount = reader.getUint32(offset, Endian.little);
      offset += 4;
      final bMap = <String, List<int>>{};
      for (var j = 0; j < tCount; j++) {
        final tLen = reader.getUint32(offset, Endian.little);
        offset += 4;
        final t = utf8.decode(
          Uint8List.view(reader.buffer, reader.offsetInBytes + offset, tLen),
        );
        offset += tLen;
        final aOff = reader.getUint32(offset, Endian.little);
        offset += 4;
        final aLen = reader.getUint32(offset, Endian.little);
        offset += 4;
        bMap[t] = [aOff, aLen];
      }
      res[bId] = bMap;
    }
    return res;
  }
}

class Truck {
  final String id;
  final String path;
  final PersistentIndex _index;
  final LRUCache<String, Map<String, dynamic>> _cache;
  final Map<String, Map<String, dynamic>> _hotCache = {};
  final Map<String, Map<String, Map<String, Set<String>>>> _fieldIndex = {};
  int _compactCounter = 0;
  final int _compactThreshold = 500;
  bool _isCompacting = false;
  RandomAccessFile? _reader;
  RandomAccessFile? _writer;
  Future<void> _lock = Future.value();
  int _dirtyCount = 0;
  final int _saveThreshold = 500;
  bool _isSavingIndex = false;

  Truck(this.id, this.path)
    : _index = PersistentIndex('$path/$id.idx'),
      _cache = LRUCache(10000);

  File get _dataFile => File('$path/$id.dat');

  Future<void> initialize() async {
    await _index.load();
    if (await _dataFile.exists()) {
      await _repair();
      _writer = await _dataFile.open(mode: FileMode.append);
      await _rebuildSearchIndex();
    }
  }

  Future<T> _synchronized<T>(Future<T> Function() action) async {
    await _lock;
    final completer = Completer<T>();
    // ignore: body_might_complete_normally_catch_error
    _lock = completer.future.catchError((_) {});
    try {
      final result = await action();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    }
  }

  Future<void> _rebuildSearchIndex() async {
    final boxes = _index._index.keys;
    for (var bId in boxes) {
      final boxData = _index.getBox(bId);
      if (boxData == null) continue;
      for (var tag in boxData.keys) {
        final data = await read(bId, tag);
        if (data != null) {
          _updateInternalIndex(bId, tag, data);
        }
      }
    }
  }

  void _updateInternalIndex(String bId, String tag, Map<String, dynamic> data) {
    data.forEach((field, value) {
      if (value is String) {
        _fieldIndex[bId] ??= {};
        _fieldIndex[bId]![field] ??= {};
        _fieldIndex[bId]![field]![value] ??= {};
        _fieldIndex[bId]![field]![value]!.add(tag);
      }
    });
  }

  Future<List<Map<String, dynamic>>> queryAdvanced({
    required String bId,
    bool Function(Map<String, dynamic>)? filter,
  }) async {
    final List<Map<String, dynamic>> results = [];
    final boxData = _index.getBox(bId);
    if (boxData == null) return results;
    for (var tag in boxData.keys) {
      final data = await read(bId, tag);
      if (data != null) {
        if (filter == null || filter(data)) {
          results.add(data);
        }
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> query(
    String bId,
    String field,
    String prefix,
  ) async {
    final List<Map<String, dynamic>> results = [];
    final boxIdx = _fieldIndex[bId];
    if (boxIdx == null) return results;
    final fieldIdx = boxIdx[field];
    if (fieldIdx == null) return results;
    for (var entry in fieldIdx.entries) {
      if (entry.key.startsWith(prefix)) {
        for (var tag in entry.value) {
          final data = await read(bId, tag);
          if (data != null) results.add(data);
        }
      }
    }
    return results;
  }

  Future<void> _repair() async {
    final int last = _index.getLastOffset();
    final int actual = await _dataFile.length();
    if (actual > last) {
      final raf = await _dataFile.open(mode: FileMode.read);
      await raf.setPosition(last);
      int pos = last;
      while (pos < actual) {
        try {
          final magic = await raf.readByte();
          if (magic != BinaryEncoder.magicByte) break;
          final bLenBytes = await raf.read(4);
          final bLen = ByteData.view(
            bLenBytes.buffer,
          ).getUint32(0, Endian.little);
          final boxIdBytes = await raf.read(bLen);
          final boxId = utf8.decode(boxIdBytes);
          final tLenBytes = await raf.read(4);
          final tLen = ByteData.view(
            tLenBytes.buffer,
          ).getUint32(0, Endian.little);
          final tagBytes = await raf.read(tLen);
          final tag = utf8.decode(tagBytes);
          final dLenBytes = await raf.read(4);
          final dLen = ByteData.view(
            dLenBytes.buffer,
          ).getUint32(0, Endian.little);
          final dataBytes = await raf.read(dLen);
          final data = BinaryEncoder.decodeValue(dataBytes);
          final total = (await raf.position()) - pos;
          _index.update(boxId, tag, pos, total);
          _updateInternalIndex(boxId, tag, data);
          pos = await raf.position();
        } catch (_) {
          break;
        }
      }
      await raf.close();
      await _index.save();
    }
  }

  Future<void> write(String bId, String t, Map<String, dynamic> v) {
    return _synchronized(() async {
      _writer ??= await _dataFile.open(mode: FileMode.append);
      final off = await _writer!.length();
      final bytes = BinaryEncoder.encode(bId, t, v);
      await _writer!.writeFrom(bytes);
      await _writer!.flush();
      _index.update(bId, t, off, bytes.length);
      _updateInternalIndex(bId, t, v);
      _dirtyCount++;
      _compactCounter++;
      if (_dirtyCount >= _saveThreshold && !_isSavingIndex) _autoSave();
      if (_compactCounter >= _compactThreshold && !_isCompacting) {
        _runAutoCompact();
      }
      final key = '$bId:$t';
      _cache.put(key, v);
      _updateHot(key, v);
    });
  }

  Future<void> batch(String bId, Map<String, Map<String, dynamic>> entries) {
    return _synchronized(() async {
      _writer ??= await _dataFile.open(mode: FileMode.append);
      var off = await _writer!.length();
      for (var entry in entries.entries) {
        final bytes = BinaryEncoder.encode(bId, entry.key, entry.value);
        await _writer!.writeFrom(bytes);
        _index.update(bId, entry.key, off, bytes.length);
        _updateInternalIndex(bId, entry.key, entry.value);
        final key = '$bId:${entry.key}';
        _cache.put(key, entry.value);
        _updateHot(key, entry.value);
        off += bytes.length;
        _dirtyCount++;
        _compactCounter++;
      }
      await _writer!.flush();
      if (_dirtyCount >= _saveThreshold && !_isSavingIndex) _autoSave();
      if (_compactCounter >= _compactThreshold && !_isCompacting) {
        _runAutoCompact();
      }
    });
  }

  void _runAutoCompact() {
    _isCompacting = true;
    _compactCounter = 0;
    compact()
        .then((_) {
          _isCompacting = false;
        })
        .catchError((e) {
          _isCompacting = false;
        });
  }

  void _autoSave() {
    _isSavingIndex = true;
    _dirtyCount = 0;
    // ignore: body_might_complete_normally_catch_error
    _index.save().then((_) => _isSavingIndex = false).catchError((_) {
      _isSavingIndex = false;
    });
  }

  Future<Map<String, dynamic>?> read(String bId, String t) {
    return _synchronized(() async {
      final key = '$bId:$t';
      if (_hotCache.containsKey(key)) return _hotCache[key];
      final c = _cache.get(key);
      if (c != null) {
        _updateHot(key, c);
        return c;
      }
      final addr = _index.get(bId, t);
      if (addr == null) return null;
      _reader ??= await _dataFile.open(mode: FileMode.read);
      await _reader!.setPosition(addr[0]);
      final block = await _reader!.read(addr[1]);
      final blockReader = ByteData.view(block.buffer);
      int offset = 1;
      final boxIdLen = blockReader.getUint32(offset, Endian.little);
      offset += 4 + boxIdLen;
      final tagLen = blockReader.getUint32(offset, Endian.little);
      offset += 4 + tagLen;
      final dataLen = blockReader.getUint32(offset, Endian.little);
      offset += 4;
      final dataBytes = block.sublist(offset, offset + dataLen);
      try {
        final data = BinaryEncoder.decodeValue(dataBytes);
        _cache.put(key, data);
        _updateHot(key, data);
        return data;
      } catch (e) {
        return null;
      }
    });
  }

  Future<Map<String, Map<String, dynamic>>> readBox(String bId) async {
    final res = <String, Map<String, dynamic>>{};
    final box = _index.getBox(bId);
    if (box == null) return res;
    for (var t in box.keys) {
      final d = await read(bId, t);
      if (d != null) res[t] = d;
    }
    return res;
  }

  void _updateHot(String k, Map<String, dynamic> v) {
    if (_hotCache.length >= 100) _hotCache.remove(_hotCache.keys.first);
    _hotCache[k] = v;
  }

  Future<void> compact() {
    return _synchronized(() async {
      final tempFile = File('$path/${id}_temp.dat');
      final IOSink sink = tempFile.openWrite();
      final newIndex = PersistentIndex('$path/${id}_temp.idx');
      int currentOffset = 0;
      final boxes = _index._index.keys.toList();
      for (var bId in boxes) {
        final tags = _index._index[bId]?.keys.toList() ?? [];
        for (var tag in tags) {
          final data = await read(bId, tag);
          if (data != null) {
            final bytes = BinaryEncoder.encode(bId, tag, data);
            sink.add(bytes);
            newIndex.update(bId, tag, currentOffset, bytes.length);
            currentOffset += bytes.length;
          }
        }
      }
      await sink.flush();
      await sink.close();
      await _reader?.close();
      await _writer?.close();
      _reader = null;
      _writer = null;
      final oldDataFile = _dataFile;
      final oldIdxFile = File(_index._file.path);
      if (await oldDataFile.exists()) await oldDataFile.delete();
      if (await oldIdxFile.exists()) await oldIdxFile.delete();
      await tempFile.rename(oldDataFile.path);
      await File(newIndex._file.path).rename(oldIdxFile.path);
      _index._index = newIndex._index;
      await _index.save();
      _writer = await _dataFile.open(mode: FileMode.append);
    });
  }

  Future<void> close() async {
    await _index.save();
    await _reader?.close();
    await _writer?.close();
  }
}

class TruckIsolate {
  late Truck _truck;

  Future<void> init(String id, String path) async {
    _truck = Truck(id, path);
    await _truck.initialize();
  }

  Future<void> write(
    String boxId,
    String tag,
    Map<String, dynamic> value,
  ) async {
    await _truck.write(boxId, tag, value);
  }

  Future<Map<String, dynamic>?> read(String boxId, String tag) async {
    return await _truck.read(boxId, tag);
  }

  Future<void> batch(
    String boxId,
    Map<String, Map<String, dynamic>> entries,
  ) async {
    await _truck.batch(boxId, entries);
  }

  Future<Map<String, Map<String, dynamic>>> readBox(String boxId) async {
    return await _truck.readBox(boxId);
  }

  Future<List<Map<String, dynamic>>> query(
    String boxId,
    String field,
    String prefix,
  ) async {
    return await _truck.query(boxId, field, prefix);
  }

  Future<List<Map<String, dynamic>>> queryAdvanced({
    required String boxId,
    bool Function(Map<String, dynamic>)? filter,
  }) async {
    return await _truck.queryAdvanced(bId: boxId, filter: filter);
  }

  Future<void> compact() async {
    await _truck.compact();
  }

  Future<void> close() async {
    await _truck.close();
  }

  Future<bool> contains(String boxId, String tag) async {
    return await _truck.read(boxId, tag) != null;
  }
}

class TruckProxy {
  final String id;
  final String path;
  late SendPort _sendPort;
  final Map<int, Completer<dynamic>> _completers = {};
  int _messageId = 0;
  final ReceivePort _receivePort = ReceivePort();

  TruckProxy(this.id, this.path);

  Future<void> initialize() async {
    await Isolate.spawn(_startTruckIsolate, _receivePort.sendPort);
    final completer = Completer<void>();
    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        _sendCommand('init', {'id': id, 'path': path}).then((_) {
          completer.complete();
        });
      } else if (message is Map) {
        final id = message['id'] as int;
        final completer = _completers[id];
        if (completer != null) {
          if (message.containsKey('result')) {
            completer.complete(message['result']);
          } else if (message.containsKey('error')) {
            completer.completeError(Exception(message['error']));
          }
          _completers.remove(id);
        }
      }
    });
    await completer.future;
  }

  static void _startTruckIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    final truckIsolate = TruckIsolate();
    receivePort.listen((message) async {
      if (message is Map) {
        final command = message['command'] as String;
        final params = message['params'] as Map<String, dynamic>;
        final id = message['id'] as int;
        try {
          dynamic result;
          switch (command) {
            case 'init':
              await truckIsolate.init(
                params['id'] as String,
                params['path'] as String,
              );
              result = null;
              break;
            case 'write':
              await truckIsolate.write(
                params['boxId'] as String,
                params['tag'] as String,
                params['value'] as Map<String, dynamic>,
              );
              result = null;
              break;
            case 'read':
              result = await truckIsolate.read(
                params['boxId'] as String,
                params['tag'] as String,
              );
              break;
            case 'batch':
              await truckIsolate.batch(
                params['boxId'] as String,
                params['entries'] as Map<String, Map<String, dynamic>>,
              );
              result = null;
              break;
            case 'readBox':
              result = await truckIsolate.readBox(params['boxId'] as String);
              break;
            case 'query':
              result = await truckIsolate.query(
                params['boxId'] as String,
                params['field'] as String,
                params['prefix'] as String,
              );
              break;
            case 'queryAdvanced':
              result = await truckIsolate.queryAdvanced(
                boxId: params['boxId'] as String,
                filter:
                    params['filter'] as bool Function(Map<String, dynamic>)?,
              );
              break;
            case 'compact':
              await truckIsolate.compact();
              result = null;
              break;
            case 'close':
              await truckIsolate.close();
              result = null;
              break;
            case 'contains':
              result = await truckIsolate.contains(
                params['boxId'] as String,
                params['tag'] as String,
              );
              break;
            default:
              throw Exception('Unknown command: $command');
          }
          sendPort.send({'id': id, 'result': result});
        } catch (e) {
          sendPort.send({'id': id, 'error': e.toString()});
        }
      }
    });
  }

  Future<dynamic> _sendCommand(String command, Map<String, dynamic> params) {
    final id = _messageId++;
    final completer = Completer<dynamic>();
    _completers[id] = completer;
    _sendPort.send({'command': command, 'params': params, 'id': id});
    return completer.future;
  }

  Future<void> write(
    String boxId,
    String tag,
    Map<String, dynamic> value,
  ) async {
    return await _sendCommand('write', {
      'boxId': boxId,
      'tag': tag,
      'value': value,
    });
  }

  Future<Map<String, dynamic>?> read(String boxId, String tag) async {
    return await _sendCommand('read', {'boxId': boxId, 'tag': tag});
  }

  Future<void> batch(
    String boxId,
    Map<String, Map<String, dynamic>> entries,
  ) async {
    return await _sendCommand('batch', {'boxId': boxId, 'entries': entries});
  }

  Future<Map<String, Map<String, dynamic>>> readBox(String boxId) async {
    return await _sendCommand('readBox', {'boxId': boxId});
  }

  Future<List<Map<String, dynamic>>> query(
    String boxId,
    String field,
    String prefix,
  ) async {
    return await _sendCommand('query', {
      'boxId': boxId,
      'field': field,
      'prefix': prefix,
    });
  }

  Future<List<Map<String, dynamic>>> queryAdvanced({
    required String boxId,
    bool Function(Map<String, dynamic>)? filter,
  }) async {
    final boxData = await readBox(boxId);
    final results = <Map<String, dynamic>>[];
    for (var entry in boxData.values) {
      if (filter == null || filter(entry)) {
        results.add(entry);
      }
    }
    return results;
  }

  Future<void> compact() async {
    return await _sendCommand('compact', {});
  }

  Future<void> close() async {
    return await _sendCommand('close', {});
  }

  Future<bool> contains(String boxId, String tag) async {
    return await _sendCommand('contains', {'boxId': boxId, 'tag': tag});
  }
}

class Zeytin {
  final String rootPath;
  final LRUCache<String, Map<String, dynamic>> _memoryCache;
  final Map<String, TruckProxy> _activeTrucks = {};

  Zeytin(this.rootPath, {int cacheSize = 50000})
    : _memoryCache = LRUCache(cacheSize) {
    Directory(rootPath).createSync(recursive: true);
  }
  final StreamController<Map<String, dynamic>> _changeController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get changes => _changeController.stream;
  Future<TruckProxy> _resolveTruck({required String truckId}) async {
    if (_activeTrucks.containsKey(truckId)) {
      return _activeTrucks[truckId]!;
    }
    final truck = TruckProxy(truckId, rootPath);
    await truck.initialize();
    _activeTrucks[truckId] = truck;
    return truck;
  }

  String _generateCacheKey({
    required String truckId,
    required String boxId,
    required String tag,
  }) {
    return '$truckId:$boxId:$tag';
  }

  Future<void> delete({
    required String truckId,
    required String boxId,
    required String tag,
  }) async {
    final key = _generateCacheKey(truckId: truckId, boxId: boxId, tag: tag);
    _memoryCache.remove(key);
    _changeController.add({
      "truckId": truckId,
      "boxId": boxId,
      "tag": tag,
      "op": "DELETE",
    });
  }

  Future<void> deleteBox({
    required String truckId,
    required String boxId,
  }) async {
    final truck = await _resolveTruck(truckId: truckId);
    final boxData = await truck.readBox(boxId);
    for (var tag in boxData.keys) {
      final key = _generateCacheKey(truckId: truckId, boxId: boxId, tag: tag);
      _memoryCache.remove(key);
    }
    _changeController.add({
      "truckId": truckId,
      "boxId": boxId,
      "op": "DELETE_BOX",
    });
  }

  Future<void> deleteTruck({required String truckId}) async {
    if (_activeTrucks.containsKey(truckId)) {
      await _activeTrucks[truckId]!.close();
      _activeTrucks.remove(truckId);
    }
    final dataFile = File('$rootPath/$truckId.dat');
    final indexFile = File('$rootPath/$truckId.idx');
    if (await dataFile.exists()) await dataFile.delete();
    if (await indexFile.exists()) await indexFile.delete();
  }

  List<String> getAllTruck() {
    final dir = Directory(rootPath);
    return dir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.dat'))
        .map(
          (entity) => entity.path
              .split(Platform.pathSeparator)
              .last
              .replaceAll('.dat', ''),
        )
        .toList();
  }

  Map<String, TruckProxy> getAllBox() {
    return Map.unmodifiable(_activeTrucks);
  }

  Future<void> deleteAll() async {
    for (var truck in _activeTrucks.values) {
      await truck.close();
    }
    _activeTrucks.clear();
    _memoryCache.clear();
    final dir = Directory(rootPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  Future<void> put({
    required String truckId,
    required String boxId,
    required String tag,
    required Map<String, dynamic> value,
  }) async {
    final truck = await _resolveTruck(truckId: truckId);
    await truck.write(boxId, tag, value);
    _memoryCache.put(
      _generateCacheKey(truckId: truckId, boxId: boxId, tag: tag),
      value,
    );
    _changeController.add({
      "truckId": truckId,
      "boxId": boxId,
      "tag": tag,
      "op": "PUT",
      "value": value,
    });
  }

  Future<void> putBatch({
    required String truckId,
    required String boxId,
    required Map<String, Map<String, dynamic>> entries,
  }) async {
    final truck = await _resolveTruck(truckId: truckId);
    await truck.batch(boxId, entries);
    for (var entry in entries.entries) {
      _memoryCache.put(
        _generateCacheKey(truckId: truckId, boxId: boxId, tag: entry.key),
        entry.value,
      );
    }
    _changeController.add({
      "truckId": truckId,
      "boxId": boxId,
      "op": "BATCH",
      "entries": entries,
    });
  }

  Future<Map<String, dynamic>?> get({
    required String truckId,
    required String boxId,
    required String tag,
  }) async {
    final cacheKey = _generateCacheKey(
      truckId: truckId,
      boxId: boxId,
      tag: tag,
    );
    final cachedValue = _memoryCache.get(cacheKey);
    if (cachedValue != null) return cachedValue;
    final truck = await _resolveTruck(truckId: truckId);
    final data = await truck.read(boxId, tag);
    if (data != null) {
      _memoryCache.put(cacheKey, data);
    }
    return data;
  }

  Future<Map<String, Map<String, dynamic>>> getBox({
    required String truckId,
    required String boxId,
  }) async {
    final truck = await _resolveTruck(truckId: truckId);
    final boxData = await truck.readBox(boxId);
    for (var entry in boxData.entries) {
      _memoryCache.put(
        _generateCacheKey(truckId: truckId, boxId: boxId, tag: entry.key),
        entry.value,
      );
    }
    return boxData;
  }

  Future<List<Map<String, dynamic>>> search(
    String truckId,
    String boxId,
    String field,
    String prefix,
  ) async {
    final truck = await _resolveTruck(truckId: truckId);
    return await truck.query(boxId, field, prefix);
  }

  Future<void> compactTruck({required String truckId}) async {
    if (_activeTrucks.containsKey(truckId)) {
      final truck = _activeTrucks[truckId]!;
      await truck.compact();
      _memoryCache.clear();
    }
  }

  Future<List<Map<String, dynamic>>> filter(
    String truckId,
    String boxId,
    bool Function(Map<String, dynamic>) predicate,
  ) async {
    final truck = await _resolveTruck(truckId: truckId);
    return await truck.queryAdvanced(boxId: boxId, filter: predicate);
  }

  Future<bool> contains(String truckId, String boxId, String tag) async {
    if (_memoryCache.contains(
      _generateCacheKey(truckId: truckId, boxId: boxId, tag: tag),
    )) {
      return true;
    }
    final truck = await _resolveTruck(truckId: truckId);
    final data = await truck.read(boxId, tag);
    return data != null;
  }

  Future<bool> existsTruck({required String truckId}) async {
    final dataFile = File('$rootPath/$truckId.dat');
    return await dataFile.exists();
  }

  Future<bool> existsBox({
    required String truckId,
    required String boxId,
  }) async {
    if (!await existsTruck(truckId: truckId)) return false;
    final truck = await _resolveTruck(truckId: truckId);
    final boxData = await truck.readBox(boxId);
    return boxData.isNotEmpty;
  }

  Future<bool> existsTag({
    required String truckId,
    required String boxId,
    required String tag,
  }) async {
    final cacheKey = _generateCacheKey(
      truckId: truckId,
      boxId: boxId,
      tag: tag,
    );
    if (_memoryCache.contains(cacheKey)) return true;
    if (!await existsTruck(truckId: truckId)) return false;
    final truck = await _resolveTruck(truckId: truckId);
    return await truck.contains(boxId, tag);
  }

  Future<void> createTruck({required String truckId}) async {
    if (await existsTruck(truckId: truckId)) return;
    final truck = TruckProxy(truckId, rootPath);
    await truck.initialize();
    _activeTrucks[truckId] = truck;
  }

  Future<void> close() async {
    for (var truck in _activeTrucks.values) {
      await truck.close();
    }
    _activeTrucks.clear();
    _memoryCache.clear();
  }
}

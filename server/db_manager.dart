import 'dart:io';
import 'dart:convert';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/account.dart';

const String _kReset = '\x1B[0m';
const String _kBold = '\x1B[1m';
const String _kRed = '\x1B[31m';
const String _kGreen = '\x1B[32m';
const String _kYellow = '\x1B[33m';
const String _kCyan = '\x1B[36m';
const String _kMagenta = '\x1B[35m';

late Zeytin zeytin;
String? currentTruckId;
String? currentBoxId;

void main() async {
  final root = _getProjectRoot();
  zeytin = Zeytin('$root/zeytin');

  print('$_kGreen[DB] Zeytin Database Manager initialized.$_kReset\n');

  while (true) {
    await _showMainMenu();
  }
}

Future<void> _showMainMenu() async {
  print('\x1B[2J\x1B[0;0H');
  print(
    _kCyan +
        r'''
  _____                _     _           
 |__  /   ___   _   _  | |_   (_)  _ __  
    / /   / _ \ | | | | | __| | | | '_ \ 
   / /_  |  __/ | |_| | | |_  | | | | | |
  /____|  \___|  \__, |  \__| |_| |_| |_|
                 |___/
      DATABASE MANAGER
''' +
        _kReset,
  );

  if (currentTruckId != null) {
    print('$_kGreen[TRUCK] $currentTruckId$_kReset');
  }
  if (currentBoxId != null) {
    print('$_kYellow[BOX] $currentBoxId$_kReset');
  }
  print('');

  print('${_kBold}ACCOUNT MANAGEMENT$_kReset');
  print('1. ${_kGreen}List All Accounts$_kReset');
  print('2. ${_kGreen}Create New Account$_kReset');
  print('3. ${_kYellow}Select Account (Truck)$_kReset');
  print('4. ${_kRed}Delete Account$_kReset');
  print('');

  print('${_kBold}BOX MANAGEMENT$_kReset');
  print('5. ${_kCyan}List Boxes in Current Truck$_kReset');
  print('6. ${_kYellow}Select Box$_kReset');
  print('7. ${_kRed}Delete Box$_kReset');
  print('');

  print('${_kBold}DATA OPERATIONS$_kReset');
  print('8. ${_kCyan}List All Data in Current Box$_kReset');
  print('9. ${_kCyan}Get Specific Data by Tag$_kReset');
  print('10. ${_kMagenta}Search in Current Box$_kReset');
  print('11. ${_kMagenta}Search Across All Boxes$_kReset');
  print('12. ${_kYellow}Add Data to Box$_kReset');
  print('13. ${_kRed}Delete Data by Tag$_kReset');
  print('');

  print('${_kBold}SYSTEM$_kReset');
  print('14. ${_kCyan}Show System Stats$_kReset');
  print('0. Exit');

  stdout.write('\n${_kBold}Choice: $_kReset');
  String? choice = stdin.readLineSync()?.trim();

  switch (choice) {
    case '1':
      await _listAllAccounts();
      break;
    case '2':
      await _createAccount();
      break;
    case '3':
      await _selectTruck();
      break;
    case '4':
      await _deleteAccount();
      break;
    case '5':
      await _listBoxes();
      break;
    case '6':
      await _selectBox();
      break;
    case '7':
      await _deleteBox();
      break;
    case '8':
      await _listDataInBox();
      break;
    case '9':
      await _getDataByTag();
      break;
    case '10':
      await _searchInBox();
      break;
    case '11':
      await _searchAcrossBoxes();
      break;
    case '12':
      await _addData();
      break;
    case '13':
      await _deleteData();
      break;
    case '14':
      await _showStats();
      break;
    case '0':
      await zeytin.close();
      exit(0);
    default:
      print('${_kRed}Invalid selection.$_kReset');
      sleep(Duration(seconds: 1));
      return;
  }

  stdout.write('\n${_kYellow}Press ENTER to continue...$_kReset');
  stdin.readLineSync();
}

Future<void> _listAllAccounts() async {
  print('\n$_kCyan[ACCOUNTS] Listing all accounts...$_kReset\n');

  final trucks = zeytin.getAllTruck();
  if (trucks.isEmpty) {
    print('${_kYellow}No accounts found.$_kReset');
    return;
  }

  print('${_kBold}Total Accounts: ${trucks.length}$_kReset\n');

  for (var truckId in trucks) {
    final data = await zeytin.get(
      truckId: 'system',
      boxId: 'trucks',
      tag: truckId,
    );

    if (data != null) {
      print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
      print('${_kBold}Truck ID:$_kReset $truckId');
      print('${_kBold}Email:$_kReset ${data['email']}');
      print('${_kBold}Created:$_kReset ${data['createdAt']}');
      if (data['passwordUpdatedAt'] != null) {
        print('${_kBold}Password Updated:$_kReset ${data['passwordUpdatedAt']}');
      }
    }
  }
  print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
}

Future<void> _createAccount() async {
  print('\n$_kGreen[CREATE] New Account$_kReset\n');

  stdout.write('Email: ');
  final email = stdin.readLineSync()?.trim();
  if (email == null || email.isEmpty) {
    print('${_kRed}Email cannot be empty.$_kReset');
    return;
  }

  stdout.write('Password: ');
  final password = stdin.readLineSync()?.trim();
  if (password == null || password.isEmpty) {
    print('${_kRed}Password cannot be empty.$_kReset');
    return;
  }

  final response = await ZeytinAccounts.createAccount(zeytin, email, password);

  if (response.isSuccess) {
    print('\n$_kGreen[SUCCESS] Account created!$_kReset');
    print('${_kBold}Truck ID:$_kReset ${response.data!['id']}');
    print('${_kBold}Email:$_kReset $email');
  } else {
    print('\n$_kRed[ERROR] ${response.error}$_kReset');
  }
}

Future<void> _selectTruck() async {
  print('\n$_kYellow[SELECT] Choose a truck$_kReset\n');

  final trucks = zeytin.getAllTruck();
  if (trucks.isEmpty) {
    print('${_kYellow}No accounts found.$_kReset');
    return;
  }

  for (var i = 0; i < trucks.length; i++) {
    final data = await zeytin.get(
      truckId: 'system',
      boxId: 'trucks',
      tag: trucks[i],
    );
    print('${i + 1}. ${data?['email']} (${trucks[i]})');
  }

  stdout.write('\nSelect number: ');
  final choice = stdin.readLineSync()?.trim();
  final index = int.tryParse(choice ?? '');

  if (index != null && index > 0 && index <= trucks.length) {
    currentTruckId = trucks[index - 1];
    currentBoxId = null;
    print('$_kGreen[SELECTED] Truck: $currentTruckId$_kReset');
  } else {
    print('${_kRed}Invalid selection.$_kReset');
  }
}

Future<void> _deleteAccount() async {
  if (currentTruckId == null) {
    print('${_kRed}Please select a truck first (option 3).$_kReset');
    return;
  }

  print('\n$_kRed[DELETE] Account: $currentTruckId$_kReset');
  stdout.write('Type "DELETE" to confirm: ');
  if (stdin.readLineSync() != 'DELETE') {
    print('Aborted.');
    return;
  }

  // Delete truck data
  await zeytin.delete(
    truckId: 'system',
    boxId: 'trucks',
    tag: currentTruckId!,
  );

  // Delete truck directory
  final truckDir = Directory('${zeytin.rootPath}/$currentTruckId');
  if (await truckDir.exists()) {
    await truckDir.delete(recursive: true);
  }

  print('$_kGreen[DELETED] Account removed.$_kReset');
  currentTruckId = null;
  currentBoxId = null;
}

Future<void> _listBoxes() async {
  if (currentTruckId == null) {
    print('${_kRed}Please select a truck first (option 3).$_kReset');
    return;
  }

  print('\n$_kCyan[BOXES] Listing boxes in truck: $currentTruckId$_kReset\n');

  final boxes = await _getAllBoxes(currentTruckId!);
  if (boxes.isEmpty) {
    print('${_kYellow}No boxes found.$_kReset');
    return;
  }

  print('${_kBold}Total Boxes: ${boxes.length}$_kReset\n');
  for (var box in boxes) {
    final tags = await _getAllTags(currentTruckId!, box);
    print('$_kCyan▸$_kReset ${_kBold}$box$_kReset ($tags items)');
  }
}

Future<void> _selectBox() async {
  if (currentTruckId == null) {
    print('${_kRed}Please select a truck first (option 3).$_kReset');
    return;
  }

  stdout.write('\nBox name: ');
  final boxName = stdin.readLineSync()?.trim();
  if (boxName == null || boxName.isEmpty) {
    print('${_kRed}Box name cannot be empty.$_kReset');
    return;
  }

  final boxes = await _getAllBoxes(currentTruckId!);
  if (boxes.contains(boxName)) {
    currentBoxId = boxName;
    print('$_kGreen[SELECTED] Box: $currentBoxId$_kReset');
  } else {
    print('${_kYellow}Box not found. It will be created when you add data.$_kReset');
    currentBoxId = boxName;
  }
}

Future<void> _deleteBox() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  print('\n$_kRed[DELETE] Box: $currentBoxId$_kReset');
  stdout.write('Type "DELETE" to confirm: ');
  if (stdin.readLineSync() != 'DELETE') {
    print('Aborted.');
    return;
  }

  await zeytin.deleteBox(truckId: currentTruckId!, boxId: currentBoxId!);
  print('$_kGreen[DELETED] Box removed.$_kReset');
  currentBoxId = null;
}

Future<void> _listDataInBox() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  print('\n$_kCyan[DATA] Listing all data in box: $currentBoxId$_kReset\n');

  final boxData = await zeytin.getBox(
    truckId: currentTruckId!,
    boxId: currentBoxId!,
  );

  if (boxData.isEmpty) {
    print('${_kYellow}No data found.$_kReset');
    return;
  }

  print('${_kBold}Total Items: ${boxData.length}$_kReset\n');

  for (var entry in boxData.entries) {
    print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
    print('${_kBold}Tag:$_kReset ${entry.key}');
    print('${_kBold}Data:$_kReset');
    _prettyPrintJson(entry.value);
  }
  print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
}

Future<void> _getDataByTag() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  stdout.write('\nTag name: ');
  final tag = stdin.readLineSync()?.trim();
  if (tag == null || tag.isEmpty) {
    print('${_kRed}Tag cannot be empty.$_kReset');
    return;
  }

  final data = await zeytin.get(
    truckId: currentTruckId!,
    boxId: currentBoxId!,
    tag: tag,
  );

  if (data != null) {
    print('\n$_kGreen[FOUND] Data for tag: $tag$_kReset\n');
    _prettyPrintJson(data);
  } else {
    print('${_kYellow}No data found for tag: $tag$_kReset');
  }
}

Future<void> _searchInBox() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  stdout.write('\nField name: ');
  final field = stdin.readLineSync()?.trim();
  if (field == null || field.isEmpty) {
    print('${_kRed}Field cannot be empty.$_kReset');
    return;
  }

  stdout.write('Search prefix: ');
  final prefix = stdin.readLineSync()?.trim();
  if (prefix == null || prefix.isEmpty) {
    print('${_kRed}Prefix cannot be empty.$_kReset');
    return;
  }

  print('\n$_kMagenta[SEARCH] Searching in box: $currentBoxId$_kReset\n');

  final results = await zeytin.search(
    currentTruckId!,
    currentBoxId!,
    field,
    prefix,
  );

  if (results.isEmpty) {
    print('${_kYellow}No results found.$_kReset');
    return;
  }

  print('${_kBold}Found ${results.length} results:$_kReset\n');
  for (var result in results) {
    print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
    _prettyPrintJson(result);
  }
  print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
}

Future<void> _searchAcrossBoxes() async {
  if (currentTruckId == null) {
    print('${_kRed}Please select a truck first (option 3).$_kReset');
    return;
  }

  stdout.write('\nField name: ');
  final field = stdin.readLineSync()?.trim();
  if (field == null || field.isEmpty) {
    print('${_kRed}Field cannot be empty.$_kReset');
    return;
  }

  stdout.write('Search prefix: ');
  final prefix = stdin.readLineSync()?.trim();
  if (prefix == null || prefix.isEmpty) {
    print('${_kRed}Prefix cannot be empty.$_kReset');
    return;
  }

  print('\n$_kMagenta[SEARCH] Searching across all boxes...$_kReset\n');

  final boxes = await _getAllBoxes(currentTruckId!);
  var totalResults = 0;

  for (var box in boxes) {
    final results = await zeytin.search(currentTruckId!, box, field, prefix);
    if (results.isNotEmpty) {
      print('$_kCyan▸ Box: $box (${results.length} results)$_kReset');
      totalResults += results.length;

      for (var result in results) {
        print('$_kGreen━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_kReset');
        _prettyPrintJson(result);
      }
    }
  }

  if (totalResults == 0) {
    print('${_kYellow}No results found.$_kReset');
  } else {
    print('\n${_kBold}Total results: $totalResults$_kReset');
  }
}

Future<void> _addData() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  stdout.write('\nTag name: ');
  final tag = stdin.readLineSync()?.trim();
  if (tag == null || tag.isEmpty) {
    print('${_kRed}Tag cannot be empty.$_kReset');
    return;
  }

  print('Enter JSON data (or type line by line, empty line to finish):');
  final lines = <String>[];
  while (true) {
    final line = stdin.readLineSync();
    if (line == null || line.trim().isEmpty) break;
    lines.add(line);
  }

  final jsonString = lines.join('\n');
  try {
    final data = jsonDecode(jsonString);
    await zeytin.put(
      truckId: currentTruckId!,
      boxId: currentBoxId!,
      tag: tag,
      value: data,
    );
    print('$_kGreen[SUCCESS] Data added.$_kReset');
  } catch (e) {
    print('$_kRed[ERROR] Invalid JSON: $e$_kReset');
  }
}

Future<void> _deleteData() async {
  if (currentTruckId == null || currentBoxId == null) {
    print('${_kRed}Please select a truck and box first.$_kReset');
    return;
  }

  stdout.write('\nTag name to delete: ');
  final tag = stdin.readLineSync()?.trim();
  if (tag == null || tag.isEmpty) {
    print('${_kRed}Tag cannot be empty.$_kReset');
    return;
  }

  stdout.write('Type "DELETE" to confirm: ');
  if (stdin.readLineSync() != 'DELETE') {
    print('Aborted.');
    return;
  }

  await zeytin.delete(
    truckId: currentTruckId!,
    boxId: currentBoxId!,
    tag: tag,
  );
  print('$_kGreen[DELETED] Data removed.$_kReset');
}

Future<void> _showStats() async {
  print('\n$_kCyan[STATS] System Statistics$_kReset\n');

  final trucks = zeytin.getAllTruck();
  print('${_kBold}Total Accounts:$_kReset ${trucks.length}');

  var totalBoxes = 0;
  var totalData = 0;

  for (var truck in trucks) {
    final boxes = await _getAllBoxes(truck);
    totalBoxes += boxes.length;

    for (var box in boxes) {
      final tags = await _getAllTags(truck, box);
      totalData += tags;
    }
  }

  print('${_kBold}Total Boxes:$_kReset $totalBoxes');
  print('${_kBold}Total Data Items:$_kReset $totalData');
  print('${_kBold}Database Path:$_kReset ${zeytin.rootPath}');
}

void _prettyPrintJson(dynamic data) {
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(data));
}

String _getProjectRoot() {
  final scriptPath = Platform.script.toFilePath();
  final currentDir = Directory(scriptPath).parent.path;
  if (currentDir.endsWith('server')) {
    return Directory(currentDir).parent.path;
  }
  return currentDir;
}

// Helper functions to get box and tag information
Future<List<String>> _getAllBoxes(String truckId) async {
  final truckDir = Directory('${zeytin.rootPath}/$truckId/storage');
  if (!await truckDir.exists()) return [];

  final boxes = <String>[];
  await for (var entity in truckDir.list()) {
    if (entity is Directory) {
      boxes.add(entity.path.split(Platform.pathSeparator).last);
    }
  }
  return boxes;
}

Future<int> _getAllTags(String truckId, String boxId) async {
  final boxData = await zeytin.getBox(truckId: truckId, boxId: boxId);
  return boxData.length;
}

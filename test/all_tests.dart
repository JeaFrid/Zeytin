import 'dart:io';

import 'account_test.dart' as account_test;
import 'admin_test.dart' as admin_test;
import 'db_manager_test.dart' as db_manager_test;
import 'engine_test.dart' as engine_test;
import 'gatekeeper_test.dart' as gatekeeper_test;
import 'ip_test.dart' as ip_test;
import 'random_code_test.dart' as random_code_test;
import 'response_test.dart' as response_test;
import 'tokener_test.dart' as tokener_test;

Future<void> cleanupTestData() async {
  final testDirs = ['test_data', 'test_trucks', 'test_storage'];
  for (var dirPath in testDirs) {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

void main() async {
  await cleanupTestData();

  response_test.main();
  random_code_test.main();
  ip_test.main();
  tokener_test.main();
  gatekeeper_test.main();
  engine_test.main();
  account_test.main();
  admin_test.main();
  db_manager_test.main();

  await cleanupTestData();
}

import 'dart:io';
import 'dart:async';

const String _kReset = '\x1B[0m';
const String _kBold = '\x1B[1m';
const String _kRed = '\x1B[31m';
const String _kGreen = '\x1B[32m';
const String _kYellow = '\x1B[33m';
const String _kCyan = '\x1B[36m';

const String logFile = 'zeytin.log';
const String pidFile = 'server.pid';
const String binaryPath = 'bin/server.exe';

void main() async {
  while (true) {
    print('\x1B[2J\x1B[0;0H');
    print(
      _kCyan +
          r'''
  _____                 _     _           _ 
 |__  /   ___   _   _  | |_  (_)  _ __   | |
   / /   / _ \ | | | | | __| | | | '_ \  | |
  / /_  |  __/ | |_| | | |_  | | | | | | |_|
 /____|  \___|  \__, |  \__| |_| |_| |_| (_)
                |___/
''' +
          _kReset,
    );

    print('1. ${_kGreen}Start Test Mode (JIT)$_kReset');
    print('2. ${_kGreen}Start Live Mode (AOT Compilation)$_kReset');
    print('3. ${_kYellow}Watch Logs (tail -f)$_kReset');
    print('4. ${_kRed}Stop Server$_kReset');
    print('5. ${_kCyan}Update Dependencies (Dart)$_kReset');
    print('6. ${_kYellow}Clear Database & Storage$_kReset');
    print('7. ${_kCyan}Nginx & SSL (Certbot) Setup$_kReset');
    print('8. ${_kRed}Remove Nginx Config$_kReset');
    print('0. Exit');

    stdout.write('\n${_kBold}Choice: $_kReset');
    String? choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        await _startTestMode();
        break;
      case '2':
        await _startLiveMode();
        break;
      case '3':
        await _watchLogs();
        break;
      case '4':
        await _stopServer();
        break;
      case '5':
        await _updateDeps();
        break;
      case '6':
        await _cleanDatabase();
        break;
      case '7':
        await _setupNginx();
        break;
      case '8':
        await _removeNginx();
        break;
      case '0':
        exit(0);
      default:
        print('Invalid selection.');
        sleep(Duration(seconds: 1));
    }

    if (choice != '1' && choice != '3') {
      stdout.write('\nPress ENTER to continue...');
      stdin.readLineSync();
    }
  }
}

Future<void> _startTestMode() async {
  print('\n$_kGreen[TEST] Starting JIT...$_kReset');
  var process = await Process.start(
    'dart',
    ['bin/server.dart'],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _getProjectRoot(),
  );
  await process.exitCode;
}

Future<void> _startLiveMode() async {
  print('\n$_kCyan[BUILD] Compiling AOT binary...$_kReset');
  final root = _getProjectRoot();
  var res = await Process.run('dart', [
    'compile',
    'exe',
    'bin/server.dart',
    '-o',
    binaryPath,
  ], workingDirectory: root);

  if (res.exitCode != 0) {
    print('$_kRed[ERROR] Build failed: ${res.stderr}$_kReset');
    return;
  }

  var shellCmd = 'nohup ./$binaryPath > $logFile 2>&1 & echo \$! > $pidFile';
  await Process.run('bash', ['-c', shellCmd], workingDirectory: root);
  print('$_kGreen[SUCCESS] Server started in background.$_kReset');
}

Future<void> _stopServer() async {
  final root = _getProjectRoot();
  final pFile = File('$root/$pidFile');
  if (pFile.existsSync()) {
    String pid = pFile.readAsStringSync().trim();
    await Process.run('kill', [pid]);
    pFile.deleteSync();
    print('$_kGreen[STOP] Server (PID: $pid) stopped.$_kReset');
  } else {
    await Process.run('pkill', ['-f', binaryPath]);
    print('$_kYellow[INFO] Forced stop performed.$_kReset');
  }
}

Future<void> _watchLogs() async {
  final file = File('${_getProjectRoot()}/$logFile');
  if (!file.existsSync()) file.createSync();
  var process = await Process.start('tail', [
    '-f',
    file.path,
  ], mode: ProcessStartMode.inheritStdio);
  await process.exitCode;
}

Future<void> _updateDeps() async {
  print('\n$_kCyan[UPDATE] Updating Dart dependencies...$_kReset');
  var process = await Process.start(
    'dart',
    ['pub', 'get'],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _getProjectRoot(),
  );
  await process.exitCode;
}

Future<void> _cleanDatabase() async {
  stdout.write('Confirm deletion of ALL DATA? (y/n): ');
  if (stdin.readLineSync()?.toLowerCase() != 'y') return;
  await _stopServer();
  var dbDir = Directory('${_getProjectRoot()}/zeytin');
  if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  print('$_kRed[CLEAN] Database folder removed.$_kReset');
}

Future<void> _setupNginx() async {
  final installScript = File('${_getProjectRoot()}/server/install.sh');
  if (!installScript.existsSync()) {
    print('$_kRed[ERROR] install.sh not found!$_kReset');
    return;
  }
  var process = await Process.start(
    'bash',
    [installScript.path],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _getProjectRoot(),
  );
  await process.exitCode;
}

Future<void> _removeNginx() async {
  stdout.write('Confirm removing Nginx config for Zeytin? (y/n): ');
  if (stdin.readLineSync()?.toLowerCase() != 'y') return;

  await Process.run('sudo', ['rm', '/etc/nginx/sites-available/zeytin']);
  await Process.run('sudo', ['rm', '/etc/nginx/sites-enabled/zeytin']);
  await Process.run('sudo', ['systemctl', 'restart', 'nginx']);

  print('$_kGreen[SUCCESS] Nginx configuration removed.$_kReset');
}

String _getProjectRoot() {
  final scriptPath = Platform.script.toFilePath();
  final currentDir = Directory(scriptPath).parent.path;
  if (currentDir.endsWith('server')) {
    return Directory(currentDir).parent.path;
  }
  return currentDir;
}

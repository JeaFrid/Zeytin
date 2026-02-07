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
  _____                _     _           _ 
 |__  /   ___   _   _  | |_   (_)  _ __   | |
    / /   / _ \ | | | | | __| | | | '_ \  | |
   / /_  |  __/ | |_| | | |_  | | | | | | |_|
  /____|  \___|  \__, |  \__| |_| |_| |_| (_)
                 |___/
           SERVER MANAGER
''' +
          _kReset,
    );

    print('1. ${_kGreen}Start Test Mode (JIT)$_kReset');
    print('2. ${_kGreen}Start Live Mode (AOT Compilation)$_kReset');
    print('3. ${_kYellow}Watch Logs (tail -f)$_kReset');
    print('4. ${_kRed}Stop Server$_kReset');
    print('5. ${_kRed}UNINSTALL SYSTEM (Danger)$_kReset');
    print('6. ${_kCyan}UPDATE SYSTEM (Git & Deps)$_kReset');
    print('7. ${_kYellow}Clear Database & Storage$_kReset');
    print('8. ${_kCyan}Nginx & SSL Setup$_kReset');
    print('9. ${_kRed}Remove Nginx Config$_kReset');
    print('0. Exit');

    stdout.write('\n${_kBold}Choice: $_kReset');
    String? choice = stdin.readLineSync()?.trim();

    switch (choice) {
      case '1':
        await _checkAndManageLiveKit();
        await _startTestMode();
        break;
      case '2':
        await _checkAndManageLiveKit();
        await _startLiveMode();
        break;
      case '3':
        await _watchLogs();
        break;
      case '4':
        await _stopServer();
        break;
      case '5':
        await _uninstallSystem();
        break;
      case '6':
        await _updateSystem();
        break;
      case '7':
        await _cleanDatabase();
        break;
      case '8':
        await _setupNginx();
        break;
      case '9':
        await _removeNginx();
        break;
      case '0':
        exit(0);
      default:
        print('Invalid selection.');
        sleep(Duration(seconds: 1));
    }

    if (choice != '1' && choice != '3' && choice != '5') {
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

Future<void> _updateSystem() async {
  print('\n$_kCyan[UPDATE] Starting system update...$_kReset');
  final root = _getProjectRoot();

  print('[@] Backing up local configs...');
  final hasConfig = await File('$root/lib/config.dart').exists();
  if (hasConfig) {
    await File('$root/lib/config.dart').copy('/tmp/zeytin_config.bak');
  }

  print('[@] Pulling latest changes from Git...');
  var gitRes = await Process.run('git', [
    'pull',
    'origin',
    'main',
  ], workingDirectory: root);

  if (gitRes.exitCode != 0) {
    print('$_kRed[ERROR] Git pull failed. Make sure it is a git repo.$_kReset');
  } else {
    print('$_kGreen[SUCCESS] Files updated.$_kReset');
  }

  if (hasConfig) {
    await File('/tmp/zeytin_config.bak').copy('$root/lib/config.dart');
    print('[@] Local config.dart restored.');
  }

  print('[@] Updating Dart dependencies...');
  var pubRes = await Process.start(
    'dart',
    ['pub', 'get'],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: root,
  );
  await pubRes.exitCode;

  print(
    '\n$_kGreen[COMPLETE] System updated. Please restart the server.$_kReset',
  );
}

Future<void> _uninstallSystem() async {
  print('\n$_kRed!!! DANGER ZONE !!!$_kReset');
  print('This will stop the server and DELETE ALL Zeytin files.');
  stdout.write('Type "DELETE" to confirm: ');
  if (stdin.readLineSync() != 'DELETE') {
    print('Aborted.');
    return;
  }

  await _stopServer();
  final root = _getProjectRoot();

  final destroyer =
      '''
#!/bin/bash
sleep 1
echo "Self-destructing..."
rm -rf "$root"
echo "Zeytin has been removed. Goodbye."
''';

  final scriptFile = File('/tmp/zeytin_uninstall.sh');
  await scriptFile.writeAsString(destroyer);
  await Process.run('chmod', ['+x', scriptFile.path]);

  print('$_kRed[BYE] Deleting system in 1 second...$_kReset');
  await Process.start('bash', [
    scriptFile.path,
  ], mode: ProcessStartMode.detached);
  exit(0);
}

Future<void> _cleanDatabase() async {
  stdout.write('Confirm deletion of ALL DATA? (y/n): ');
  if (stdin.readLineSync()?.toLowerCase() != 'y') return;
  await _stopServer();
  final root = _getProjectRoot();
  var dbDir = Directory('$root/zeytin');
  var dbErrDir = Directory('$root/zeytin_err');

  if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  if (dbErrDir.existsSync()) dbErrDir.deleteSync(recursive: true);

  print('$_kRed[CLEAN] Database and error folders removed.$_kReset');
}

Future<void> _checkAndManageLiveKit() async {
  print('$_kCyan[INIT] Checking LiveKit status...$_kReset');
  try {
    var checkDocker = await Process.run('docker', ['--version']);
    if (checkDocker.exitCode != 0) return;
  } catch (e) {
    return;
  }
  var containerCheck = await Process.run('docker', [
    'ps',
    '-a',
    '--filter',
    'name=zeytin-livekit',
    '--format',
    '{{.Names}}',
  ]);

  if (containerCheck.stdout.toString().trim() == 'zeytin-livekit') {
    var runningCheck = await Process.run('docker', [
      'ps',
      '--filter',
      'name=zeytin-livekit',
      '--format',
      '{{.Names}}',
    ]);
    if (runningCheck.stdout.toString().trim().isEmpty) {
      print('$_kYellow[LIVEKIT] Container stopped. Starting...$_kReset');
      await Process.run('docker', ['start', 'zeytin-livekit']);
      print('$_kGreen[LIVEKIT] Started.$_kReset');
    } else {
      print('$_kGreen[LIVEKIT] Already running.$_kReset');
    }
  } else {
    print('$_kYellow[LIVEKIT] Not found. Skipping.$_kReset');
  }
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

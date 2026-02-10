import 'dart:io';
import 'dart:async';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class ZeytinBackupEngine {
  final String rootPath;
  final Duration backupInterval;
  final Duration retentionPeriod;

  ZeytinBackupEngine({
    required this.rootPath,
    this.backupInterval = const Duration(hours: 1),
    this.retentionPeriod = const Duration(days: 7),
  });

  void start() {
    print("[📦 Backup]: Automation started. Interval: 1h, Retention: 7d");
    Timer.periodic(backupInterval, (timer) async {
      await performBackup();
      await cleanOldBackups();
    });
  }

  Future<void> performBackup() async {
    try {
      final backupDir = Directory(p.join(rootPath, 'backups'));
      if (!backupDir.existsSync()) backupDir.createSync();

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = "zeytin_backup_$timestamp.tar.gz";
      final backupFile = File(p.join(backupDir.path, backupFileName));

      print("[📦 Backup]: Creating backup: $backupFileName");

      final encoder = TarFileEncoder();
      encoder.create(backupFile.path);
      final foldersToBackup = ['zeytin', 'zeytin_err'];

      for (var folderName in foldersToBackup) {
        final dir = Directory(p.join(rootPath, folderName));
        if (dir.existsSync()) {
          await encoder.addDirectory(dir);
        }
      }

      encoder.close();
      print("[📦 Backup]: Success! File saved to ${backupFile.path}");
    } catch (e) {
      print("[📦 Backup Error]: Failed to create backup: $e");
    }
  }

  Future<void> cleanOldBackups() async {
    try {
      final backupDir = Directory(p.join(rootPath, 'backups'));
      if (!backupDir.existsSync()) return;

      final now = DateTime.now();
      final files = backupDir.listSync();

      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.tar.gz')) {
          final stat = entity.statSync();
          final age = now.difference(stat.modified);

          if (age > retentionPeriod) {
            print(
              "[📦 Backup]: Deleting old backup: ${p.basename(entity.path)} (Age: ${age.inDays} days)",
            );
            entity.deleteSync();
          }
        }
      }
    } catch (e) {
      print("[📦 Backup Error]: Cleanup failed: $e");
    }
  }
}

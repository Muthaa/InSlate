import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImportLogger {
  ImportLogger._();

  static File? _logFile;

  static Future<File> _getLogFile() async {
    if (_logFile != null) {
      return _logFile!;
    }

    final directory = await getApplicationDocumentsDirectory();

    final logDirectory = Directory(path.join(directory.path, 'logs'));

    if (!await logDirectory.exists()) {
      await logDirectory.create(recursive: true);
    }

    _logFile = File(path.join(logDirectory.path, 'import.log'));

    return _logFile!;
  }

  static Future<void> write(String message) async {
    try {
      final file = await _getLogFile();

      final timestamp = DateTime.now().toIso8601String();

      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      // Logging must never break the import process.
      if (kDebugMode) {
        print('IMPORT LOGGER ERROR: $e');
      }
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _getLogFile();

      if (await file.exists()) {
        await file.writeAsString('');
      }
    } catch (e) {
      if (kDebugMode) {
        print('IMPORT LOGGER CLEAR ERROR: $e');
      }
    }
  }

  static Future<String> read() async {
    try {
      final file = await _getLogFile();

      if (!await file.exists()) {
        return '';
      }

      return file.readAsString();
    } catch (e) {
      return '';
    }
  }
}

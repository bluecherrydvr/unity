import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void setupLogging() {
  Logger.root.level = Level.ALL; // You can set the log level as needed.
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
}

void handleError(dynamic error, dynamic stackTrace) {
  debugPrint('Uncaught error: $error');
  debugPrint('Stack trace: $stackTrace');

  // Write the error information to a log file.
  writeErrorToFile(error, stackTrace);
}

Future<File> getLogFile() async {
  final dir = await getApplicationSupportDirectory();
  final file = File(path.join(dir.path, 'logs.txt'));

  return file;
}

Future<void> writeErrorToFile(dynamic error, dynamic stackTrace) async {
  if (kIsWeb) return;

  final time = DateTime.now().toIso8601String();
  final errorLog = '\n[$time]Error: $error\n[$time]Stack trace: $stackTrace';

  final file = await getLogFile();

  await file.writeAsString(errorLog, mode: FileMode.append);
  Logger.root.log(Level.INFO, 'Wrote log file to ${file.path}');
}

Future<void> writeLogToFile(String text) async {
  if (kIsWeb) return;

  final time = DateTime.now().toIso8601String();
  final file = await getLogFile();

  await file.writeAsString('\n[$time] $text', mode: FileMode.append);
  Logger.root.log(Level.INFO, 'Wrote log file to ${file.path}');
}

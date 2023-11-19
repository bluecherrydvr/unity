import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

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

Future<void> writeErrorToFile(dynamic error, dynamic stackTrace) async {
  // Customize this part based on how you want to write the error to a file.
  final errorLog = 'Error: $error\nStack trace: $stackTrace';
  final file = File('error_log.txt');

  await file.writeAsString(errorLog, mode: FileMode.append);
  Logger.root.log(Level.INFO, 'Wrote log file to ${file.path}');
}

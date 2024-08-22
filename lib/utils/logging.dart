/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
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
  Logger.root.log(Level.INFO, 'Wrote log file to "${file.path}"');
}

Future<void> writeLogToFile(String text, {bool print = false}) async {
  if (!kIsWeb) {
    final time = DateTime.now().toIso8601String();
    final file = await getLogFile();

    await file.writeAsString('\n[$time] $text', mode: FileMode.append);
    if (print) Logger.root.log(Level.INFO, 'Wrote log file to "${file.path}"');
  }
  if (print) debugPrint(text);
}

Future<File> getLogFileForStream(String streamUrl) async {
  final dir = await getApplicationSupportDirectory();

  final streamUri = Uri.tryParse(streamUrl);
  String fileName;
  if (streamUri == null || streamUri.host.isEmpty) {
    fileName = streamUrl;
  } else {
    fileName = ''
        '${streamUri.host}-'
        '${streamUri.port}'
        '${streamUri.path.replaceAll('/', '-')}';
  }
  fileName = fileName.trim();

  final file = File(
    path.join(
      dir.path,
      'logs',
      '$fileName.txt',
    ),
  );

  if (!(await file.exists())) {
    await file.create(recursive: true);
  }

  return file;
}

Future<void> logStreamToFile(String streamUrl, String log) async {
  if (kIsWeb) return;

  final time = DateTime.now().toIso8601String();
  final file = await getLogFileForStream(streamUrl);

  await file.writeAsString('\n[$time] $log', mode: FileMode.append);
}

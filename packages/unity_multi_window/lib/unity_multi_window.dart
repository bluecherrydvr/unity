import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class MultiWindow {
  static Future<ResultWindow> run([List<String> arguments = const []]) async {
    final result = await Process.start(
      Platform.resolvedExecutable,
      arguments,
    );

    result.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => 'Sub window ${result.pid}: $line')
        .forEach((line) {
      if (kDebugMode) print(line);
    });

    return ResultWindow(result.pid);
  }
}

class ResultWindow {
  final int _pid;

  const ResultWindow(this._pid);

  int get windowId => _pid;

  bool close() {
    return Process.killPid(_pid);
  }
}

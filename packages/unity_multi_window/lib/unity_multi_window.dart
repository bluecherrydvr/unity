import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class MultiWindow {
  static Future<ResultWindow> run([List<String> arguments = const []]) async {
    if (kDebugMode) print('Opening ${Platform.resolvedExecutable} $arguments');
    final result = await Process.start(
      Platform.resolvedExecutable,
      [
        // This sub_window argument is required because of the way we handle
        // the windows. If a url is passed as an argument, this url will be
        // added to the current window in the "External Layout" layout. This
        // sub_window argument will be used to identify the window as a
        // sub-window and not add it to the current window, creating a new
        // window instead.
        //
        // See windows\runner\main.cpp, 55 for more information.
        'sub_window',
        ...arguments,
      ],
    );

    result.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => 'window(${result.pid}): $line')
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

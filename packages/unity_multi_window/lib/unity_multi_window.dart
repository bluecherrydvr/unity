library unity_multi_window;

import 'dart:io';

class MultiWindow {
  static Future<ResultWindow> run([List<String> arguments = const []]) async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      arguments,
    );

    return ResultWindow(result.pid);
  }
}

class ResultWindow {
  final int _pid;

  const ResultWindow(this._pid);

  bool close() {
    return Process.killPid(_pid);
  }
}

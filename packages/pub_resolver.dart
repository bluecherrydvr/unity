// A script that resolves the dependencies of all unity packages.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  print('Resolving dependencies');

  final packagePaths = <String>[
    'packages/unity_multi_window',
    'packages/unity_video_player/unity_video_player',
    'packages/unity_video_player/unity_video_player_flutter',
    'packages/unity_video_player/unity_video_player_fvp',
    'packages/unity_video_player/unity_video_player_main',
    'packages/unity_video_player/unity_video_player_platform_interface',
  ];

  print('Running pub get in all packages:');
  await Future.wait(packagePaths.map(_runPubGet));

  print('Running pub upgrade in all packages:');
  await Future.wait(packagePaths.map(_runPubUpgrade));

  print('All done');
}

Future<void> _runPubGet(String packagePath) async {
  void printLine(String line) {
    print('[$packagePath] $line');
  }

  final process = await Process.start(
    'flutter',
    ['pub', 'get'],
    workingDirectory: packagePath,
    runInShell: true,
  );
  process.stdout.transform(utf8.decoder).listen(printLine);
  process.stderr.transform(utf8.decoder).listen(printLine);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('Failed to run pub get in $packagePath');
  }
}

Future<void> _runPubUpgrade(String packagePath) async {
  void printLine(String line) {
    print('[$packagePath] $line');
  }

  final process = await Process.start(
    'flutter',
    ['pub', 'upgrade'],
    workingDirectory: packagePath,
    runInShell: true,
  );
  process.stdout.transform(utf8.decoder).listen(printLine);
  process.stderr.transform(utf8.decoder).listen(printLine);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('Failed to run pub upgrade in $packagePath');
  }
}

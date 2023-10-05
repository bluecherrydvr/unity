import 'dart:convert';
import 'dart:io';

void main() {
  final files = Directory('${Directory.current.path}/lib/l10n')
      .listSync()
      .whereType<File>();
  final mirrorFile = File('${Directory.current.path}/lib/l10n/app_en.arb');

  final mirrorContent = mirrorFile.readAsStringSync();
  final mirrorMap = Map<String, dynamic>.from(json.decode(mirrorContent));

  for (final file in files) {
    if (file.path == mirrorFile.path) continue;

    final content = file.readAsStringSync();
    final contentMap = Map<String, dynamic>.from(json.decode(content));

    final newContentMap = <String, dynamic>{
      for (final key in mirrorMap.keys) key: contentMap[key] ?? mirrorMap[key],
    };

    final newContent =
        const JsonEncoder.withIndent('  ').convert(newContentMap);
    file.writeAsString(newContent);
  }
}

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

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/widgets/device_grid/desktop/external_stream.dart';
import 'package:flutter/rendering.dart';

/// Represents a video overlay.
class VideoOverlay {
  /// The text to display.
  final String text;

  /// The text style.
  final TextStyle? textStyle;

  /// The position of the overlay.
  final Offset position;

  /// Whether the overlay is visible.
  final bool visible;

  /// Creates a new video overlay.
  const VideoOverlay({
    required this.text,
    this.textStyle = const TextStyle(),
    this.position = Offset.zero,
    this.visible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'textStyle': {
        'color': textStyle?.color?.value.toRadixString(16),
        'fontSize': textStyle?.fontSize,
      },
      'position_x': position.dx,
      'position_y': position.dy,
      'visible': visible,
    };
  }

  factory VideoOverlay.fromMap(Map map) {
    return VideoOverlay(
      text: map['text'] ?? '',
      textStyle: TextStyle(
        color: map['textStyle']['color'] == null
            ? null
            : Color(int.parse(
                '0xFF${(map['textStyle']['color'] as String).replaceAll('#', '')}',
              )),
        fontSize: (map['textStyle']['fontSize'] as num?)?.toDouble(),
      ),
      position: Offset(map['position_x'] ?? 0.0, map['position_y'] ?? 0.0),
      visible: map['visible'] ?? false,
    );
  }

  VideoOverlay copyWith({
    String? text,
    TextStyle? textStyle,
    Offset? position,
    bool? visible,
  }) {
    return VideoOverlay(
      text: text ?? this.text,
      textStyle: textStyle ?? this.textStyle,
      position: position ?? this.position,
      visible: visible ?? this.visible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VideoOverlay &&
        other.text == text &&
        other.textStyle == textStyle &&
        other.position == position &&
        other.visible == visible;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        textStyle.hashCode ^
        position.hashCode ^
        visible.hashCode;
  }
}

/// Parses the config file content and returns a map with the config values.
///
/// The config file content is a string with the following format:
///
/// ```
/// [section1]
/// key1=value1
/// key2=value2
///
/// [section2]
/// key2=value2
///
/// [section3]
/// key3=value3
/// ```
///
/// The `[overlay]` section is a special case, because it can have multiple
/// values. In this case, the returned map will have a list of maps, where each
/// map is a set of key-value pairs.
///
/// For example, the following config file content:
///
/// ```
/// [overlay]
/// key1=value1
/// key2=value2
///
/// [overlay]
/// key3=value3
/// ```
///
/// Will return the following map:
///
/// ```
/// {
///  'overlay': [
///   {'key1': 'value1', 'key2': 'value2'},
///   {'key3': 'value3'}
///  ],
/// }
/// ```
///
/// The config file content can also have comments, which are lines that start
/// with `#`. These lines are ignored. Empty lines are also ignored.
Map<String, dynamic> parseConfig(String configFileContent) {
  var config = <String, dynamic>{};
  String? currentSection;

  for (var line in configFileContent.split('\n')) {
    line = line.trim();

    if (line.startsWith('#') || line.isEmpty) continue;

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.substring(1, line.length - 1).toLowerCase();
      config[currentSection] = currentSection == 'overlay' ? [{}] : {};
    } else if (currentSection != null) {
      var parts = line.split('=');
      var key = parts[0].trim().toLowerCase();
      var value = parts[1].trim();

      final dynamic parsedValue = () {
        if (bool.tryParse(value.toLowerCase()) != null) {
          return bool.parse(value);
        }
        if (int.tryParse(value) != null) return int.tryParse(value);
        if (double.tryParse(value) != null) return double.tryParse(value);
        if (value.startsWith('"') && value.endsWith('"')) {
          return value.substring(1, value.length - 1);
        }
        return value;
      }();

      if (config[currentSection] is List) {
        ((config[currentSection] as List).last as Map)
            .addAll({key: parsedValue});
      } else {
        config[currentSection][key] = parsedValue;
      }
    }
  }

  return config;
}

void ensureFileFormat(Map<String, dynamic> configData) {
  if (configData['stream'] == null) {
    throw Exception('Missing [stream] section in config file');
  }

  if (configData['overlay'] != null) {
    if (configData['overlay'] is! List) {
      throw Exception('Invalid [overlay] section in config file');
    }

    for (var overlay in configData['overlay']) {
      if (overlay is! Map) {
        throw Exception('Invalid [overlay] section in config file');
      }

      if (overlay['text'] == null) {
        throw Exception('Missing "text" key in [overlay] section');
      }
    }
  }
}

Future<void> handleConfigurationFile(File file) async {
  var configData = parseConfig(await file.readAsString());
  ensureFileFormat(configData);

  final context = navigatorKey.currentContext;
  if (context == null) {
    throw Exception('Missing context');
  }

  final videoUrl = configData['stream']['video'] as String?;

  if (videoUrl == null) {
    throw Exception('Missing "video" key in [stream] section');
  }

  final overlays = <VideoOverlay>[];
  final overlaysData = configData['overlay'] as List?;
  if (overlaysData != null) {
    for (var overlayData in overlaysData) {
      final text = overlayData['text'] as String?;
      if (text == null) throw Exception('Missing "text" key in [overlay]');

      final opacityData = overlayData['opacity'];
      final opacity = opacityData == null
          ? 1.0
          : ((opacityData as num?)?.toDouble() ?? 100.0) / 100;

      final textStyle = TextStyle(
        color: overlayData['color'] == null
            ? null
            : Color(
                int.parse(
                  '0xFF${(overlayData['color'] as String).replaceAll('#', '')}',
                ),
              ).withOpacity(opacity),
        fontSize: (overlayData['size'] as num?)?.toDouble(),
      );
      final position = Offset(
        (overlayData['position_x'] as num?)?.toDouble() ?? 0.0,
        (overlayData['position_y'] as num?)?.toDouble() ?? 0.0,
      );
      final visible = (overlayData['show'] as bool?) ?? true;

      overlays.add(VideoOverlay(
        text: text,
        textStyle: textStyle,
        position: position,
        visible: visible,
      ));
    }
  }

  if (context.mounted) {
    await AddExternalStreamDialog.show(
      context,
      defaultUrl: videoUrl,
      overlays: overlays,
    );
  }
}

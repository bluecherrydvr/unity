import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DownloadedEvent {
  final Event event;
  final String downloadPath;

  const DownloadedEvent({
    required this.event,
    required this.downloadPath,
  });

  DownloadedEvent copyWith({
    Event? event,
    String? downloadPath,
  }) {
    return DownloadedEvent(
      event: event ?? this.event,
      downloadPath: downloadPath ?? this.downloadPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'downloadPath': downloadPath,
    };
  }

  factory DownloadedEvent.fromJson(Map<String, dynamic> map) {
    return DownloadedEvent(
      event: Event.fromJson(map['event']),
      downloadPath: map['downloadPath'] ?? '',
    );
  }

  @override
  String toString() =>
      'DownloadedEvent(event: ${event.id}, downloadPath: $downloadPath)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadedEvent &&
        other.event == event &&
        other.downloadPath == downloadPath;
  }

  @override
  int get hashCode => event.hashCode ^ downloadPath.hashCode;
}

/// The progress of an event download
typedef DownloadProgress = double;

class DownloadsManager extends ChangeNotifier {
  DownloadsManager._();

  /// `late` initialized [DownloadsManager] instance.
  static late final DownloadsManager instance;

  /// Initializes the [DownloadsManager] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<DownloadsManager> ensureInitialized() async {
    instance = DownloadsManager._();
    await instance.initialize();
    return instance;
  }

  /// All the downloaded events
  List<DownloadedEvent> downloadedEvents = [];

  /// The events that are downloading
  Map<Event, DownloadProgress> downloading = {};

  /// Called by [ensureInitialized].
  Future<void> initialize() async {
    final hive = await Hive.openBox('hive');
    if (!hive.containsKey(kHiveDownloads)) {
      await _save();
    } else {
      await _restore();
    }
  }

  /// Saves current layout/order of [Device]s to cache using `package:hive`.
  /// Pass [notifyListeners] as `false` to prevent redundant redraws.
  Future<void> _save({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    await instance.put(
      kHiveDownloads,
      jsonEncode(downloadedEvents.map((de) => de.toJson()).toList()),
    );

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  /// Restores current layout/order of [Device]s from `package:hive` cache.
  Future<void> _restore({bool notifyListeners = true}) async {
    final instance = await Hive.openBox('hive');

    downloadedEvents =
        ((jsonDecode(instance.get(kHiveDownloads)) ?? []) as List)
            .cast<Map>()
            .map<DownloadedEvent>((item) {
      return DownloadedEvent.fromJson(item.cast<String, dynamic>());
    }).toList();

    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  Future<Directory> _downloadsDirectory() async {
    final docsDir = await getApplicationSupportDirectory();
    return Directory('${docsDir.path}${path.separator}downloads').create();
  }

  /// Downloads the given [event]
  Future<void> download(Event event) async {
    assert(event.mediaURL != null, 'There must be an url to be downloaded');

    // safe for release
    if (event.mediaURL == null) return;

    downloading[event] = 0.0;
    notifyListeners();

    final dir = await _downloadsDirectory();
    final fileName = 'event_${event.id}${event.deviceID}${event.server.ip}.mp4';
    final downloadPath = '${dir.path}${path.separator}$fileName';

    await Dio().downloadUri(
      event.mediaURL!,
      downloadPath,
      options: Options(
        headers: {HttpHeaders.acceptEncodingHeader: '*'}, // disable gzip
      ),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          downloading[event] = received / total;
          notifyListeners();
        }
      },
    );

    downloading.remove(event);
    downloadedEvents.add(DownloadedEvent(
      event: event,
      downloadPath: downloadPath,
    ));

    await _save();
  }

  /// Deletes any downloaded events at the given [downloadPath]
  Future<void> delete(String downloadPath) async {
    final file = File(downloadPath);

    downloadedEvents.removeWhere((de) => de.downloadPath == downloadPath);
    await _save();

    if (await file.exists()) await file.delete();
  }
}

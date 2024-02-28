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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

class DownloadsManager extends UnityProvider {
  DownloadsManager._();

  static late final DownloadsManager instance;
  static Future<DownloadsManager> ensureInitialized() async {
    instance = DownloadsManager._();
    await instance.initialize();
    return instance;
  }

  static Future<Directory> get kDefaultDownloadsDirectory async {
    Directory? dir;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final dirs = await getExternalStorageDirectories(
            type: StorageDirectory.downloads);
        if (dirs?.isNotEmpty ?? false) dir = dirs!.first;
      }

      if (dir == null) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          dir = Directory(path.join(downloadsDir.path, 'Bluecherry Client'));
        }
      }

      if (dir == null) {
        final docsDir = await getApplicationSupportDirectory();
        dir = Directory(path.join(docsDir.path, 'downloads'));
      }
    } catch (error, stack) {
      debugPrint('Failed to get default downloads directory: $error\n$stack');
      final docsDir = await getApplicationSupportDirectory();
      dir = Directory(path.join(docsDir.path, 'downloads'));
    }

    debugPrint('The default downloads is ${dir.path}');

    return dir.create(recursive: true);
  }

  /// All the downloaded events
  List<DownloadedEvent> downloadedEvents = [];

  /// The events that are downloading
  Map<Event, DownloadProgress> downloading = {};

  Completer? downloadsCompleter;
  // bool _isProgressBarSet = false;

  @override
  Future<void> initialize() async {
    addListener(() {
      if (downloadsCompleter != null && downloadsCompleter!.isCompleted) {
        downloadsCompleter = null;
      }

      // // setProgressBar is only available on Windows and macOS
      // if (isDesktopPlatform && !Platform.isLinux) {
      //   if (downloading.isEmpty) {
      //     if (_isProgressBarSet) {
      //       windowManager.setProgressBar(-1);
      //       _isProgressBarSet = false;
      //     }
      //   } else {
      //     final progress =
      //         downloading.values.reduce((a, b) => a + b) / downloading.length;
      //     windowManager.setProgressBar(progress);
      //     _isProgressBarSet = true;
      //   }
      // }
    });

    await tryReadStorage(
        () => super.initializeStorage(downloads, kHiveDownloads));
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    try {
      await downloads.write({
        kHiveDownloads:
            jsonEncode(downloadedEvents.map((de) => de.toJson()).toList()),
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    final data = await tryReadStorage(() => downloads.read());

    downloadedEvents = data[kHiveDownloads] == null
        ? []
        : ((await compute(jsonDecode, data[kHiveDownloads] as String) ?? [])
                as List)
            .cast<Map>()
            .map<DownloadedEvent>((item) {
            return DownloadedEvent.fromJson(item.cast<String, dynamic>());
          }).toList();

    super.restore(notifyListeners: notifyListeners);
  }

  /// Whether there are no events downloaded, nor downloading events
  bool get isEmpty {
    return downloadedEvents.isEmpty && downloading.isEmpty;
  }

  /// Whether the given event is downloaded
  bool isEventDownloaded(int eventId) {
    return downloadedEvents.any((de) => de.event.id == eventId);
  }

  String getDownloadedPathForEvent(int eventId) {
    assert(isEventDownloaded(eventId));
    return downloadedEvents
        .firstWhere((de) => de.event.id == eventId)
        .downloadPath;
  }

  /// Whether the given event is being downloaded
  bool isEventDownloading(int eventId) {
    return downloading.keys.any((e) => e.id == eventId);
  }

  /// Downloads the given [event]
  Future<void> download(Event event) async {
    assert(event.mediaURL != null, 'There must be an url to be downloaded');
    if (event.mediaURL == null) return; // safe for release

    final home = HomeProvider.instance
      ..loading(UnityLoadingReason.downloadEvent);

    if (downloadsCompleter == null || downloadsCompleter!.isCompleted) {
      downloadsCompleter = Completer();
    }

    downloading[event] = 0.0;
    notifyListeners();

    final dir = SettingsProvider.instance.kDownloadsDirectory.value;
    final fileName =
        'event_${event.id}_${event.deviceID}_${event.server.name}.mp4';
    final downloadPath = path.join(dir, fileName);

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

    if (downloading.isEmpty) {
      downloadsCompleter?.complete();
    }

    home.notLoading(UnityLoadingReason.downloadEvent);
    await save();
  }

  /// Deletes any downloaded events at the given [downloadPath]
  Future<void> delete(String downloadPath) async {
    final file = File(downloadPath);

    downloadedEvents.removeWhere((de) => de.downloadPath == downloadPath);
    await save();

    if (await file.exists()) await file.delete();
  }
}

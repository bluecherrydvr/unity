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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DownloadedEvent {
  final Event event;
  final String downloadPath;

  const DownloadedEvent({required this.event, required this.downloadPath});

  DownloadedEvent copyWith({Event? event, String? downloadPath}) {
    return DownloadedEvent(
      event: event ?? this.event,
      downloadPath: downloadPath ?? this.downloadPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {'event': event.toJson(), 'downloadPath': downloadPath};
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
    debugPrint('DownloadsManager initialized');
    return instance;
  }

  static Future<Directory?> get kDefaultDownloadsDirectory async {
    if (kIsWeb) return null;
    Directory? dir;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs?.isNotEmpty ?? false) dir = dirs!.first;
      }

      // This method is only available on macOS
      if (Platform.isMacOS) {
        if (dir == null) {
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            dir = Directory(path.join(downloadsDir.path, 'Bluecherry Client'));
          }
        }
      }

      dir ??= Directory(
        path.join((await getApplicationSupportDirectory()).path, 'downloads'),
      );
    } on StateError catch (e) {
      debugPrint('Failed to get default downloads directory: $e');
    } catch (error, stack) {
      debugPrint('Failed to get default downloads directory:$error\n$stack');
    } finally {
      if (dir == null) {
        final docsDir = await getApplicationSupportDirectory();
        dir = Directory(path.join(docsDir.path, 'downloads'));
      }
    }

    debugPrint('The default downloads is ${dir.path}');

    return dir.create(recursive: true);
  }

  /// All the downloaded events
  Set<DownloadedEvent> downloadedEvents = {};

  /// The events that are downloading
  Map<Event, (DownloadProgress progress, String filePath)> downloading = {};

  Completer? downloadsCompleter;
  // bool _isProgressBarSet = false;

  @override
  Future<void> initialize() async {
    addListener(() {
      if (downloadsCompleter != null && downloadsCompleter!.isCompleted) {
        downloadsCompleter = null;
      }

      downloading.removeWhere((key, value) {
        final progress = value.$1;
        return progress == 1.0;
      });

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
    super.initializeStorage(kStorageDownloads);

    for (final de in downloadedEvents) {
      doesEventFileExist(de.event.id).then((exist) async {
        if (!exist) {
          debugPrint(
            'Event file does not exist: ${de.event.id}. Redownloading',
          );
          final downloadPath = await _downloadEventFile(
            de.event,
            path.dirname(de.downloadPath),
          );
          downloadedEvents.add(de.copyWith(downloadPath: downloadPath));
        }
      });
    }
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({
      kStorageDownloads: jsonEncode(
        downloadedEvents.map((de) => de.toJson()).toList(),
      ),
    });

    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    // TODO(bdlukaa): Remove this migration in the future.
    //                Previously, we were unecessarily encoding the downloads
    //                data as a string. This is no longer necessary.
    //
    //                This migration is to ensure the downloads made on previous
    //                versions are not lost.
    List downloadsData;
    {
      final data = await secureStorage.read(key: kStorageDownloads);
      if (data == null) {
        downloadsData = [];
      } else {
        downloadsData = jsonDecode(data) as List;
      }
    }

    downloadedEvents =
        downloadsData.map<DownloadedEvent>((item) {
          return DownloadedEvent.fromJson(
            (item as Map).cast<String, dynamic>(),
          );
        }).toSet();

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

  Future<bool> doesEventFileExist(int eventId) async {
    final downloadPath = getDownloadedPathForEvent(eventId);
    return File(downloadPath).exists();
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

    final dir = await () async {
      final settings = SettingsProvider.instance;

      if (settings.kChooseLocationEveryTime.value) {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Choose download location',
          initialDirectory: settings.kDownloadsDirectory.value,
          lockParentWindow: true,
        );

        if (selectedDirectory != null) {
          debugPrint('Selected directory: $selectedDirectory');
          settings.kDownloadsDirectory.value = selectedDirectory;
        }
      }
      return settings.kDownloadsDirectory.value;
    }();
    final downloadPath = await _downloadEventFile(event, dir);

    downloading.remove(event);
    downloadedEvents
      ..removeWhere((downloadedEvent) => downloadedEvent.event.id == event.id)
      ..add(DownloadedEvent(event: event, downloadPath: downloadPath));

    if (downloading.isEmpty) {
      downloadsCompleter?.complete();
    }

    await save();
  }

  /// Downloads the given [event] and returns the path of the downloaded file
  Future<String> _downloadEventFile(Event event, String dir) async {
    if (event.mediaURL == null) {
      throw ArgumentError('The event does not have a mediaURL');
    }

    if (downloading.entries.any((de) => de.key.id == event.id)) {
      return downloading.entries
          .firstWhere((de) => de.key.id == event.id)
          .value
          .$2;
    }
    writeLogToFile(
      'downloads(${event.id}): $dir at ${event.mediaPath}',
      print: true,
    );
    final home =
        HomeProvider.instance..loading(UnityLoadingReason.downloadEvent);

    if (downloadsCompleter == null || downloadsCompleter!.isCompleted) {
      downloadsCompleter = Completer();
    }

    downloading[event] = (0.0, '');
    notifyListeners();

    final fileName =
        'event_${event.id}_${event.deviceID}_${event.server.name}.mp4';
    final downloadPath = path.join(dir, fileName);
    final downloadFile = File(downloadPath);
    if (!(await downloadFile.exists())) {
      await downloadFile.create(recursive: true);
      writeLogToFile(
        'downloads(${event.id}): Created file: $downloadPath',
        print: true,
      );
    }

    try {
      await Dio().download(
        event.mediaPath,
        downloadPath,
        options: Options(
          headers: {
            HttpHeaders.acceptEncodingHeader: '*', // disable gzip
            HttpHeaders.cookieHeader: event.server.cookie!,
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloading[event] = (received / total, fileName);
            writeLogToFile('downloads(${event.id}): ${received / total}');
            notifyListeners();
          }
        },
      );
    } on DioException catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to download event file from ${event.mediaPath}'
        ' (${error.response?.statusCode}): '
        '${error.message}. ',
      );
    } catch (error, stack) {
      handleError(error, stack, 'Failed to download event file');
    } finally {
      home.notLoading(UnityLoadingReason.downloadEvent);
    }

    return downloadPath;
  }

  /// Deletes any downloaded events at the given [downloadPath]
  Future<void> delete(String downloadPath) async {
    final file = File(downloadPath);

    downloadedEvents.removeWhere((de) => de.downloadPath == downloadPath);
    await save();

    if (await file.exists()) await file.delete();
  }

  void cancelEventDownload(Event target) {
    final event = downloading.keys.firstWhereOrNull((downloadingEvent) {
      return downloadingEvent.id == target.id;
    });

    try {
      final file = File(downloading[event]!.$2);
      if (file.existsSync()) file.deleteSync();
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to delete file while canceling download',
      );
    }
    downloading.remove(event);
    notifyListeners();
  }

  /// Cancels the ongoing downloads and deletes the downloaded files.
  Future<void> cancelDownloading([String? downloadPath]) async {
    for (final event in downloading.keys) {
      cancelEventDownload(event);
    }

    downloadsCompleter?.complete();
  }
}

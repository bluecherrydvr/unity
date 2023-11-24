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

import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:version/version.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xml/xml.dart';

enum FailType {
  executableNotFound,
}

class UpdateVersion {
  final String version;
  final String description;
  final String publishedAt;

  const UpdateVersion({
    required this.version,
    required this.description,
    required this.publishedAt,
  });

  @override
  String toString() =>
      'UpdateVersion(version: $version, description: $description, publishedAt: $publishedAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UpdateVersion &&
        other.version == version &&
        other.description == description &&
        other.publishedAt == publishedAt;
  }

  @override
  int get hashCode =>
      version.hashCode ^ description.hashCode ^ publishedAt.hashCode;

  static const titleField = 'title';
  static const descriptionField = 'description';
  static const publishedAtField = 'pubDate';

  static const rpm = 'rpm';
  static const deb = 'deb';
  static const tarball = 'tar.gz';
  static const appImage = 'appimage';
  static const linuxDownloadFileName = 'bluecherry-linux-x86_64';
  static const windowsDownloadFileName = 'bluecherry-windows-setup';
}

class UpdateManager extends ChangeNotifier {
  UpdateManager._();

  /// `late` initialized [UpdateManager] instance.
  static late final UpdateManager instance;
  late final PackageInfo packageInfo;
  late String tempDir;

  /// The URL to the appcast file.
  static const appCastUrl =
      'https://raw.githubusercontent.com/bluecherrydvr/unity/main/bluecherry_appcast.xml';

  /// Initializes the [UpdateManager] instance & fetches state from `async`
  /// `package:hive` method-calls. Called before [runApp].
  static Future<UpdateManager> ensureInitialized() async {
    instance = UpdateManager._();
    await instance.initialize();
    return instance;
  }

  /// If true, there is a new update available.
  ///
  /// If false, the user is up to date with the latest version.
  bool get hasUpdateAvailable {
    if (this.latestVersion == null) return false;

    final currentVersion = Version.parse(packageInfo.version);
    final latestVersion = Version.parse(this.latestVersion!.version);

    // assert(
    //   latestVersion >= currentVersion,
    //   'The latest version can not be older than the current version',
    // );

    return currentVersion != latestVersion;
  }

  List<UpdateVersion> versions = [];
  UpdateVersion? get latestVersion {
    return versions.isEmpty ? null : versions.last;
  }

  Future<void> initialize() async {
    final data = await downloads.read() as Map;
    if (!data.containsKey(kHiveAutomaticUpdates)) {
      await _save();
    } else {
      await _restore();
    }

    tempDir = (await getTemporaryDirectory()).path;

    await Future.wait([
      checkForUpdates(),
      PackageInfo.fromPlatform().then((result) {
        packageInfo = result;
      })
    ]);

    if (hasUpdateAvailable && automaticDownloads) {
      download(latestVersion!.version);
    }
  }

  Future<void> _save({bool notify = true}) async {
    try {
      await downloads.write({
        kHiveAutomaticUpdates: automaticDownloads,
        kHiveLastCheck: lastCheck?.toIso8601String(),
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    if (notify) notifyListeners();
  }

  Future<void> _restore({bool notifyListeners = true}) async {
    final data = await downloads.read() as Map;

    _automaticDownloads = data[kHiveAutomaticUpdates];
    _lastCheck = data[kHiveLastCheck] == null
        ? null
        : DateTime.tryParse(data[kHiveLastCheck]!);

    if (notifyListeners) this.notifyListeners();
  }

  /// If there is anything loading at the time
  bool loading = false;

  /// Whether the user wants to automatically download updates
  bool _automaticDownloads = false;
  bool get automaticDownloads => _automaticDownloads;
  set automaticDownloads(bool value) {
    _automaticDownloads = value;
    _save();
  }

  /// The last time the user checked for updates
  DateTime? _lastCheck;
  DateTime? get lastCheck => _lastCheck;
  set lastCheck(DateTime? date) {
    _lastCheck = date;
    _save();
  }

  /// Checks how the Linux executable was installed.
  ///
  /// Returns `null` if the platform is not Linux or if the environment is not
  /// recognized.
  ///
  /// The possible values are:
  ///   * `rpm`
  ///   * `deb`
  ///   * `AppImage`
  ///   * `tar.gz` (tarball)
  ///
  /// This means the value represent the file extension of the executable.
  ///
  /// Each Flutter executable is built with a different `linux_environment`
  /// value, so it is possible to distinguish between them. This is useful to
  /// know how to upgrade the app.
  ///
  /// See also:
  ///
  ///  * [install], which uses this method to install the correct executable.
  String? get linuxEnvironment {
    assert(
      Platform.isLinux,
      'This should never be reached on non-Linux platforms.',
    );

    if (!const bool.hasEnvironment('linux_environment')) return null;

    return const String.fromEnvironment('linux_environment');
  }

  /// Check if updates are supported on the current platform.
  ///
  /// On Windows, updates are always supported.
  ///
  /// On Linux, updates are supported if the `linux_environment` is set and it
  /// is not an `AppImage`.
  bool get isUpdatingSupported {
    if (Platform.isWindows) return true;
    if (Platform.isLinux) {
      return linuxEnvironment != null &&
          linuxEnvironment != UpdateVersion.appImage;
    }

    return false;
  }

  /// Whether any executable is being downloaded at the time
  bool downloading = false;

  /// The progress of the download, from 0.0 to 1.0
  double downloadProgress = 0.0;

  /// Gets the executable for the given [version].
  ///
  /// If the executable is not found, returns `null`. To download the executable,
  /// call [download(version)].
  File? executableFor(String version) {
    assert(
      isDesktopPlatform,
      'This should never be reached on non-desktop platforms',
    );

    if (Platform.isWindows) {
      final file = File(path.join(
        tempDir,
        '${UpdateVersion.windowsDownloadFileName}-$version.exe',
      ));
      if (file.existsSync()) return file;
    } else if (Platform.isLinux) {
      final file = File(path.join(
        tempDir,
        '${UpdateVersion.linuxDownloadFileName}-$version.$linuxEnvironment',
      ));
      if (file.existsSync()) return file;
    } else {
      throw UnsupportedError(
        'Unsupported platform. Only Windows and Linux are supported',
      );
    }
    return null;
  }

  /// Downloads the latest version executable.
  Future<void> download(String version) async {
    assert(
      isDesktopPlatform,
      'This should never be reached on non-desktop platforms',
    );

    downloading = true;
    notifyListeners();

    String fileName;
    String extension;

    if (Platform.isWindows) {
      fileName = UpdateVersion.windowsDownloadFileName;
      extension = '.exe';
    } else if (Platform.isLinux) {
      assert(linuxEnvironment != null);
      fileName = UpdateVersion.linuxDownloadFileName;
      extension = '.$linuxEnvironment';
    } else {
      downloading = false;
      notifyListeners();
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }

    final file = File(path.join(tempDir, '$fileName-$version$extension'));
    if (await file.exists()) await file.delete();

    final executablePath = Uri.https(
      'github.com',
      '/bluecherrydvr/unity/releases/download/bleeding_edge/$fileName$extension',
    );

    await Dio().downloadUri(
      executablePath,
      file.path,
      onReceiveProgress: (received, total) {
        downloadProgress = received / total * 100;
        notifyListeners();
      },
    );

    downloading = false;
    downloadProgress = 0.0;
    notifyListeners();
  }

  /// Installs the executable for the latest version.
  ///
  /// It can not downgrade
  Future<void> install({
    required ValueChanged<FailType> onFail,
  }) async {
    assert(
      isUpdatingSupported,
      'This should never be reached on unsupported platforms',
    );

    assert(hasUpdateAvailable, 'Already up to date');

    final executable = executableFor(latestVersion!.version);
    assert(executable != null, 'Executable not found');

    if (executable == null) {
      onFail(FailType.executableNotFound);
      return;
    }

    windowManager.hide();
    await UnityVideoPlayerInterface.dispose();

    if (Platform.isWindows) {
      // https://jrsoftware.org/ishelp/index.php?topic=technotes
      Process.run(executable.path, [
        '/SP-',
        '/silent',
        '/noicons',
      ]);
    } else if (Platform.isLinux) {
      switch (linuxEnvironment) {
        case UpdateVersion.rpm:
          Process.run('tar', ['-U', executable.path]);
          break;
        case UpdateVersion.deb:
          Process.run('sudo', ['dpkg', '-i', executable.path]);
          break;
        case UpdateVersion.tarball: // tarball
          Process.run('tar', ['-i', executable.path]);
          break;
        case UpdateVersion.appImage:
          throw UnsupportedError('AppImages do not support updating from app');
        default:
          throw UnsupportedError(
            'Can not install an executable on an unknown environment',
          );
      }
    }

    windowManager.close();
  }

  /// Check for new updates.
  Future<void> checkForUpdates() async {
    
    loading = true;
    notifyListeners();

try {
    final response = await http.get(Uri.parse(appCastUrl));

    if (response.statusCode != 200) {
      debugPrint(
        'Failed to check for updates (${response.statusCode}): ${response.body}',
      );
      loading = false;
      notifyListeners();
      return;
    }

    var versions = <UpdateVersion>[];
    final doc = XmlDocument.parse(response.body);
    for (final item in doc.findAllElements('item')) {
      late String version;
      late String description;
      late String publishedAt;
      for (var child in item.children.whereType<XmlElement>()) {
        switch (child.name.toString()) {
          case UpdateVersion.titleField:
            version = child.innerText.replaceAll('Version', '').trim();
            break;
          case UpdateVersion.descriptionField:
            description = child.innerText.trim();
            break;
          case UpdateVersion.publishedAtField:
            publishedAt = child.innerText.trim();
            break;
          default:
        }
      }
      versions.add(UpdateVersion(
        version: version,
        description: description,
        publishedAt: publishedAt,
      ));
    }
    // versions.sort(
    //   (a, b) => a.publishedAt.compareTo(b.publishedAt),
    // );
    versions = versions.reversed.toList();

    if (versions != this.versions) this.versions = versions;

    } catch (e) {
      debugPrint(e.toString());
    }

    loading = false;
    lastCheck = DateTime.now(); // this updates the screen already
  }
}

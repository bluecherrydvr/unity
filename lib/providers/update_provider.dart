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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/providers/app_provider_interface.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:version/version.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xml/xml.dart';

enum FailType { executableNotFound }

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

  static const linuxDownloadFileName = 'bluecherry-linux-x86_64';
  static const windowsDownloadFileName = 'bluecherry-windows-setup';
}

enum LinuxPlatform {
  rpm('rpm'),
  deb('deb'),
  appImage('AppImage'),
  tarball('tar.gz'),
  embedded(null);

  final String? value;

  const LinuxPlatform(this.value);

  String get name {
    return switch (this) {
      LinuxPlatform.deb => 'Debian',
      LinuxPlatform.rpm => 'Rpm',
      LinuxPlatform.appImage => 'AppImage',
      LinuxPlatform.tarball => 'Tarball',
      LinuxPlatform.embedded || _ => 'Embedded',
    };
  }
}

class UpdateManager extends UnityProvider {
  UpdateManager._();

  /// `late` initialized [UpdateManager] instance.
  static late final UpdateManager instance;
  late final PackageInfo? packageInfo;
  late String tempDir;

  /// The URL to the appcast file.
  static const appCastUrl =
      'https://raw.githubusercontent.com/bluecherrydvr/unity/main/bluecherry_appcast.xml';

  static Future<UpdateManager> ensureInitialized() async {
    instance = UpdateManager._();
    await instance.initialize();
    debugPrint('UpdateManager initialized');
    return instance;
  }

  /// If true, there is a new update available.
  ///
  /// If false, the user is up to date with the latest version.
  bool get hasUpdateAvailable {
    if (this.latestVersion == null || packageInfo == null) return false;

    final currentVersion = Version.parse(packageInfo!.version);
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

  Future<void> _setPackageInfo() async {
    if (isEmbedded) {
      packageInfo = null;
    } else {
      await PackageInfo.fromPlatform().then((result) {
        packageInfo = result;
      });
    }
  }

  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      return _setPackageInfo();
    }
    super.initializeStorage(kStorageAutomaticUpdates);

    tempDir = (await getTemporaryDirectory()).path;

    await Future.wait([checkForUpdates(), _setPackageInfo()]);

    if (hasUpdateAvailable && automaticDownloads) {
      download(latestVersion!.version);
    }
  }

  @override
  Future<void> save({bool notifyListeners = true}) async {
    await write({
      kStorageAutomaticUpdates: automaticDownloads,
      kStorageLastCheck: lastCheck?.toIso8601String(),
    });
    super.save(notifyListeners: notifyListeners);
  }

  @override
  Future<void> restore({bool notifyListeners = true}) async {
    _automaticDownloads =
        await secureStorage.readBool(key: kStorageAutomaticUpdates) ?? false;
    final lastCheckData = await secureStorage.read(key: kStorageLastCheck);
    _lastCheck =
        lastCheckData == null ? null : DateTime.tryParse(lastCheckData);

    super.restore(notifyListeners: notifyListeners);
  }

  /// If there is anything loading at the time
  bool loading = false;

  /// Whether the user wants to automatically download updates
  bool _automaticDownloads = false;
  bool get automaticDownloads => _automaticDownloads;
  set automaticDownloads(bool value) {
    _automaticDownloads = value;
    save();
  }

  /// The last time the user checked for updates
  DateTime? _lastCheck;
  DateTime? get lastCheck => _lastCheck;
  set lastCheck(DateTime? date) {
    _lastCheck = date;
    save();
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
  /// Null defaults to Raspberry Pi
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
  static LinuxPlatform get linuxEnvironment {
    assert(
      Platform.isLinux,
      'This should never be reached on non-Linux platforms.',
    );

    if (!const bool.hasEnvironment('linux_environment')) {
      return LinuxPlatform.embedded;
    }

    return LinuxPlatform.values.firstWhere(
      (linux) =>
          linux.value == const String.fromEnvironment('linux_environment'),
      orElse: () => LinuxPlatform.embedded,
    );
  }

  /// Whether the current platform is embedded
  static bool get isEmbedded {
    return isDesktopPlatform &&
        Platform.isLinux &&
        UpdateManager.linuxEnvironment == LinuxPlatform.embedded;
  }

  /// Check if updates are supported on the current platform.
  ///
  /// On Windows, updates are always supported.
  ///
  /// On Linux, updates are supported if the `linux_environment` is set and it
  /// is not an `AppImage`.
  static bool get isUpdatingSupported {
    if (Platform.isWindows) return true;
    if (Platform.isLinux) {
      return linuxEnvironment != LinuxPlatform.appImage &&
          linuxEnvironment != LinuxPlatform.embedded;
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
      final file = File(
        path.join(
          tempDir,
          '${UpdateVersion.windowsDownloadFileName}-$version.exe',
        ),
      );
      if (file.existsSync()) return file;
    } else if (Platform.isLinux) {
      final file = File(
        path.join(
          tempDir,
          '${UpdateVersion.linuxDownloadFileName}-$version.$linuxEnvironment',
        ),
      );
      if (file.existsSync()) return file;
    } else {
      throw UnsupportedError(
        'Unsupported platform. Only Windows and Linux are supported.',
      );
    }
    return null;
  }

  String get downloadMacOSRedirect =>
      'https://github.com/bluecherrydvr/unity?tab=readme-ov-file#download';

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
  Future<void> install({required ValueChanged<FailType> onFail}) async {
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
      Process.run(executable.path, ['/SP-', '/silent', '/noicons']);
    } else if (Platform.isLinux) {
      switch (linuxEnvironment) {
        case LinuxPlatform.rpm:
          Process.run('tar', ['-U', executable.path]);
          break;
        case LinuxPlatform.deb:
          Process.run('sudo', ['dpkg', '-i', executable.path]);
          break;
        case LinuxPlatform.tarball: // tarball
          Process.run('tar', ['-i', executable.path]);
          break;
        case LinuxPlatform.embedded:
        case LinuxPlatform.appImage:
          throw UnsupportedError('AppImages do not support updating from app');
      }
    }

    windowManager.close();
  }

  /// Check for new updates.
  Future<void> checkForUpdates() async {
    loading = true;
    notifyListeners();

    try {
      final response = await API.client.get(Uri.parse(appCastUrl));

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
        versions.add(
          UpdateVersion(
            version: version,
            description: description,
            publishedAt: publishedAt,
          ),
        );
      }
      // versions.sort(
      //   (a, b) => a.publishedAt.compareTo(b.publishedAt),
      // );
      versions = versions.reversed.toList();

      if (versions != this.versions) this.versions = versions;

      loading = false;
      // this updates the screen already because "lastCheck" is a setter. No need to trigger the update again
      lastCheck = DateTime.now();
    } catch (error, stackTrace) {
      handleError(error, stackTrace, 'Failed to check for updates');
    }
  }
}

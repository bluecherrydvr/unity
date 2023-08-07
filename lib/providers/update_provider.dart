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
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:version/version.dart';
import 'package:xml/xml.dart';

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
}

class UpdateManager extends ChangeNotifier {
  UpdateManager._();

  /// `late` initialized [UpdateManager] instance.
  static late final UpdateManager instance;
  late final PackageInfo packageInfo;
  late String tempDir;

  /// The URL to the appcast file.
  static const appCastUrl =
      'https://raw.githubusercontent.com/bdlukaa/unity/upgrade/bluecherry_appcast.xml';

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
    final currentVersion = packageInfo.version;
    return Version.parse(currentVersion) !=
        Version.parse(latestVersion.version);
  }

  List<UpdateVersion> versions = [];
  UpdateVersion get latestVersion => versions.last;

  Future<void> initialize() async {
    final data = await downloads.read() as Map;
    if (!data.containsKey(kHiveAutomaticUpdates)) {
      await _save();
    } else {
      await _restore();
    }

    await Future.wait([
      checkForUpdates(),
      PackageInfo.fromPlatform().then((result) {
        packageInfo = result;
      })
    ]);

    if (hasUpdateAvailable && automaticDownloads) {
      download(latestVersion.version);
    }
  }

  Future<void> _save({bool notify = true}) async {
    await downloads.write({
      kHiveAutomaticUpdates: automaticDownloads,
      kHiveLastCheck: lastCheck?.toIso8601String(),
    });

    if (notify) notifyListeners();
  }

  Future<void> _restore({bool notifyListeners = true}) async {
    final data = await downloads.read() as Map;

    _automaticDownloads = data[kHiveAutomaticUpdates];
    _lastCheck = DateTime.tryParse(data[kHiveLastCheck] ?? '');

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

  DateTime? _lastCheck;
  DateTime? get lastCheck => _lastCheck;
  set lastCheck(DateTime? date) {
    _lastCheck = date;
    _save();
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
    assert(isDesktop, 'This should never be reached on non-desktop platforms');

    if (Platform.isWindows) {
      const fileName =
          true ? 'bluecherry-dvr-setup' : 'bluecherry-windows-setup';
      final file = File(path.join(tempDir, '$fileName-$version.exe'));
      if (file.existsSync()) {
        return file;
      }
    } else if (Platform.isLinux) {
    } else {
      throw UnsupportedError('Unsupported platform');
    }
    return null;
  }

  /// Downloads the latest version executable.
  Future<void> download(String version) async {
    assert(isDesktop, 'This should never be reached on non-desktop platforms');

    downloading = true;
    notifyListeners();

    if (Platform.isWindows) {
      // TODO(bdlukaa): Use the bluecherry-windows-setup file before merging
      const fileName =
          true ? 'bluecherry-dvr-setup' : 'bluecherry-windows-setup';
      final windowsPath = Uri.https(
        'github.com',
        '/bluecherrydvr/unity/releases/download/bleeding_edge/$fileName.exe',
      );

      final file = File(path.join(tempDir, '$fileName-$version.exe'));
      if (await file.exists()) await file.delete();

      await Dio().downloadUri(
        windowsPath,
        file.path,
        onReceiveProgress: (received, total) {
          downloadProgress = received / total * 100;
          notifyListeners();
        },
      );
    } else if (Platform.isLinux) {
    } else {
      downloading = false;
      throw UnsupportedError('Unsupported platform');
    }

    downloading = false;
    downloadProgress = 0.0;
    notifyListeners();
  }

  /// Installs the executable for the latest version.
  ///
  /// It can not downgrade
  Future<void> install() async {
    assert(isDesktop, 'This should never be reached on non-desktop platforms');

    final executable = executableFor(latestVersion.version);

    assert(executable != null);

    if (Platform.isWindows) {
      // https://jrsoftware.org/ishelp/index.php?topic=technotes
      Process.run(executable!.path, [
        '/SP-',
        '/silent',
        '/noicons',
      ]);
    }
  }

  /// Check for new updates.
  Future<void> checkForUpdates() async {
    loading = true;
    notifyListeners();

    tempDir = (await getTemporaryDirectory()).path;

    final versions = <UpdateVersion>[];
    // Parse the versions from the server
    final doc = XmlDocument.parse((await http.get(Uri.parse(appCastUrl))).body);
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
    versions.sort(
      (a, b) => Version.parse(a.version).compareTo(Version.parse(b.version)),
    );

    if (versions != this.versions) this.versions = versions;

    loading = false;
    lastCheck = DateTime.now(); // this updates the screen already
  }
}

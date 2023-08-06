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

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
    ;
    versions.sort(
      (a, b) => Version.parse(a.version).compareTo(Version.parse(b.version)),
    );

    packageInfo = await PackageInfo.fromPlatform();
  }
}

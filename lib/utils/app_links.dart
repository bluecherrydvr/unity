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

import 'package:app_links/app_links.dart';
import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/utils/config.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/device_grid/desktop/external_stream.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:win32_registry/win32_registry.dart';

final instance = AppLinks();

/// Registers a scheme the app will listen.
Future<void> register(String scheme) async {
  if (Platform.isWindows) {
    var appPath = Platform.resolvedExecutable;

    var protocolRegKey = 'Software\\Classes\\$scheme';
    var protocolRegValue = const RegistryValue(
      'URL Protocol',
      RegistryValueType.string,
      '',
    );
    var protocolCmdRegKey = 'shell\\open\\command';
    var protocolCmdRegValue = RegistryValue(
      '',
      RegistryValueType.string,
      '"$appPath" "%1"',
    );

    Registry.currentUser.createKey(protocolRegKey)
      ..createValue(protocolRegValue)
      ..createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
  }
}

bool? _openedFromFile;

/// Whether the app was opened from a `.bluecherry` file.
bool get openedFromFile => _openedFromFile ?? false;

/// Listens to any links received while the app is running.
void listen() {
  instance.allUriLinkStream.listen((uri) async {
    debugPrint('Received URI: $uri');
    final handleType = await _handleUri(uri);
    _openedFromFile ??= handleType == HandleType.bluecherry;
  });
}

enum HandleType { bluecherry, streamUrl, none }

Future<HandleType> _handleUri(Uri uri) async {
  if (path.extension(uri.path) == '.bluecherry') {
    final file = File(uri.path);
    if (await file.exists()) {
      handleConfigurationFile(file);
      return HandleType.bluecherry;
    }
  }

  final url = uri.toString();
  if (isDesktopPlatform) {
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      AddExternalStreamDialog.addStream(context, url);
    }
  } else {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return HandleType.none;
    navigator.pushNamed('/rtsp', arguments: url);
  }

  return HandleType.streamUrl;
}

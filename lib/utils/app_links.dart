import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/widgets.dart';
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

/// Initialize the app links.
///
/// When the app is opened from a link, it will open the [AddExternalStreamDialog]
/// as soon as the application is ready.
Future<void> init() async {
  try {
    var initialUri = await instance.getInitialAppLinkString();
    debugPrint('Initial URI: $initialUri');
    if (initialUri != null) {
      final url = initialUri;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          AddExternalStreamDialog.addStream(context, url);
        }
      });
    }
  } catch (e) {
    debugPrint('Error initializing app links: $e');
  }
}

/// Listens to any links received while the app is running.
void listen() {
  instance.allUriLinkStream.listen((uri) {
    debugPrint('Received URI: $uri');
    final url = uri.toString();
    if (isDesktopPlatform) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        AddExternalStreamDialog.addStream(context, url);
      }
    } else {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamed('/rtsp', arguments: url);
    }
  });
}

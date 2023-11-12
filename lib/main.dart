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

import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/api/api_helpers.dart';
import 'package:bluecherry_client/firebase_messaging_background_handler.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/downloads_provider.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/utils/app_links.dart' as app_links;
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/events/events_screen.dart';
import 'package:bluecherry_client/widgets/home.dart';
import 'package:bluecherry_client/widgets/multi_window/single_camera_window.dart';
import 'package:bluecherry_client/widgets/multi_window/single_layout_window.dart';
import 'package:bluecherry_client/widgets/multi_window/window.dart';
import 'package:bluecherry_client/widgets/player/live_player.dart';
import 'package:bluecherry_client/widgets/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // https://github.com/flutter/flutter/issues/41980#issuecomment-1231760866
  // On windows, the window is hidden until flutter draws its first frame.
  // To create a splash screen effect while the dependencies are loading, we
  // can run the [SplashScreen] widget as the app.
  if (isDesktopPlatform) {
    await configureWindow();
    runApp(const SplashScreen());
  }

  DevHttpOverrides.configureCertificates();
  await UnityVideoPlayerInterface.instance.initialize();
  await configureStorage();

  if (isDesktopPlatform && args.isNotEmpty) {
    debugPrint('FOUND ANOTHER WINDOW: $args');

    if (args.length == 1 &&
        (path.extension(args.first) == '.bluecherry' ||
            Uri.tryParse(args.first)?.scheme == 'bluecherry')) {
      // this is handled by app links
      // final configFile = File(args.first);
      // if (await configFile.exists()) {
      //   handleConfigurationFile(configFile);
      // }
    } else {
      try {
        // this is just a mock. HomeProvider depends on this, so we mock the instance
        ServersProvider.instance = ServersProvider();
        await SettingsProvider.ensureInitialized();
        await DesktopViewProvider.ensureInitialized();

        final windowType = MultiWindowType.values[int.tryParse(args[0]) ?? 0];
        final themeMode = ThemeMode.values[int.tryParse(args[2]) ?? 0];

        switch (windowType) {
          case MultiWindowType.device:
            final device = Device.fromJson(json.decode(args[1]));
            configureWindowTitle(device.fullName);

            runApp(AlternativeWindow(
              mode: themeMode,
              child: CameraView(device: device),
            ));
            break;
          case MultiWindowType.layout:
            final layout = Layout.fromJson(args[1]);
            configureWindowTitle(layout.name);

            runApp(AlternativeWindow(
              mode: themeMode,
              child: AlternativeLayoutView(layout: layout),
            ));

            break;
        }
      } catch (error, stack) {
        debugPrint('error: $error');
        debugPrintStack(stackTrace: stack);
      }

      return;
    }
  }

  // Request notifications permission for iOS, Android 13+ and Windows.
  //
  // permission_handler only supports these platforms
  if (isMobilePlatform || Platform.isWindows) {
    () async {
      if (await Permission.notification.isDenied) {
        final state = await Permission.notification.request();
        debugPrint('Notification permission state $state');
      }
    }();
  }

  // We use [Future.wait] to decrease startup time.
  //
  // With it, all these functions will be running at the same time, reducing the
  // wait time at the splash screen
  // settings provider needs to be initalized alone
  await SettingsProvider.ensureInitialized();
  await Future.wait([
    MobileViewProvider.ensureInitialized(),
    DesktopViewProvider.ensureInitialized(),
    ServersProvider.ensureInitialized(),
    DownloadsManager.ensureInitialized(),
    EventsProvider.ensureInitialized(),
    UpdateManager.ensureInitialized(),
  ]);

  /// Firebase messaging isn't available on windows nor linux
  if (kIsWeb || isMobilePlatform || Platform.isMacOS) {
    FirebaseConfiguration.ensureInitialized();
  }

  HomeProvider.setDefaultStatusBarStyle();

  app_links.register('rtsp');
  app_links.register('bluecherry');
  app_links.listen();
  runApp(const UnityApp());
}

class UnityApp extends StatefulWidget {
  const UnityApp({super.key});

  @override
  State<UnityApp> createState() => _UnityAppState();
}

class _UnityAppState extends State<UnityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Whether the app is in background or not
  bool isInBackground = false;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('in foreground');

        // When the app is resumed from background to foreground, reload all
        // unity players
        if (isInBackground) {
          UnityPlayers.reloadAll(onlyIfTimedOut: true);
        }

        isInBackground = false;
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        debugPrint('in background');
        isInBackground = true;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: SettingsProvider.instance,
        ),
        ChangeNotifierProvider<DesktopViewProvider>.value(
          value: DesktopViewProvider.instance,
        ),
        ChangeNotifierProvider<DownloadsManager>.value(
          value: DownloadsManager.instance,
        ),
        ChangeNotifierProvider<MobileViewProvider>.value(
          value: MobileViewProvider.instance,
        ),
        ChangeNotifierProvider<ServersProvider>.value(
          value: ServersProvider.instance,
        ),
        ChangeNotifierProvider<EventsProvider>.value(
          value: EventsProvider.instance,
        ),
        ChangeNotifierProvider<UpdateManager>.value(
          value: UpdateManager.instance,
        ),
        ChangeNotifierProvider<UnityPlayers>.value(
          value: UnityPlayers.instance,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          navigatorObservers: [NObserver()],
          locale: settings.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: settings.themeMode,
          theme: createTheme(themeMode: ThemeMode.light),
          darkTheme: createTheme(themeMode: ThemeMode.dark),
          initialRoute: '/',
          routes: {
            '/': (context) => const Home(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/events') {
              final data = settings.arguments! as Map;
              final event = data['event'] as Event;
              final upcomingEvents =
                  (data['upcoming'] as Iterable<Event>?) ?? [];
              final videoPlayer = data['videoPlayer'] as UnityVideoPlayer?;

              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/events',
                  arguments: event,
                ),
                builder: (context) {
                  return EventPlayerScreen(
                    event: event,
                    upcomingEvents: upcomingEvents,
                    player: videoPlayer,
                  );
                },
              );
            }

            if (settings.name == '/fullscreen') {
              final data = settings.arguments! as Map;
              final Device device = data['device'];
              final UnityVideoPlayer player = data['player'];
              final bool ptzEnabled = data['ptzEnabled'] ?? false;

              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/fullscreen',
                  arguments: device,
                ),
                builder: (context) {
                  return LivePlayer(
                    player: player,
                    device: device,
                    ptzEnabled: ptzEnabled,
                  );
                },
              );
            }

            if (settings.name == '/rtsp') {
              final url = settings.arguments as String;
              return MaterialPageRoute(
                settings: RouteSettings(
                  name: '/rtsp',
                  arguments: url,
                ),
                builder: (context) {
                  return LivePlayer.fromUrl(
                    url: url,
                    device: Device.dump(
                      name: 'External stream',
                      url: url,
                    )..server = Server.dump(name: url),
                  );
                },
              );
            }

            return null;
          },
        ),
      ),
    );
  }
}

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
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:status_bar_control/status_bar_control.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/home.dart';
import 'package:bluecherry_client/firebase_messaging_background_handler.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setSize(const Size(900, 645));
      await windowManager.setMinimumSize(const Size(900, 600));
      await windowManager.center();
      await windowManager.show();
      await windowManager.setSkipTaskbar(false);
    });

    DartVLC.initialize();
  }

  // Request notifications permission for iOS, Android 13+ and Windows.
  //
  // permission_handler only supports these platforms
  if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
    try {
      final result = await Permission.notification.request();
      debugPrint(result.toString());
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  }
  HttpOverrides.global = DevHttpOverrides();
  await Hive.initFlutter();
  await MobileViewProvider.ensureInitialized();
  await DesktopViewProvider.ensureInitialized();
  await ServersProvider.ensureInitialized();
  await SettingsProvider.ensureInitialized();

  /// Firebase messaging isn't available on desktop platforms
  if (!isDesktop) {
    await FirebaseConfiguration.ensureInitialized();
    // Restore the navigation bar & status bar styling.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    StatusBarControl.setStyle(
      getStatusBarStyleFromBrightness(
        SettingsProvider.instance.themeMode == ThemeMode.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  runApp(const MyApp());
}

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider.instance,
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: settings.themeMode,
          theme: createTheme(themeMode: ThemeMode.light),
          darkTheme: createTheme(themeMode: ThemeMode.dark),
          home: const MyHomePage(),
          builder: (context, child) {
            return Column(children: [
              if (isDesktop) const WindowButtons(),
              Expanded(child: ClipRect(child: child!)),
            ]);
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MobileViewProvider>(
          create: (context) => MobileViewProvider.instance,
        ),
        ChangeNotifierProvider<ServersProvider>(
          create: (context) => ServersProvider.instance,
        ),
        ChangeNotifierProvider<DesktopViewProvider>(
          create: (context) => DesktopViewProvider.instance,
        ),
      ],
      builder: (context, child) => const Home(),
    );
  }
}

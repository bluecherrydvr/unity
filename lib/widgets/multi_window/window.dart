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

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// A widget that provides a [Window] for the [child] widget.
///
/// This is used to provide an app for secondary windows.
class AlternativeWindow extends StatefulWidget {
  final ThemeMode mode;

  final Widget child;

  /// Creates a new [AlternativeWindow] instance.
  const AlternativeWindow({
    super.key,
    required this.mode,
    required this.child,
  });

  static AlternativeWindowState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AlternativeWindowState>();
  }

  @override
  State<AlternativeWindow> createState() => AlternativeWindowState();
}

class AlternativeWindowState extends State<AlternativeWindow> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider.value(value: DesktopViewProvider.instance),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [NObserver()],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: widget.mode,
        theme: createTheme(themeMode: ThemeMode.light),
        darkTheme: createTheme(themeMode: ThemeMode.dark),
        debugShowCheckedModeBanner: false,
        home: widget.child,
      ),
    );
  }
}

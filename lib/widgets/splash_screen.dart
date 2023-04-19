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

import 'dart:ui' as ui;

import 'package:bluecherry_client/utils/theme.dart';
import 'package:flutter/material.dart';

/// The local splash screen of the app
///
/// This is mainly used by desktop apps while the app is rendering. On mobile,
/// the platform splash screen is used instead
class SplashScreen extends StatelessWidget {
  /// Creates an unity splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark =
        ui.PlatformDispatcher.instance.platformBrightness == ui.Brightness.dark;
    final theme = createTheme(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );

    return Container(
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/icon.png',
        height: 100.0,
        width: 100.0,
      ),
    );
  }
}

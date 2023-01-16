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

import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kPrimaryColorLight = Color(0xFF3F51B5);
const kPrimaryColorDark = Color(0xFF8C9EFF);
const kAccentColorLight = Color(0xffff4081);
const kAccentColorDark = Color(0xffff4081);

/// Creates a new [ThemeData] to theme applications's various UI elements & [Widget]s based on the passed [ThemeMode].
///
/// This follows the Material Design guidelines. See: https://material.io/
///
/// In Material Design, we have a prominent primary color, which is used to color various parts e.g. buttons, app-bars, tabs etc.
/// And, there is a secondary color called accent color, which is used less frequently and is used to color various parts e.g. floating action buttons, switches etc.
///
/// These colors are different for light and dark themes. So, we have two sets of primary and accent colors.
/// See [kPrimaryColorLight], [kPrimaryColorDark], [kAccentColorLight], [kAccentColorDark].
///
/// In general, there are two modes: [ThemeMode.light] and [ThemeMode.dark].
/// There's also [ThemeMode.system] which makes the app pick the theme based on the system settings.
///
/// **NOTE:** [TextTheme]s are significantly tweaked & different for both desktop & mobile platforms.
///
ThemeData createTheme({
  required ThemeMode themeMode,
}) {
  final light = themeMode == ThemeMode.light;
  final primary = light ? kPrimaryColorLight : kPrimaryColorDark;
  final accent = light ? kAccentColorLight : kAccentColorDark;
  late TextTheme textTheme;
  if (isDesktop) {
    textTheme = TextTheme(
      /// Leading tile widgets text theme.
      displayLarge: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),

      /// [AlbumTile] text theme.
      displayMedium: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headlineMedium: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headlineSmall: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
      ),
      titleMedium: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
    );
  } else {
    textTheme = TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 18.0,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 16.0,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black54 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
    );
  }

  final colorScheme = ColorScheme.fromSeed(
    brightness: light ? Brightness.light : Brightness.dark,
    seedColor: primary,
    secondary: accent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,

    // ignore: deprecated_member_use
    androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primary,
      selectionColor: primary.withOpacity(0.2),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: MaterialStateProperty.all(true),
      thickness: MaterialStateProperty.all(8.0),
      trackBorderColor:
          MaterialStateProperty.all(light ? Colors.black12 : Colors.white24),
      trackColor:
          MaterialStateProperty.all(light ? Colors.black12 : Colors.white24),
      crossAxisMargin: 0.0,
      radius: Radius.zero,
      minThumbLength: 96.0,
      thumbColor: MaterialStateProperty.resolveWith(
        (states) {
          if ([
            MaterialState.hovered,
            MaterialState.dragged,
            MaterialState.focused,
            MaterialState.pressed,
          ].fold(false, (val, el) => val || states.contains(el))) {
            return light ? Colors.black54 : Colors.white54;
          } else {
            return light ? Colors.black26 : Colors.white24;
          }
        },
      ),
    ),
    buttonTheme:
        ButtonThemeData(disabledColor: light ? Colors.black12 : Colors.white24),
    splashFactory: InkSparkle.splashFactory,
    highlightColor: defaultTargetPlatform == TargetPlatform.android
        ? Colors.transparent
        : null,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: light ? const Color(0xFF202020) : Colors.white,
      actionTextColor: primary,
      contentTextStyle: textTheme.headlineMedium?.copyWith(
        color: light ? Colors.white : Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: light ? Colors.black26 : Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: primary,
          width: 2.0,
        ),
      ),
    ),
    splashColor: primary.withOpacity(0.15),
    appBarTheme: AppBarTheme(
      // color: Colors.transparent,
      shadowColor: light ? Colors.white : const Color(0xFF202020),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: light ? Colors.black12 : Colors.white12,
        statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
        statusBarBrightness: light ? Brightness.light : Brightness.dark,
      ),
      scrolledUnderElevation: 0.0,
      elevation: 0.0,
      iconTheme: IconThemeData(
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        size: 24.0,
      ),
      actionsIconTheme: IconThemeData(
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        size: 24.0,
      ),
      titleTextStyle: TextStyle(
        fontSize: 18.0,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontWeight: FontWeight.w500,
      ),
      centerTitle: [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform),
    ),
    iconTheme: IconThemeData(
      color: light ? const Color(0xFF757575) : const Color(0xFF8A8A8A),
      size: 24,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    tooltipTheme: TooltipThemeData(
      textStyle: isDesktop
          ? TextStyle(
              fontSize: 12.0,
              color: light ? Colors.white : Colors.black,
            )
          : null,
      decoration: BoxDecoration(
        color: light ? Colors.grey.shade900 : Colors.white,
        borderRadius:
            isMobile ? BorderRadius.circular(16.0) : BorderRadius.circular(6.0),
      ),
      height: isMobile ? 32.0 : null,
      verticalOffset: isDesktop ? 28.0 : null,
      preferBelow: isDesktop ? true : null,
      waitDuration: const Duration(seconds: 1),
    ),
    fontFamily: defaultTargetPlatform == TargetPlatform.linux ? 'Inter' : null,
    expansionTileTheme: const ExpansionTileThemeData(
      shape: RoundedRectangleBorder(),
      collapsedShape: RoundedRectangleBorder(),
    ),
  );
}

/// Returns either [dark] or [light] colors based on the brightness of the current
/// theme
Color colorFromBrightness(
  BuildContext context, {
  required Color light,
  required Color dark,
}) {
  switch (Theme.of(context).brightness) {
    case Brightness.dark:
      return dark;
    case Brightness.light:
      return light;
  }
}

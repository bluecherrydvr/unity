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
import 'package:bluecherry_client/widgets/misc.dart';
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
  bool light = themeMode == ThemeMode.light;
  final primary = light ? kPrimaryColorLight : kPrimaryColorDark;
  final accent = light ? kAccentColorLight : kAccentColorDark;
  late TextTheme textTheme;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    textTheme = TextTheme(
      /// Leading tile widgets text theme.
      headline1: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),

      /// [AlbumTile] text theme.
      headline2: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      headline3: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headline4: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headline5: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
      ),
      subtitle1: TextStyle(
        color: light ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      bodyText2: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      caption: TextStyle(
        color: light
            ? Colors.black.withOpacity(0.70)
            : Colors.white.withOpacity(0.70),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
    );
  } else {
    textTheme = TextTheme(
      headline1: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 18.0,
      ),
      headline2: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 16.0,
      ),
      headline3: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
      headline4: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
      ),
      headline5: TextStyle(
        fontWeight: FontWeight.normal,
        color: light ? Colors.black54 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
    );
  }

  return ThemeData(
    useMaterial3: true,

    // ignore: deprecated_member_use
    androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
    // Explicitly using [ChipThemeData] on Linux since it seems to be falling back to Ubuntu's font family.
    chipTheme: Platform.isLinux
        ? ChipThemeData(
            backgroundColor: primary,
            disabledColor: primary.withOpacity(0.2),
            selectedColor: primary,
            secondarySelectedColor: accent,
            padding: EdgeInsets.zero,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
            ),
            secondaryLabelStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.normal,
              fontFamily: 'Inter',
            ),
            brightness: Brightness.dark,
          )
        : null,
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
    splashFactory:
        Platform.isAndroid ? InkSparkle.splashFactory : InkRipple.splashFactory,
    highlightColor: Platform.isAndroid ? Colors.transparent : null,
    primaryColorLight: primary,
    primaryColor: primary,
    primaryColorDark: primary,
    scaffoldBackgroundColor: light ? Colors.white : const Color(0xFF121212),
    toggleableActiveColor: primary,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: light ? const Color(0xFF202020) : Colors.white,
      actionTextColor: primary,
      contentTextStyle: textTheme.headline4?.copyWith(
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
    cardTheme: CardTheme(
      color: light ? Colors.white : const Color(0xFF242424),
    ),
    backgroundColor: primary.withOpacity(0.24),
    dividerColor: light ? Colors.black12 : Colors.white24,
    disabledColor: light ? Colors.black38 : Colors.white38,
    tabBarTheme: TabBarTheme(
      labelColor: primary,
      unselectedLabelColor:
          light ? Colors.black54 : Colors.white.withOpacity(0.67),
    ),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 4.0,
      color: light ? Colors.white : const Color(0xFF292929),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: light ? Colors.white : const Color(0xFF141414),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: light ? Colors.white : const Color(0xFF202020),
      surfaceTintColor: light ? Colors.white : const Color(0xFF202020),
      shadowColor: light ? Colors.white : const Color(0xFF202020),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: light ? Colors.black12 : Colors.white12,
        statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
        statusBarBrightness: light ? Brightness.light : Brightness.dark,
      ),
      elevation: isDesktop ? 0.1 : 4.0,
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
      centerTitle: Platform.isIOS || Platform.isMacOS,
    ),
    iconTheme: IconThemeData(
      color: light ? const Color(0xFF757575) : const Color(0xFF8A8A8A),
      size: 24,
    ),
    dialogBackgroundColor: light ? Colors.white : const Color(0xFF202020),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: light ? primary : const Color(0xFF272727),
      selectedItemColor: Colors.white.withOpacity(0.87),
      unselectedItemColor: Colors.white54,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: ColorScheme.fromSwatch(
      brightness: light ? Brightness.light : Brightness.dark,
      cardColor: light ? Colors.white : const Color(0xFF242424),
    ).copyWith(
      primary: primary,
      secondary: accent,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: Platform.isWindows || Platform.isLinux || Platform.isMacOS
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
      height: Platform.isAndroid || Platform.isIOS ? 32.0 : null,
      verticalOffset: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 28.0
          : null,
      preferBelow: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? true
          : null,
      waitDuration: const Duration(seconds: 1),
    ),
    fontFamily: Platform.isLinux ? 'Inter' : null,
  );
}

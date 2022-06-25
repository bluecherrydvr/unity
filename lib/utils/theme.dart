/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:status_bar_control/status_bar_control.dart';

ThemeData createTheme({
  ThemeMode themeMode = ThemeMode.light,
}) {
  bool isLight = themeMode == ThemeMode.light;
  final color = isLight ? Colors.indigo : Colors.indigo.shade400;
  const accent = Color(0xffff4081);
  late TextTheme textTheme;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    textTheme = TextTheme(
      /// Leading tile widgets text theme.
      headline1: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
      ),

      /// [AlbumTile] text theme.
      headline2: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      headline3: TextStyle(
        color: isLight
            ? Colors.black.withOpacity(0.87)
            : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headline4: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      headline5: TextStyle(
        color: isLight
            ? Colors.black.withOpacity(0.87)
            : Colors.white.withOpacity(0.87),
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
      ),
      subtitle1: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
      ),
      bodyText2: TextStyle(
        color: isLight
            ? Colors.black.withOpacity(0.87)
            : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
      caption: TextStyle(
        color: isLight
            ? Colors.black.withOpacity(0.87)
            : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
      ),
    );
  } else {
    textTheme = TextTheme(
      headline1: TextStyle(
        fontWeight: FontWeight.normal,
        color: isLight ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 18.0,
      ),
      headline2: TextStyle(
        fontWeight: FontWeight.normal,
        color: isLight ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 16.0,
      ),
      headline3: TextStyle(
        fontWeight: FontWeight.normal,
        color: isLight ? Colors.black87 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
      headline4: TextStyle(
        fontWeight: FontWeight.normal,
        color: isLight ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontSize: 14.0,
      ),
      headline5: TextStyle(
        fontWeight: FontWeight.normal,
        color: isLight ? Colors.black54 : Colors.white.withOpacity(0.54),
        fontSize: 14.0,
      ),
    );
  }
  StatusBarControl.setStyle(
    isLight ? StatusBarStyle.DARK_CONTENT : StatusBarStyle.LIGHT_CONTENT,
  );
  return ThemeData(
    // ignore: deprecated_member_use
    androidOverscrollIndicator: AndroidOverscrollIndicator.stretch,
    // Explicitly using [ChipThemeData] on Linux since it seems to be falling back to Ubuntu's font family.
    chipTheme: Platform.isLinux
        ? ChipThemeData(
            backgroundColor: color,
            disabledColor: color.withOpacity(0.2),
            selectedColor: color,
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
      cursorColor: color,
      selectionColor: color.withOpacity(0.2),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: MaterialStateProperty.all(true),
      thickness: MaterialStateProperty.all(8.0),
      trackBorderColor:
          MaterialStateProperty.all(isLight ? Colors.black12 : Colors.white24),
      trackColor:
          MaterialStateProperty.all(isLight ? Colors.black12 : Colors.white24),
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
            return isLight ? Colors.black54 : Colors.white54;
          } else {
            return isLight ? Colors.black26 : Colors.white24;
          }
        },
      ),
    ),
    buttonTheme: ButtonThemeData(
        disabledColor: isLight ? Colors.black12 : Colors.white24),
    splashFactory: InkRipple.splashFactory,
    primaryColorLight: color,
    primaryColor: color,
    primaryColorDark: color,
    scaffoldBackgroundColor: isLight ? Colors.white : const Color(0xFF121212),
    toggleableActiveColor: color,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isLight ? const Color(0xFF202020) : Colors.white,
      actionTextColor: color,
      contentTextStyle: textTheme.headline4?.copyWith(
        color: isLight ? Colors.white : Colors.black,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: isLight ? Colors.black26 : Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: color,
          width: 2.0,
        ),
      ),
    ),
    cardColor: isLight ? Colors.white : const Color(0xFF242424),
    backgroundColor: color.withOpacity(0.24),
    dividerColor: isLight ? Colors.black12 : Colors.white24,
    disabledColor: isLight ? Colors.black38 : Colors.white38,
    tabBarTheme: TabBarTheme(
      labelColor: color,
      unselectedLabelColor:
          isLight ? Colors.black54 : Colors.white.withOpacity(0.67),
    ),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 4.0,
      color: isLight ? Colors.white : const Color(0xFF292929),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: isLight ? Colors.white : const Color(0xFF141414),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: isLight ? Colors.white : const Color(0xFF202020),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: isLight ? Colors.black12 : Colors.white12,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        statusBarBrightness: isLight ? Brightness.dark : Brightness.light,
      ),
      elevation: 4.0,
      iconTheme: IconThemeData(
        color: isLight ? const Color(0xFF757575) : const Color(0xFF8A8A8A),
        size: 24.0,
      ),
      actionsIconTheme: IconThemeData(
        color: isLight ? const Color(0xFF757575) : const Color(0xFF8A8A8A),
        size: 24.0,
      ),
      titleTextStyle: TextStyle(
        fontSize: 18.0,
        color: isLight ? Colors.black87 : Colors.white.withOpacity(0.87),
        fontWeight: FontWeight.w500,
      ),
    ),
    iconTheme: IconThemeData(
      color: isLight ? const Color(0xFF757575) : const Color(0xFF8A8A8A),
      size: 24,
    ),
    dialogBackgroundColor: isLight ? Colors.white : const Color(0xFF202020),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isLight ? color : const Color(0xFF272727),
      selectedItemColor: Colors.white.withOpacity(0.87),
      unselectedItemColor: Colors.white54,
    ),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: color,
      secondary: accent,
      brightness: isLight ? Brightness.light : Brightness.dark,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isLight ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(4.0),
      ),
      verticalOffset: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? 36.0
          : null,
      preferBelow: Platform.isWindows || Platform.isLinux || Platform.isMacOS
          ? true
          : null,
      waitDuration: const Duration(seconds: 1),
    ),
    fontFamily: Platform.isLinux ? 'Inter' : null,
  );
}

class Accent {
  final Color light;
  final Color dark;

  const Accent(this.light, this.dark);
}

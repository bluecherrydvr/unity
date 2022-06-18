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

import 'package:flutter/widgets.dart';

/// Locales supported by the application.
/// See `./assets/translations/*` for the translations.
const kSupportedLocales = [Locale('en', 'US')];

/// Interpreted as the current application version.
/// Update the [String]'s value before an update.
const kAppVersion = 'v0.0.1';

/// Default port used in Bluecherry DVR server.
const kDefaultPort = 7001;

/// Default username used in Bluecherry DVR server.
const kDefaultUsername = 'Admin';

/// Default password used in Bluecherry DVR server.
const kDefaultPassword = 'bluecherry';

/// Number of tips present in the app.
const kInAppTipsCount = 4;

/// Keys used for storing data in cache using `package:shared_preferences`.

const kSharedPreferencesServers = 'servers';
const kSharedPreferencesMobileView = 'mobile_view';
const kSharedPreferencesMobileViewTab = 'mobile_view_current_tab';
const kSharedPreferencesNotificationToken = 'notification_token';
const kSharedPreferencesThemeMode = 'theme_mode';
const kSharedPreferencesDateFormat = 'date_format';
const kSharedPreferencesTimeFormat = 'time_format';

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio. Only relevant on desktop.
const kDeviceTileWidth = 640.0;

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio. Only relevant on desktop.
const kDeviceTileHeight = 360.0;

/// Margin between & around a [DeviceTile]. Only relevant on desktop.
const kDeviceTileMargin = 16.0;

/// Default libVLC flags used while rendering the video output. Only relevant on desktop.
const kLibVLCFlags = [
  '--no-audio',
  '--rtsp-tcp',
  '--network-caching=0',
  '--rtsp-caching=150',
  '--no-stats',
  '--tcp-caching=150',
  '--rtsp-frame-buffer-size=500000',
  '--realrtsp-caching=150',
];

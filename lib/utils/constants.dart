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

import 'dart:ui' show Size;

import 'package:uuid/uuid.dart';

/// Default port used in Bluecherry DVR server.
const kDefaultPort = 7001;

/// Default port used in the RTSP connection.
const kDefaultRTSPPort = 7002;

/// Default username used in Bluecherry DVR server.
const kDefaultUsername = 'Admin';

/// Default password used in Bluecherry DVR server.
const kDefaultPassword = 'bluecherry';

// Keys used for storing data.
const kStorageServers = 'servers';
const kStorageMobileView = 'mobile_view';
const kStorageMobileViewTab = 'mobile_view_current_tab';
const kStorageDesktopLayouts = 'desktop_view_layouts';
const kStorageDesktopCurrentLayout = 'desktop_view_current_layout';
const kStorageNotificationToken = 'notification_token';
const kStorageDownloads = 'downloads';
const kStorageEventsPlayback = 'events_playback';
const kStorageAutomaticUpdates = 'automatic_download_updates';
const kStorageLastCheck = 'last_update_check';
const kStorageEvents = 'events';

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio. Only relevant on desktop.
const kDeviceTileWidth = 640.0;

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio. Only relevant on desktop.
const kDeviceTileHeight = 360.0;

/// Margin between & around a [DeviceTile]. Only relevant on desktop.
const kDeviceTileMargin = 16.0;

/// Uuid generator
const uuid = Uuid();

/// If the screen size is smaller or equal to this, a mobile view shall be used
const kMobileBreakpoint = Size(800, 500);

/// Aspect ratio of a single camera tile
const kHorizontalAspectRatio = 16 / 9;

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

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio.
const kDeviceTileWidth = 640.0;

/// Used as frame buffer size in [DeviceTile], and calculating aspect ratio.
const kDeviceTileHeight = 360.0;

/// Margin between & around a [DeviceTile].
const kDeviceTileMargin = 8.0;

/// Default libVLC flags used while rendering the video output.
const kLibVLCFlags = [
  '--no-audio',
  '--rtsp-tcp',
  '--network-caching=150',
  '--network-caching=0',
  '--rtsp-caching=150',
  '--no-stats',
  '--tcp-caching=150',
  '--rtsp-frame-buffer-size=500000',
  '--realrtsp-caching=150',
];

const kDefaultPort = 7001;
const kDefaultUsername = 'Admin';
const kDefaultPassword = 'bluecherry';

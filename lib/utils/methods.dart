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
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

Future<String?> get clientUUID async {
  final instance = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final ios = await instance.iosInfo;
    return ios.identifierForVendor;
  } else if (Platform.isAndroid) {
    final androidDeviceInfo = await instance.androidInfo;
    return androidDeviceInfo.androidId;
  }
  return null;
}

String getEventNameFromID(String id) => {
      'device_state': 'Device State Event',
      'motion_event': 'Motion Event',
    }[id]!;

bool isValidEventType(String? eventType) =>
    ['motion_event', 'device_state'].contains(eventType);

Future<void> setDevicePreferredOrientations(
  List<DeviceOrientation> orientations,
) {
  _orientations.add(orientations);
  return SystemChrome.setPreferredOrientations(orientations);
}

Future<void> restoreLastDevicePreferredOrientations() async {
  _orientations.removeLast();
  await SystemChrome.setPreferredOrientations(_orientations.last);
}

final List<List<DeviceOrientation>> _orientations = [];

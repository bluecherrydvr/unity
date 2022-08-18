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

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// A helper singleton to set preferred orientation for the app.
class DeviceOrientations {
  /// [DeviceOrientations] singleton instance.
  static final DeviceOrientations instance = DeviceOrientations._();

  /// Private constructor.
  DeviceOrientations._();

  Future<void> set(
    List<DeviceOrientation> orientations,
  ) {
    _stack.add(orientations);
    debugPrint(orientations.toString());
    return SystemChrome.setPreferredOrientations(orientations);
  }

  Future<void> restoreLast() async {
    _stack.removeLast();
    debugPrint(_stack.toString());
    await SystemChrome.setPreferredOrientations(_stack.last);
  }

  /// Maintain a stack of the last set of orientations, to switch back to the most recent one.
  final List<List<DeviceOrientation>> _stack = [];
}

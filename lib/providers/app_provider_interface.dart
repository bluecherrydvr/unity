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

import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/storage.dart';
import 'package:flutter/widgets.dart';

abstract class UnityProvider extends ChangeNotifier {
  Future<void> initialize();
  Future<void> reloadInterface() => initialize();

  String? key;

  @protected
  Future<void> initializeStorage(String key) async {
    this.key = key;
    try {
      await restore();
    } catch (error, stackTrace) {
      await save();

      handleError(error, stackTrace, 'Failed to restore $key');
    }
  }

  @mustCallSuper
  @protected
  Future<void> save({bool notifyListeners = true}) async {
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  @mustCallSuper
  @protected
  Future<void> restore({bool notifyListeners = true}) async {
    if (notifyListeners) {
      this.notifyListeners();
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      for (var key in data.keys) {
        final value = data[key];
        assert(
          value is String ||
              value is int ||
              value is double ||
              value is bool ||
              value == null,
        );
        if (value != null) {
          secureStorage.write(
            key: key,
            value: value?.toString(),
          );
        } else {
          debugPrint('Could not write $key: $value. Invalid value.');
        }
      }
    } catch (error, stackTrace) {
      handleError(error, stackTrace, 'Failed to write data to $key');
      return Future.value();
    }
  }
}

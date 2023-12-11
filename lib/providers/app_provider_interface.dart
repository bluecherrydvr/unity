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

import 'package:flutter/widgets.dart';
import 'package:safe_local_storage/safe_local_storage.dart';

abstract class UnityProvider extends ChangeNotifier {
  Future<void> initialize();
  Future<void> reloadInterface() => initialize();

  @protected
  Future<void> initializeStorage(SafeLocalStorage storage, String key) async {
    try {
      final hive = await storage.read() as Map;
      if (!hive.containsKey(key)) {
        await save();
      } else {
        await restore();
      }
    } catch (e) {
      await save();
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
}

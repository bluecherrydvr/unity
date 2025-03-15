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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:flutter/widgets.dart';

enum PTZCommand {
  move,
  stop;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return switch (this) {
      PTZCommand.stop => localizations.stop,
      PTZCommand.move => localizations.move,
    };
  }
}

enum Movement {
  noMovement,
  moveNorth,
  moveSouth,
  moveWest,
  moveEast,
  moveWide,
  moveTele;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return switch (this) {
      Movement.moveNorth => localizations.moveNorth,
      Movement.moveSouth => localizations.moveSouth,
      Movement.moveWest => localizations.moveWest,
      Movement.moveEast => localizations.moveEast,
      Movement.moveWide => localizations.moveWide,
      Movement.moveTele => localizations.moveTele,
      Movement.noMovement => localizations.noMovement,
    };
  }
}

enum PresetCommand { query, save, rename, go, clear }

extension PtzApiExtension on API {
  /// * <https://bluecherry-apps.readthedocs.io/en/latest/development.html#controlling-ptz-cameras>
  Future<bool> ptz({
    required Device device,
    required Movement movement,
    PTZCommand command = PTZCommand.move,
    int panSpeed = 1,
    int tiltSpeed = 1,
    int duration = 250,
  }) async {
    if (!device.hasPTZ) return false;

    final server = device.server;

    final url = Uri.https(
      '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
      '/media/ptz.php',
      {
        'id': '${device.id}',
        'command': command.name,

        // commands
        if (movement == Movement.moveNorth)
          'tilt':
              'u' //up
        else if (movement == Movement.moveSouth)
          'tilt':
              'd' //down
        else if (movement == Movement.moveWest)
          'pan':
              'l' //left
        else if (movement == Movement.moveEast)
          'pan':
              'r' //right
        else if (movement == Movement.moveWide)
          'zoom':
              'w' //wide
        else if (movement == Movement.moveTele)
          'zoom': 't', //tight
        // speeds
        if (command == PTZCommand.move) ...{
          if (panSpeed > 0) 'panspeed': '$panSpeed',
          if (tiltSpeed > 0) 'tiltspeed': '$tiltSpeed',
          if (duration >= -1) 'duration': '$duration',
        },
      },
    );

    debugPrint(url.toString());

    final response = await API.client.get(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (server.cookie != null) API.cookieHeader: server.cookie!,
      },
    );

    debugPrint('${command.name} ${response.statusCode}');

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  /// * <https://bluecherry-apps.readthedocs.io/en/latest/development.html#controlling-ptz-cameras>
  Future<bool> presets({
    required Device device,
    required PresetCommand command,
    String? presetId,
    String? presetName,
  }) async {
    if (!device.hasPTZ) return false;

    final server = device.server;

    assert(presetName != null || command != PresetCommand.save);

    final url = Uri.https(
      '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
      '/media/ptz.php',
      {
        'id': '${device.id}',
        'command': command.name,
        if (presetId != null) 'preset': presetId,
        if (presetName != null) 'name': presetName,
      },
    );

    debugPrint(url.toString());

    final response = await API.client.get(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
        if (server.cookie != null) API.cookieHeader: server.cookie!,
      },
    );

    debugPrint('${command.name} ${response.body} ${response.statusCode}');

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }
}

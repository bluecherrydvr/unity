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

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/api/ptz.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:flutter/material.dart';

typedef PTZComamndsBuilder = Widget Function(
  BuildContext context,
  List<PTZControllerCommand> commands,
);

class PTZControllerCommand {
  final Movement movement;
  final PTZCommand command;

  const PTZControllerCommand({
    this.movement = Movement.noMovement,
    this.command = PTZCommand.move,
  });
}

class PTZController extends StatefulWidget {
  const PTZController({
    super.key,
    required this.builder,
    required this.device,
    this.enabled = true,
  });

  final PTZComamndsBuilder builder;
  final Device device;

  final bool enabled;

  @override
  State<PTZController> createState() => _PTZControllerState();
}

class _PTZControllerState extends State<PTZController> {
  /// This ensures the commands will be sent only once.
  bool lock = false;

  List<PTZControllerCommand> commands = [];

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.builder(context, commands);

    return HoverButton(
      onPressed: () {},
      onTapUp: () async {
        debugPrint('stopping');
        const cmd = PTZControllerCommand(command: PTZCommand.stop);
        setState(() => commands.add(cmd));
        await API.instance.ptz(
          device: widget.device,
          movement: Movement.noMovement,
          command: PTZCommand.stop,
        );
        setState(() => commands.remove(cmd));
      },
      onVerticalDragUpdate: (d) async {
        if (lock) return;
        lock = true;

        if (d.delta.dy < 0) {
          debugPrint('moving up ${d.delta.dy}');

          const cmd = PTZControllerCommand(movement: Movement.moveNorth);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveNorth,
          );
          setState(() => commands.remove(cmd));
        } else {
          debugPrint('moving down ${d.delta.dy}');
          const cmd = PTZControllerCommand(movement: Movement.moveSouth);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveSouth,
          );
          setState(() => commands.remove(cmd));
        }
      },
      onVerticalDragEnd: (_) => lock = false,
      onHorizontalDragUpdate: (d) async {
        if (lock) return;
        lock = true;

        if (d.delta.dx < 0) {
          debugPrint('moving left ${d.delta.dx}');
          const cmd = PTZControllerCommand(movement: Movement.moveWest);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveWest,
          );
          setState(() => commands.remove(cmd));
        } else {
          debugPrint('moving right ${d.delta.dx}');
          const cmd = PTZControllerCommand(movement: Movement.moveEast);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveEast,
          );
          setState(() => commands.remove(cmd));
        }
      },
      onHorizontalDragEnd: (_) => lock = false,
      onScaleUpdate: (details) async {
        if (lock ||
            details.scale.isNegative ||
            details.scale.toString().runes.last.isEven) return;
        lock = true;

        if (details.scale > 1.0) {
          debugPrint('zooming up');
          const cmd = PTZControllerCommand(movement: Movement.moveTele);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveTele,
          );
          setState(() => commands.remove(cmd));
        } else {
          debugPrint('zooming down');
          const cmd = PTZControllerCommand(movement: Movement.moveWide);
          setState(() => commands.add(cmd));
          await API.instance.ptz(
            device: widget.device,
            movement: Movement.moveWide,
          );
          setState(() => commands.remove(cmd));
        }
      },
      onScaleEnd: (_) => lock = false,
      builder: (context, states) {
        return widget.builder(context, commands);
      },
    );
  }
}

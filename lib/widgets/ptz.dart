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
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef PTZComamndsBuilder = Widget Function(
  BuildContext context,
  List<PTZControllerCommand> commands,
  BoxConstraints constraints,
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
    if (!widget.enabled) {
      return HoverButton(
        forceEnabled: true,
        hitTestBehavior: HitTestBehavior.translucent,
        listenTo: const {ButtonStates.hovering},
        builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
          return widget.builder(context, commands, constraints);
        }),
      );
    }

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
        return LayoutBuilder(builder: (context, constraints) {
          return widget.builder(context, commands, constraints);
        });
      },
    );
  }
}

/// This widget is used to display the PTZ commands sent to the server.
///
/// When the server receives the command, the command vanishes.
class PTZData extends StatelessWidget {
  final List<PTZControllerCommand> commands;

  const PTZData({super.key, required this.commands});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 16.0),
        constraints: const BoxConstraints(minHeight: 140.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: commands.map<String>((cmd) {
            switch (cmd.command) {
              case PTZCommand.move:
                return '${cmd.command.locale(context)}: ${cmd.movement.locale(context)}';
              case PTZCommand.stop:
                return cmd.command.locale(context);
            }
          }).map<Widget>((text) {
            return Text(text, style: const TextStyle(color: Colors.white));
          }).toList(),
        ),
      ),
    );
  }
}

/// A button that toggles PTZ on/off.
class PTZToggleButton extends StatelessWidget {
  final bool ptzEnabled;
  final ValueChanged<bool> onChanged;

  final Color? enabledColor;
  final Color? disabledColor;

  const PTZToggleButton({
    super.key,
    required this.ptzEnabled,
    required this.onChanged,
    this.enabledColor,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(children: [
      SquaredIconButton(
        icon: Icon(
          Icons.videogame_asset,
          color: ptzEnabled
              ? enabledColor ?? Colors.white
              : disabledColor ??
                  theme.colorScheme.onInverseSurface.withOpacity(0.86),
        ),
        tooltip: ptzEnabled ? loc.enabledPTZ : loc.disabledPTZ,
        onPressed: () => onChanged(!ptzEnabled),
      ),
      // TODO(bdlukaa): enable presets when the API is ready
      // SquaredIconButton(
      //   icon: Icon(
      //     Icons.dataset,
      //     color: ptzEnabled ? Colors.white : theme.disabledColor,
      //   ),
      //   tooltip: ptzEnabled
      //       ? loc.enabledPTZ
      //       : loc.disabledPTZ,
      //   onPressed: !ptzEnabled
      //       ? null
      //       : () {
      //           showDialog(
      //             context: context,
      //             builder: (context) {
      //               return PresetsDialog(device: widget.device);
      //             },
      //           );
      //         },
      // ),
    ]);
  }
}

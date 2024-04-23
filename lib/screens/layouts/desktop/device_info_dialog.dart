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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> showDeviceInfoDialog(BuildContext context, Device device) async {
  await showDialog(
    context: context,
    builder: (context) => DeviceInfoDialog(device: device),
  );
}

class DeviceInfoDialog extends StatefulWidget {
  final Device device;

  const DeviceInfoDialog({super.key, required this.device});

  @override
  State<DeviceInfoDialog> createState() => _DeviceInfoDialogState();
}

class _DeviceInfoDialogState extends State<DeviceInfoDialog> {
  bool _showStreamUrl = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.device.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(loc.serverName, widget.device.server.ip),
          _buildInfoTile(
            loc.status,
            widget.device.status ? loc.online : loc.offline,
            TextStyle(
              color: widget.device.status
                  ? theme.extension<UnityColors>()!.successColor
                  : theme.colorScheme.error,
            ),
          ),
          _buildInfoTile(loc.uri, widget.device.uri),
          _buildInfoTile(
            loc.resolution,
            '${widget.device.resolutionX ?? '${loc.unknown} '}'
            'x'
            '${widget.device.resolutionY ?? ' ${loc.unknown}'}',
          ),
          _buildInfoTile(
              loc.isPtzSupported, widget.device.hasPTZ ? loc.yes : loc.no),
          _buildInfoTileWidget(
            loc.streamURL,
            Row(children: [
              Text(
                _showStreamUrl
                    ? widget.device.streamURL
                    : List.generate(widget.device.streamURL.length, (index) {
                        return '•';
                      }).join(),
              ),
              const SizedBox(width: 6.0),
              SquaredIconButton(
                onPressed: () =>
                    setState(() => _showStreamUrl = !_showStreamUrl),
                tooltip: _showStreamUrl ? loc.hide : loc.show,
                icon: Icon(
                  _showStreamUrl ? Icons.visibility_off : Icons.visibility,
                  size: 18.0,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, [TextStyle? valueStyle]) {
    return _buildInfoTileWidget(title, Text(value, style: valueStyle));
  }

  Widget _buildInfoTileWidget(String title, Widget value) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return IntrinsicHeight(
        child: Row(children: [
          SizedBox(
            width: 100.0,
            child: Text(
              title,
              style: theme.textTheme.labelLarge,
              textAlign: TextAlign.end,
            ),
          ),
          const VerticalDivider(),
          Flexible(child: value),
        ]),
      );
    });
  }
}

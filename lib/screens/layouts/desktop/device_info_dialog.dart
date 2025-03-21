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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/security.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    final settings = context.watch<SettingsProvider>();
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
              color:
                  widget.device.status
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
            loc.isPtzSupported,
            widget.device.hasPTZ ? loc.yes : loc.no,
          ),
          if (widget.device.oldestRecording != null)
            _buildInfoTile(
              loc.oldestRecording,
              settings.formatDate(widget.device.oldestRecording!),
            ),
          _buildInfoTileWidget(
            loc.streamURL,
            Row(
              children: [
                Text(
                  _showStreamUrl
                      ? widget.device.streamURL
                      : List.generate(
                        widget.device.streamURL.length ~/ 2,
                        (index) => '•',
                      ).join(),
                ),
                const SizedBox(width: 6.0),
                CopyDeviceUrlButton(device: widget.device),
                SquaredIconButton(
                  onPressed: _onToggleStreamUrl,
                  tooltip: _showStreamUrl ? loc.hide : loc.show,
                  icon: Icon(
                    _showStreamUrl ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, [TextStyle? valueStyle]) {
    return _buildInfoTileWidget(title, Text(value, style: valueStyle));
  }

  Widget _buildInfoTileWidget(String title, Widget value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 120.0,
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.end,
                ),
              ),
              const VerticalDivider(),
              Flexible(child: value),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onToggleStreamUrl() async {
    final canShow = _showStreamUrl || await UnityAuth.ask();
    if (!mounted) return;

    if (canShow) {
      setState(() => _showStreamUrl = !_showStreamUrl);
    } else {
      UnityAuth.showAccessDeniedMessage(context);
    }
  }
}

class CopyDeviceUrlButton extends StatelessWidget {
  final Device device;

  const CopyDeviceUrlButton({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return SquaredIconButton(
      padding: EdgeInsetsDirectional.zero,
      icon: const Icon(Icons.copy),
      tooltip: MaterialLocalizations.of(context).copyButtonLabel,
      onPressed: () => _onCopy(context),
    );
  }

  Future<void> _onCopy(BuildContext context) async {
    final canCopy = await UnityAuth.ask();
    if (!context.mounted) return;

    final loc = AppLocalizations.of(context);

    if (canCopy) {
      Clipboard.setData(ClipboardData(text: device.streamURL));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.copiedToClipboard('URL'),
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          width: 200.0,
        ),
      );
    } else {
      UnityAuth.showAccessDeniedMessage(context);
    }
  }
}

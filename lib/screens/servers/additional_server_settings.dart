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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/stream_data.dart';
import 'package:bluecherry_client/screens/servers/wizard.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class AdditionalServerSettings extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Server? server;
  final Future<void> Function(Server server) onServerChanged;

  /// Whether this isn't adding the server for the first time
  final bool isEditing;

  const AdditionalServerSettings({
    super.key,
    required this.onBack,
    required this.onNext,
    required this.server,
    required this.onServerChanged,
    this.isEditing = false,
  });

  @override
  State<AdditionalServerSettings> createState() =>
      _AdditionalServerSettingsState();
}

class _AdditionalServerSettingsState extends State<AdditionalServerSettings> {
  late bool connectAutomaticallyAtStartup =
      widget.server?.additionalSettings.connectAutomaticallyAtStartup ??
          SettingsProvider.instance.kConnectAutomaticallyAtStartup.value;
  late StreamingType? streamingType =
      widget.server?.additionalSettings.preferredStreamingType;
  late RTSPProtocol? rtspProtocol =
      widget.server?.additionalSettings.rtspProtocol;
  late RenderingQuality? renderingQuality =
      widget.server?.additionalSettings.renderingQuality;
  late UnityVideoFit? videoFit = widget.server?.additionalSettings.videoFit;

  Future<void> updateServer() async {
    if (widget.server != null) {
      await widget.onServerChanged(widget.server!.copyWith(
        additionalSettings: AdditionalServerOptions(
          connectAutomaticallyAtStartup: connectAutomaticallyAtStartup,
          preferredStreamingType: streamingType,
          rtspProtocol: rtspProtocol,
          renderingQuality: renderingQuality,
          videoFit: videoFit,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return PopScope(
      canPop: widget.isEditing,
      onPopInvokedWithResult: (_, __) => widget.onBack(),
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsetsDirectional.all(16.0),
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width / 2.5,
          ),
          child: Card(
            margin: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: isDesktop
                        ? MediaQuery.sizeOf(context).width / 2.5
                        : null,
                    child: buildCardAppBar(
                      title: loc.serverSettings,
                      description: loc.serverSettingsDescription,
                      onBack: widget.server == null ? widget.onBack : null,
                    ),
                  ),
                  _buildSelectable<StreamingType>(
                    title: loc.streamingProtocol,
                    values: StreamingType.values,
                    value: streamingType,
                    defaultValue: settings.kStreamingType.value,
                    onChanged: (value) {
                      setState(() {
                        streamingType = value;
                      });
                    },
                  ),
                  _buildSelectable<RTSPProtocol>(
                    title: loc.rtspProtocol,
                    values: RTSPProtocol.values,
                    value: rtspProtocol,
                    defaultValue: settings.kRTSPProtocol.value,
                    onChanged: (value) {
                      setState(() {
                        rtspProtocol = value;
                      });
                    },
                  ),
                  _buildSelectable<UnityVideoFit>(
                    title: loc.cameraViewFit,
                    description: loc.cameraViewFitDescription,
                    values: UnityVideoFit.values,
                    value: videoFit,
                    defaultValue: settings.kVideoFit.value,
                    onChanged: (value) {
                      setState(() {
                        videoFit = value;
                      });
                    },
                  ),
                  _buildSelectable<RenderingQuality>(
                    title: loc.renderingQuality,
                    description: loc.renderingQualityDescription,
                    values: RenderingQuality.values,
                    value: renderingQuality,
                    defaultValue: settings.kRenderingQuality.value,
                    onChanged: (value) {
                      setState(() {
                        renderingQuality = value;
                      });
                    },
                  ),
                  const Divider(),
                  CheckboxListTile.adaptive(
                    value: connectAutomaticallyAtStartup,
                    onChanged: (value) {
                      setState(
                        () => connectAutomaticallyAtStartup = value ?? true,
                      );
                    },
                    title: Text(loc.connectAutomaticallyAtStartup),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    secondary: Tooltip(
                      message: loc.connectAutomaticallyAtStartupDescription,
                      child: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.secondary,
                        size: 20.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 12.0),
                    child: Row(children: [
                      if (streamingType != null ||
                          rtspProtocol != null ||
                          renderingQuality != null ||
                          videoFit != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              streamingType = null;
                              rtspProtocol = null;
                              renderingQuality = null;
                              videoFit = null;
                            });
                          },
                          child: Text(loc.clear),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          await updateServer();
                          widget.onNext();
                        },
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(8.0),
                          child: Text(loc.finish.toUpperCase()),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectable<T extends Enum>({
    required String title,
    String? description,
    required Iterable<T> values,
    required T? value,
    required T defaultValue,
    required ValueChanged<T?> onChanged,
  }) {
    return Builder(builder: (context) {
      return ListTile(
        title: Row(children: [
          Flexible(child: Text(title)),
          if (description != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 6.0),
              child: Tooltip(
                message: description,
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 16.0,
                ),
              ),
            ),
        ]),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: isDesktop ? 175.0 : 90.0,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              // isExpanded: true,
              value: value,
              onChanged: (v) {
                onChanged(v);
              },
              hint: Text(defaultValue.name.toUpperCase()),
              items: values.map((value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Row(children: [
                    Text(value.name.toUpperCase()),
                    if (defaultValue == value) ...[
                      const SizedBox(width: 10.0),
                      const DefaultValueIcon(),
                    ],
                  ]),
                );
              }).toList(),
            ),
          ),
        ),
      );
    });
  }
}

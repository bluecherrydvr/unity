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

import 'dart:async';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/config.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/device_grid/desktop/external_stream.dart';
import 'package:bluecherry_client/widgets/ptz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

Future<Device?> showStreamDataDialog(
  BuildContext context, {
  required Device device,
  required bool ptzEnabled,
  required ValueChanged<bool> onPTZEnabledChanged,
  required UnityVideoFit fit,
  required ValueChanged<UnityVideoFit> onFitChanged,
}) {
  final video = UnityVideoView.maybeOf(context);

  return showDialog<Device>(
    context: context,
    builder: (context) => StreamData(
      device: device,
      video: video!,
      ptzEnabled: ptzEnabled,
      onPTZEnabledChanged: onPTZEnabledChanged,
      fit: fit,
      onFitChanged: onFitChanged,
    ),
  );
}

class StreamData extends StatefulWidget {
  final Device device;
  final VideoViewInheritance video;

  final bool ptzEnabled;
  final ValueChanged<bool> onPTZEnabledChanged;

  final UnityVideoFit fit;
  final ValueChanged<UnityVideoFit> onFitChanged;

  const StreamData({
    super.key,
    required this.device,
    required this.video,
    required this.ptzEnabled,
    required this.onPTZEnabledChanged,
    required this.fit,
    required this.onFitChanged,
  });

  @override
  State<StreamData> createState() => _StreamDataState();
}

class _StreamDataState extends State<StreamData> {
  late var matrixType = widget.device.matrixType;

  late var ptzEnabled = widget.ptzEnabled;
  late var fit = widget.fit;
  late final overlays = List<VideoOverlay>.from(widget.device.overlays);

  late final StreamSubscription<double> volumeSubscription;

  @override
  void initState() {
    super.initState();
    volumeSubscription = widget.video.player.volumeStream.listen((volume) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    volumeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);

    //This, basically, would
    // contain all the information about this stream - and provide
    // more options, such as adding/changing overlays.
    return AlertDialog(
      title: Text(widget.device.name),
      content: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.streamingSetings,
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  loc.volume(
                    (widget.video.player.volume * 100).toInt().toString(),
                  ),
                  style: theme.textTheme.headlineSmall,
                ),
                Slider(
                  value: widget.video.player.volume,
                  onChanged: (v) {
                    widget.video.player.setVolume(v);
                  },
                ),
                Text(loc.cameraViewFit, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6.0),
                ToggleButtons(
                  isSelected: UnityVideoFit.values
                      .map((fit) => fit == this.fit)
                      .toList(),
                  children: UnityVideoFit.values.map((fit) {
                    return Row(children: [
                      const SizedBox(width: 12.0),
                      Icon(fit.icon),
                      const SizedBox(width: 8.0),
                      Text(fit.locale(context)),
                      if (settings.cameraViewFit == fit) ...[
                        const SizedBox(width: 10.0),
                        Tooltip(
                          message: loc.defaultField,
                          preferBelow: true,
                          child: const Icon(
                            Icons.loyalty,
                            size: 18.0,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                      const SizedBox(width: 12.0),
                    ]);
                  }).toList(),
                  onPressed: (index) {
                    setState(() => fit = UnityVideoFit.values[index]);
                  },
                ),
                if (settings.betaMatrixedZoomEnabled) ...[
                  const SizedBox(height: 16.0),
                  Text(loc.matrixType, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6.0),
                  Center(
                    child: ToggleButtons(
                      isSelected: MatrixType.values.map((type) {
                        return type.index == matrixType.index;
                      }).toList(),
                      onPressed: (type) => setState(() {
                        matrixType = MatrixType.values[type];
                      }),
                      // constraints: buttonConstraints,
                      children: MatrixType.values.map<Widget>((type) {
                        return Row(children: [
                          const SizedBox(width: 12.0),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: KeyedSubtree(
                              key: ValueKey(type),
                              child: IconTheme.merge(
                                data: const IconThemeData(size: 22.0),
                                child: type.icon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(type.toString()),
                          const SizedBox(width: 12.0),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.device.overlays.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 8.0),
              child: VerticalDivider(),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280.0),
              child: IntrinsicWidth(
                child: VideoOverlaysEditor(
                  overlays: overlays,
                  onChanged: (index, overlay) {
                    setState(() => overlays[index] = overlay);
                  },
                ),
              ),
            ),
          ]
        ]),
      ),
      actions: [
        Row(children: [
          if (widget.device.hasPTZ)
            PTZToggleButton(
              enabledColor: theme.colorScheme.inversePrimary,
              disabledColor: theme.colorScheme.inversePrimary.withOpacity(0.5),
              ptzEnabled: ptzEnabled,
              onChanged: (v) {
                setState(() => ptzEnabled = v);
              },
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          const SizedBox(width: 8.0),
          FilledButton(
            onPressed: () {
              widget.onFitChanged(fit);
              widget.onPTZEnabledChanged(ptzEnabled);

              Navigator.of(context).pop(
                widget.device.copyWith(
                  overlays: overlays,
                  matrixType: matrixType,
                ),
              );
            },
            child: Text(loc.finish),
          ),
        ]),
      ],
    );
  }
}

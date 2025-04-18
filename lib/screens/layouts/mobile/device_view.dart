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
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/layouts/video_status_label.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/widgets/device_selector.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This manages the selection of devices on the mobile view. When selected, a
/// [DeviceTile] is shown. If not, am empty view is shown with the possibility
/// to choose devices
///
/// See also:
///
///  * [SmallDeviceGrid], used to render mobile views
///  * [DeviceTile], used to render the tile
class MobileDeviceView extends StatefulWidget {
  /// Which tab is selected on the mobile device grid
  final int tab;

  /// The index of this view
  final int index;

  /// Creates a device view used in mobile grids
  const MobileDeviceView({super.key, required this.tab, required this.index});

  @override
  State<MobileDeviceView> createState() => _MobileDeviceViewState();
}

class _MobileDeviceViewState extends State<MobileDeviceView> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final view = context.watch<MobileViewProvider>();
    final device = view.devices[widget.tab]![widget.index];

    if (device != null) {
      return Material(
        color: Colors.black,
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            DeviceTile(device: device, tab: widget.tab, index: widget.index),
            PositionedDirectional(
              top: 0.0,
              end: 0.0,
              child: Container(
                height: 72.0,
                width: 72.0,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: AlignmentDirectional.topEnd,
                    end: AlignmentDirectional.bottomStart,
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4.0, end: 4.0),
              child: Builder(
                builder: (context) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (d) async {
                      final box = context.findRenderObject() as RenderBox;
                      final buttonPos = box.localToGlobal(
                        const Offset(kMinInteractiveDimension - 14.0, 0.0),
                        ancestor:
                            Navigator.of(context).context.findRenderObject(),
                      );

                      const menuWidth = 200.0;
                      final position = RelativeRect.fromDirectional(
                        textDirection: Directionality.of(context),
                        start: buttonPos.dx - menuWidth,
                        top: buttonPos.dy,
                        end: buttonPos.dx,
                        bottom: buttonPos.dy + menuWidth,
                      );

                      await showMenu<IconData>(
                        context: context,
                        position: position,
                        items: [
                          PopupMenuItem(
                            child: Text(loc.removeCamera),
                            onTap: () => view.remove(widget.tab, widget.index),
                          ),
                          PopupMenuItem(
                            child: Text(loc.replaceCamera),
                            onTap: () async {
                              if (mounted) {
                                final device = await showDeviceSelector(
                                  context,
                                );
                                if (device != null) {
                                  view.replace(
                                    widget.tab,
                                    widget.index,
                                    device,
                                  );
                                }
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: Text(loc.reloadCamera),
                            onTap: () => view.reload(widget.tab, widget.index),
                          ),
                        ],
                      );
                    },
                    child: SquaredIconButton(
                      onPressed: null,
                      icon: Icon(moreIconData, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    final selected = view.devices[widget.tab]!.whereType<Device>();

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.zero,
        color: Colors.black,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceSelector(selected: selected),
              ),
            );
            if (result is Device) {
              view.add(widget.tab, widget.index, result);
              if (mounted) setState(() {});
            }
          },
          child: Container(
            alignment: AlignmentDirectional.center,
            child: const Icon(Icons.add, size: 36.0, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class DeviceTile extends StatefulWidget {
  final Device device;
  final int tab;
  final int index;

  const DeviceTile({
    super.key,
    required this.device,
    required this.tab,
    required this.index,
  });

  @override
  State<StatefulWidget> createState() => DeviceTileState();
}

class DeviceTileState extends State<DeviceTile> {
  bool get hover =>
      context.read<MobileViewProvider>().hoverStates[widget.tab]?[widget
          .index] ??
      false;

  set hover(bool value) =>
      context.read<MobileViewProvider>().hoverStates[widget.tab]?[widget
              .index] =
          value;

  @override
  Widget build(BuildContext context) {
    context.watch<UnityPlayers>();
    final videoPlayer = UnityPlayers.players[widget.device.uuid];
    if (videoPlayer == null) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return GestureDetectorWithReducedDoubleTapTime(
      onTap: () {
        if (mounted) setState(() => hover = !hover);
      },
      // Fullscreen on double-tap.
      onDoubleTap: () async {
        if (videoPlayer.error == null) {
          await Navigator.of(context).pushNamed(
            '/fullscreen',
            arguments: {'device': widget.device, 'player': videoPlayer},
          );
        }
      },
      child: UnityVideoView(
        heroTag: widget.device.streamURL,
        player: videoPlayer,
        fit:
            widget.device.server.additionalSettings.videoFit ??
            settings.kVideoFit.value,
        paneBuilder: (context, controller) {
          final video = UnityVideoView.of(context);
          final error = video.error;
          final isLoading = !controller.isSeekable;

          return ClipRect(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (error != null)
                  ErrorWarning(message: error)
                else if (isLoading)
                  const CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 1.5,
                  ),
                if (video.lastImageUpdate != null)
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: hover ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: SquaredIconButton(
                      // splashRadius: 20.0,
                      onPressed: () async {
                        await Navigator.of(context).pushNamed(
                          '/fullscreen',
                          arguments: {
                            'device': widget.device,
                            'player': videoPlayer,
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 32.0,
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: 6.0,
                  start: 6.0,
                  child: VideoStatusLabel(
                    video: video,
                    device: widget.device,
                    position: VideoStatusLabelPosition.top,
                  ),
                ),
                PositionedDirectional(
                  bottom: 0.0,
                  start: 0.0,
                  end: 0.0,
                  child: AnimatedSlide(
                    offset: Offset(
                      0,
                      error != null || isLoading || hover ? 0.0 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Container(
                      padding: const EdgeInsetsDirectional.only(
                        start: 16.0,
                        top: 6.0,
                        bottom: 6.0,
                        end: 16.0,
                      ),
                      alignment: AlignmentDirectional.centerEnd,
                      color: Colors.black26,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.device.name,
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 14.0,
                                  ),
                                ),
                                Text(
                                  widget.device.server.name,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.device.hasPTZ)
                            Icon(
                              Icons.videogame_asset,
                              color: Colors.white,
                              size: 20.0,
                              semanticLabel: loc.ptzSupported,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

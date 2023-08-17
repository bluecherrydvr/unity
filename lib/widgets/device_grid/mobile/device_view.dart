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
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/widgets/device_grid/video_status_label.dart';
import 'package:bluecherry_client/widgets/device_selector_screen.dart';
import 'package:bluecherry_client/widgets/error_warning.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// This manages the selection of devices on the mobile view. When selected, a
/// [DeviceTile] is shown. If not, am empty view is shown with the possibility
/// to choose devices
///
/// See also:
///
///  * [MobileDeviceGrid], used to render mobile views
///  * [DeviceTile], used to render the tile
class MobileDeviceView extends StatefulWidget {
  /// Which tab is selected on the mobile device grid
  final int tab;

  /// The index of this view
  final int index;

  /// Creates a device view used in mobile grids
  const MobileDeviceView({
    super.key,
    required this.tab,
    required this.index,
  });

  @override
  State<MobileDeviceView> createState() => _MobileDeviceViewState();
}

class _MobileDeviceViewState extends State<MobileDeviceView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.watch<MobileViewProvider>();
    final device = view.devices[widget.tab]![widget.index];

    if (device != null) {
      return Material(
        color: Colors.black,
        child: Stack(alignment: AlignmentDirectional.topEnd, children: [
          DeviceTile(
            device: device,
            tab: widget.tab,
            index: widget.index,
          ),
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
            child: Builder(builder: (context) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (d) async {
                  final box = context.findRenderObject() as RenderBox;
                  final buttonPos = box.localToGlobal(
                    const Offset(kMinInteractiveDimension - 14.0, 0.0),
                    ancestor: Navigator.of(context).context.findRenderObject(),
                  );

                  const menuWidth = 275.0;
                  final position = RelativeRect.fromLTRB(
                    buttonPos.dx - menuWidth,
                    buttonPos.dy,
                    buttonPos.dx,
                    buttonPos.dy + menuWidth,
                  );

                  final value = await showMenu<int>(
                    context: context,
                    position: position,
                    constraints: const BoxConstraints(
                      maxWidth: menuWidth,
                      minWidth: menuWidth,
                    ),
                    items: [
                      loc.removeCamera,
                      loc.replaceCamera,
                      loc.reloadCamera,
                    ].asMap().entries.map((e) {
                      return PopupMenuItem(
                        value: e.key,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            foregroundColor: theme.iconTheme.color,
                            child: Icon(<int, IconData>{
                              0: Icons.close_outlined,
                              1: Icons.add_outlined,
                              2: Icons.replay_outlined,
                            }[e.key]!),
                          ),
                          title: Text(e.value),
                        ),
                      );
                    }).toList(),
                  );

                  if (value == null || !mounted) return;

                  switch (value) {
                    case 0:
                      view.remove(widget.tab, widget.index);
                      if (mounted) setState(() {});

                      break;
                    case 1:
                      if (mounted) {
                        final result = await showDeviceSelectorScreen(context);
                        if (result != null) {
                          view.replace(widget.tab, widget.index, result);
                          if (mounted) setState(() {});
                        }
                      }
                      break;
                    case 2:
                      view.reload(widget.tab, widget.index);
                      break;
                  }
                },
                child: IconButton(
                  onPressed: null,
                  icon: Icon(moreIconData, color: Colors.white),
                ),
              );
            }),
          ),
        ]),
      );
    }

    final selected =
        view.devices[widget.tab]!.where((d) => d != null).cast<Device>();

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
                builder: (context) => DeviceSelectorScreen(selected: selected),
              ),
            );
            if (result is Device) {
              view.add(widget.tab, widget.index, result);
              if (mounted) setState(() {});
            }
          },
          child: Container(
            alignment: AlignmentDirectional.center,
            child: const Icon(
              Icons.add,
              size: 36.0,
              color: Colors.white,
            ),
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

  final double width;
  final double height;

  const DeviceTile({
    super.key,
    required this.device,
    required this.tab,
    required this.index,
    this.width = 640.0,
    this.height = 360.0,
  });

  @override
  State<StatefulWidget> createState() => DeviceTileState();
}

class DeviceTileState extends State<DeviceTile> {
  UnityVideoPlayer? get videoPlayer => UnityPlayers.players[widget.device];

  bool get hover =>
      context.read<MobileViewProvider>().hoverStates[widget.tab]
          ?[widget.index] ??
      false;

  set hover(bool value) =>
      context.read<MobileViewProvider>().hoverStates[widget.tab]
          ?[widget.index] = value;

  @override
  Widget build(BuildContext context) {
    if (videoPlayer == null) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GestureDetectorWithReducedDoubleTapTime(
      onTap: () {
        if (mounted) setState(() => hover = !hover);
      },
      // Fullscreen on double-tap.
      onDoubleTap: () async {
        if (videoPlayer == null) return;

        await Navigator.of(context).pushNamed(
          '/fullscreen',
          arguments: {
            'device': widget.device,
            'player': videoPlayer,
          },
        );
      },
      child: UnityVideoView(
        heroTag: widget.device.streamURL,
        player: videoPlayer!,
        paneBuilder: (context, controller) {
          final video = UnityVideoView.of(context);
          final error = video.error;

          return ClipRect(
            child: Stack(children: [
              if (error != null)
                ErrorWarning(message: error)
              else if (!controller.isSeekable || videoPlayer == null)
                const Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 4.4,
                  ),
                ),
              if (video.lastImageUpdate != null)
                Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: hover ? 1.0 : 0.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: IconButton(
                      splashRadius: 20.0,
                      onPressed: () async {
                        if (videoPlayer == null) return;

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
                ),
              PositionedDirectional(
                top: 6.0,
                start: 6.0,
                child: VideoStatusLabel(
                  video: video,
                  device: widget.device,
                ),
              ),
              PositionedDirectional(
                bottom: 0.0,
                start: 0.0,
                end: 0.0,
                child: AnimatedSlide(
                  offset: Offset(0, hover ? 0.0 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: 48.0,
                    alignment: AlignmentDirectional.centerEnd,
                    color: Colors.black26,
                    child: Row(children: [
                      const SizedBox(width: 16.0),
                      const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.device.name
                                  .split(' ')
                                  .map((word) => word.uppercaseFirst())
                                  .join(' '),
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
                      const SizedBox(width: 16.0),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

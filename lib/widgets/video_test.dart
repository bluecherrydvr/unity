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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/screens/layouts/desktop/viewport.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/video_player.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class VideoTest extends StatefulWidget {
  const VideoTest({super.key});

  @override
  State<VideoTest> createState() => _VideoTestState();
}

class _VideoTestState extends State<VideoTest> {
  final Device device = Device.dump(
    name: 'Big Buck Bunny',
    url:
        'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  );
  late final testVideoPlayer = UnityPlayers.forDevice(device);

  @override
  void initState() {
    super.initState();
    device.server = device.server.copyWith(name: 'By Blender Foundation');
  }

  @override
  void dispose() {
    testVideoPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ListView(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: UnityVideoView(
                player: testVideoPlayer,
                paneBuilder: (context, player) {
                  return DesktopTileViewport(
                    controller: player,
                    device: device,
                    showDebugInfo: true,
                    onFitChanged: (_) {},
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: VideoInfoCard(
                player: testVideoPlayer,
                uuid: device.uuid,
                title: '${device.name} (${device.server.name})',
              ),
            ),
          ],
        );
      },
    );
  }
}

class VideoInfoCard extends StatelessWidget {
  final UnityVideoPlayer player;
  final String uuid;
  final String? title;

  const VideoInfoCard({
    super.key,
    required this.player,
    required this.uuid,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    Widget buildCardProp(String title, String value) {
      return Row(
        children: [
          Text('$title:', style: theme.textTheme.labelMedium),
          const SizedBox(width: 4.0),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: player,
        child: Row(
          children: [
            Expanded(
              child: AutoSizeText(
                title ?? player.title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
              ),
            ),
            SquaredIconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.error),
              tooltip: loc.removePlayer,
              onPressed: () {
                final view = context.read<LayoutsProvider>();
                final device = view.layouts
                    .map<List<Device>>((l) => l.devices)
                    .reduce((a, b) => a + b)
                    .firstWhereOrNull((d) => d.uuid == uuid);
                if (device != null) view.removeDevices([device]);
              },
            ),
          ],
        ),
        builder: (context, title) {
          return ListView(
            padding: const EdgeInsets.all(12.0),
            shrinkWrap: true,
            children: [
              title!,
              AutoSizeText(uuid, style: theme.textTheme.bodySmall, maxLines: 1),
              const Divider(),
              buildCardProp('Position', player.currentPos.toString()),
              buildCardProp('Duration', player.duration.toString()),
              buildCardProp('Buffer', player.currentBuffer.toString()),
              buildCardProp('FPS', player.fps.toString()),
              buildCardProp('LIU', player.lastImageUpdate.toString()),
              buildCardProp(
                'Resolution',
                '${player.resolution?.width ?? '${loc.unknown} '}'
                    'x'
                    '${player.resolution?.height ?? ' ${loc.unknown}'}',
              ),
              buildCardProp('Quality', player.quality?.name ?? loc.unknown),
              buildCardProp('Volume', player.volume.toString()),
            ],
          );
        },
      ),
    );
  }
}

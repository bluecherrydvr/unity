import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/settings/mobile/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class ServerSettings extends StatelessWidget {
  const ServerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(children: [
      Text(
        loc.servers,
        style: theme.textTheme.titleMedium,
      ),
      const ServersList(),
      Text(
        'Streaming Settings',
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8.0),
      const StreamingSettings(),
      const SizedBox(height: 12.0),
      Text(
        'Cameras Settings',
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8.0),
      const CamerasSettings(),
    ]);
  }
}

class StreamingSettings extends StatelessWidget {
  const StreamingSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: const Text('Streaming type'),
          trailing: DropdownButton<StreamingType>(
            value: settings.streamingType,
            onChanged: (v) {
              if (v != null) {
                settings.streamingType = v;
              }
            },
            items: StreamingType.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Text(q.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          enabled: settings.streamingType == StreamingType.rtsp,
          title: const Text('RTSP protocol'),
          trailing: DropdownButton<RTSPProtocol>(
            value: settings.rtspProtocol,
            onChanged: settings.streamingType == StreamingType.rtsp
                ? (v) {
                    if (v != null) {
                      settings.rtspProtocol = v;
                    }
                  }
                : null,
            items: RTSPProtocol.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(p.name.toUpperCase()),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}

class CamerasSettings extends StatelessWidget {
  const CamerasSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final loc = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: const Text('Rendering quality'),
          subtitle: const Text(
            'The quality of the video rendering. The higher the quality, the more resources it takes.',
          ),
          trailing: DropdownButton<UnityVideoQuality>(
            value: settings.videoQuality,
            onChanged: (v) {
              if (v != null) {
                settings.videoQuality = v;
              }
            },
            items: UnityVideoQuality.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Text(q.locale(context)),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 8.0),
      Material(
        borderRadius: BorderRadius.circular(6.0),
        child: ListTile(
          title: Text(loc.cameraViewFit),
          subtitle: const Text('The way the video is displayed in the view.'),
          trailing: DropdownButton<UnityVideoFit>(
            value: settings.cameraViewFit,
            onChanged: (v) {
              if (v != null) {
                settings.cameraViewFit = v;
              }
            },
            items: UnityVideoFit.values.map((q) {
              return DropdownMenuItem(
                value: q,
                child: Row(children: [
                  Icon(q.icon),
                  const SizedBox(width: 8.0),
                  Text(q.locale(context)),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }
}

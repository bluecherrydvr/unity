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

import 'dart:io';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/events_timeline/desktop/timeline.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EventsAndDownloadsSettings extends StatelessWidget {
  const EventsAndDownloadsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(children: [
      SubHeader(loc.downloads),
      CheckboxListTile.adaptive(
        value: settings.kChooseLocationEveryTime.value,
        onChanged: (v) {
          if (v != null) {
            settings.kChooseLocationEveryTime.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.create_new_folder),
        ),
        title: Text(loc.chooseEveryDownloadsLocation),
        subtitle: Text(loc.chooseEveryDownloadsLocationDescription),
      ),
      ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.notifications_paused),
        ),
        title: Text(loc.downloadPath),
        subtitle: Text(settings.kDownloadsDirectory.value),
        trailing: const Icon(Icons.navigate_next),
        onTap: () async {
          final selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: loc.downloadPath,
            initialDirectory: settings.kDownloadsDirectory.value,
            lockParentWindow: true,
          );

          if (selectedDirectory != null) {
            settings.kDownloadsDirectory.value =
                Directory(selectedDirectory).path;
          }
        },
      ),
      CheckboxListTile.adaptive(
        value: settings.kAllowAppCloseWhenDownloading.value,
        onChanged: (v) {
          if (v != null) {
            settings.kAllowAppCloseWhenDownloading.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.close),
        ),
        title: Text(loc.allowCloseWhenDownloading),
      ),
      SubHeader(loc.events),
      if (settings.kShowDebugInfo.value)
        CheckboxListTile.adaptive(
          value: settings.kPictureInPicture.value,
          onChanged: (v) {
            if (v != null) {
              settings.kPictureInPicture.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.picture_in_picture),
          ),
          title: const Text('Picture-in-picture'),
          subtitle: const Text(
            'Move to picture-in-picture mode when the app moves to background.',
          ),
        ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.speed),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: Text(loc.initialEventSpeed),
        subtitle: Text(settings.kEventsSpeed.value.toStringAsFixed(1)),
        trailing: SizedBox(
          width: 160.0,
          child: Slider(
            value: settings.kEventsSpeed.value.clamp(
              settings.kEventsSpeed.min!,
              settings.kEventsSpeed.max!,
            ),
            min: settings.kEventsSpeed.min!,
            max: settings.kEventsSpeed.max!,
            onChanged: (v) {
              settings.kEventsSpeed.value = v;
            },
          ),
        ),
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.equalizer),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: Text(loc.initialEventVolume),
        subtitle: Text(settings.kEventsVolume.value.toStringAsFixed(1)),
        trailing: SizedBox(
          width: 160.0,
          child: Slider(
            value: settings.kEventsVolume.value,
            onChanged: (v) {
              settings.kEventsVolume.value = v;
            },
          ),
        ),
      ),
      const SizedBox(height: 20.0),
      SubHeader(loc.eventsTimeline),
      CheckboxListTile.adaptive(
        value: settings.kShowDifferentColorsForEvents.value,
        onChanged: (v) {
          if (v != null) {
            settings.kShowDifferentColorsForEvents.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.color_lens),
        ),
        title: Text(loc.differentEventColors),
        subtitle: Text(loc.differentEventColorsDescription),
      ),
      if (settings.kShowDebugInfo.value) ...[
        CheckboxListTile.adaptive(
          value: settings.kPauseToBuffer.value,
          onChanged: (v) {
            if (v != null) {
              settings.kPauseToBuffer.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.pause_presentation),
          ),
          title: const Text('Pause to buffer'),
          subtitle: const Text(
            'Whether the entire timeline should pause to buffer the events.',
          ),
        ),
      ],
      OptionsChooserTile<TimelineInitialPoint>(
        title: loc.initialTimelinePoint,
        description: loc.initialTimelinePointDescription,
        icon: Icons.flag,
        value: settings.kTimelineInitialPoint.value,
        values: [
          Option(
            value: TimelineInitialPoint.beginning,
            icon: Icons.start,
            text: loc.beginningInitialPoint,
          ),
          Option(
            value: TimelineInitialPoint.firstEvent,
            icon: Icons.first_page,
            text: loc.firstEventInitialPoint,
          ),
          Option(
            value: TimelineInitialPoint.hourAgo,
            icon: Icons.hourglass_bottom,
            text: loc.hourAgoInitialPoint,
          ),
        ],
        onChanged: (v) {
          settings.kTimelineInitialPoint.value = v;
        },
      ),
    ]);
  }
}

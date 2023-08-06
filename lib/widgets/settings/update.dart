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

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

/// The card that displays the update information.
class AppUpdateCard extends StatelessWidget {
  const AppUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final update = context.watch<UpdateManager>();

    if (update.hasUpdateAvailable) {
      return Card(
        margin: const EdgeInsetsDirectional.only(
          start: 10.0,
          end: 10.0,
          bottom: 6.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: Icon(
                Icons.update,
                size: 54.0,
                color: theme.colorScheme.primary,
              ),
            ),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New version available',
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(update.latestVersion.description),
                  ]),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  update.latestVersion.version,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6.0),
                FilledButton(
                  onPressed: () {},
                  child: const Text('Download'),
                ),
              ],
            ),
          ]),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsetsDirectional.only(
          start: 10.0,
          end: 10.0,
          bottom: 6.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: Stack(alignment: Alignment.center, children: [
                Icon(
                  Icons.update,
                  size: 54.0,
                  color: theme.colorScheme.primary,
                ),
                const Positioned(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: 'You are up to date.\n',
                    style: theme.textTheme.headlineMedium,
                  ),
                  TextSpan(
                    text: 'Last checked: 1 day ago',
                    style: theme.textTheme.labelMedium,
                  ),
                ]),
              ),
            ),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Check for updates'),
            ),
          ]),
        ),
      );
    }
  }
}

class AppUpdateOptions extends StatelessWidget {
  const AppUpdateOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      CheckboxListTile(
        onChanged: (_) {},
        value: true,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.podcasts),
        ),
        title: const Text('Automatic download updates'),
        subtitle: RichText(
          text: TextSpan(children: [
            const TextSpan(
              text:
                  'Be among the first to get the latest updates, fixes and improvements as they rool out.',
            ),
            TextSpan(
              text: '\nLearn more',
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()..onTap = () {},
            ),
          ]),
        ),
        isThreeLine: true,
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.history),
        ),
        title: const Text('Update history'),
        trailing: const Icon(Icons.navigate_next),
        onTap: () => showUpdateHistory(context),
      ),
    ]);
  }

  void showUpdateHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final update = context.watch<UpdateManager>();
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.8,
          builder: (context, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: update.versions.length,
              itemBuilder: (context, index) {
                final version = update.versions[index];
                return ListTile(
                  title: Row(children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: version.version),
                        const TextSpan(text: '   '),
                        TextSpan(
                          text: SettingsProvider.instance.dateFormat.format(
                            DateFormat('EEE, d MMM yyyy')
                                .parse(version.publishedAt),
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                      ]),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(start: 12.0),
                        child: Divider(),
                      ),
                    ),
                  ]),
                  subtitle: Text(version.description),
                  isThreeLine: true,
                  trailing: Link(
                    uri: Uri.parse(
                        'https://github.com/bluecherrydvr/unity/releases/tag/v${version.version}'),
                    builder: (context, followLink) {
                      return TextButton(
                        onPressed: followLink,
                        child: const Text('Learn more'),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

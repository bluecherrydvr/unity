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
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

/// The card that displays the update information.
class AppUpdateCard extends StatelessWidget {
  const AppUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final textDirection = Directionality.of(context);
    final update = context.watch<UpdateManager>();

    if (update.hasUpdateAvailable) {
      final executable = update.executableFor(update.latestVersion!.version);
      return Card(
        margin: EdgeInsetsDirectional.only(
          top: 8.0,
          start: DesktopSettings.horizontalPadding.resolve(textDirection).left,
          end: DesktopSettings.horizontalPadding.resolve(textDirection).right,
          bottom: 6.0,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
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
                    loc.newVersionAvailable,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(update.latestVersion!.description),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  update.latestVersion!.version,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6.0),
                if (update.downloading)
                  SizedBox(
                    height: 32.0,
                    width: 32.0,
                    child: CircularProgressIndicator(
                      value: update.downloadProgress,
                      strokeWidth: 2.0,
                    ),
                  )
                else if (executable != null)
                  FilledButton(
                    onPressed: () => update.install(
                      onFail: (type) => showInstallFailDialog(context, type),
                    ),
                    child: Text(loc.installVersion),
                  )
                else
                  FilledButton(
                    onPressed: () => update.download(
                      update.latestVersion!.version,
                    ),
                    child: Text(loc.downloadVersion),
                  ),
              ],
            ),
          ]),
        ),
      );
    } else {
      return Card(
        margin: EdgeInsetsDirectional.only(
          top: 8.0,
          bottom: 6.0,
          start: DesktopSettings.horizontalPadding.resolve(textDirection).left,
          end: DesktopSettings.horizontalPadding.resolve(textDirection).right,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: Row(children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12.0),
              child: Stack(alignment: AlignmentDirectional.center, children: [
                Icon(
                  Icons.update,
                  size: 54.0,
                  color: theme.colorScheme.primary,
                ),
                const PositionedDirectional(
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
                    text: '${loc.upToDate}\n',
                    style: theme.textTheme.headlineMedium,
                  ),
                  TextSpan(
                    text: loc.lastChecked(
                      () {
                        if (update.lastCheck == null) return loc.never;
                        if (DateUtils.isSameDay(
                          update.lastCheck,
                          DateTime.now(),
                        )) return loc.today;

                        if (DateUtils.isSameDay(
                          update.lastCheck,
                          DateTime.now().subtract(
                            const Duration(days: 1, minutes: 12),
                          ),
                        )) return loc.yesterday;

                        return DateFormat().format(update.lastCheck!);
                      }(),
                    ),
                    style: theme.textTheme.labelMedium,
                  ),
                ]),
              ),
            ),
            FilledButton.tonal(
              onPressed: update.checkForUpdates,
              child: update.loading
                  ? SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2.0,
                        semanticsLabel: loc.checkingForUpdates,
                      ),
                    )
                  : Text(loc.checkForUpdates),
            ),
          ]),
        ),
      );
    }
  }

  void showInstallFailDialog(BuildContext context, FailType failType) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) {
        late String title;
        late String failMessage;

        switch (failType) {
          case FailType.executableNotFound:
            title = loc.failedToUpdate;
            failMessage = loc.executableNotFound;
            break;
        }

        return AlertDialog(
          title: Text(title),
          content: Text(failMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.ok),
            ),
          ],
        );
      },
    );
  }
}

class AppUpdateOptions extends StatelessWidget {
  const AppUpdateOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final update = context.watch<UpdateManager>();
    return Column(children: [
      CheckboxListTile(
        onChanged: (v) {
          if (v != null) {
            update.automaticDownloads = v;
          }
        },
        value: update.automaticDownloads,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.podcasts),
        ),
        title: Text(loc.automaticDownloadUpdates),
        subtitle: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: loc.automaticDownloadUpdatesDescription),
              TextSpan(
                text: '\n${loc.learnMore}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.primary,
                ),
                mouseCursor: SystemMouseCursors.click,
                recognizer: TapGestureRecognizer()..onTap = () {},
              ),
            ],
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        isThreeLine: true,
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.history),
        ),
        title: Text(loc.updateHistory),
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
        final loc = AppLocalizations.of(context);
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.8,
          initialChildSize: 0.8,
          builder: (context, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: update.versions.length,
              itemBuilder: (context, index) {
                final version = update.versions.reversed.elementAt(index);
                return ListTile(
                  title: Row(children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: version.version),
                          const TextSpan(text: '   '),
                          TextSpan(
                            text: SettingsProvider.instance.dateFormat.format(
                              DateFormat('EEE, d MMM yyyy', 'en_US')
                                  .parse(version.publishedAt),
                            ),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        style: theme.textTheme.bodyMedium,
                      ),
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
                        child: Text(loc.learnMore),
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

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final update = context.watch<UpdateManager>();

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8.0),
        Text(update.packageInfo.version),
        const SizedBox(height: 8.0),
        Text(
          loc.versionText,
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: 8.0),
        Link(
          uri: Uri.https('www.bluecherrydvr.com', '/'),
          builder: (context, open) {
            return MaterialButton(
              onPressed: open,
              padding: EdgeInsetsDirectional.zero,
              minWidth: 0.0,
              child: Text(
                loc.website,
                semanticsLabel: 'www.bluecherrydvr.com',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

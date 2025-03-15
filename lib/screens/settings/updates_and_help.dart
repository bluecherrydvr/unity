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

import 'dart:io' hide Link;

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart';

class UpdatesSettings extends StatelessWidget {
  const UpdatesSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final update = context.watch<UpdateManager>();
    final settings = context.watch<SettingsProvider>();

    return ListView(
      children: [
        SubHeader(
          loc.privacyAndSecurity,
          padding: DesktopSettings.horizontalPadding,
        ),
        CheckboxListTile.adaptive(
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.analytics),
          ),
          contentPadding: DesktopSettings.horizontalPadding,
          title: Text(loc.allowDataCollection),
          subtitle: Text(loc.allowDataCollectionDescription),
          isThreeLine: true,
          value: settings.kAllowDataCollection.value,
          onChanged: (value) {
            if (value != null) {
              settings.kAllowDataCollection.value = value;
            }
          },
        ),
        OptionsChooserTile<EnabledPreference>(
          title: loc.automaticallyReportErrors,
          description: loc.automaticallyReportErrorsDescription,
          icon: Icons.error,
          value: settings.kAllowCrashReports.value,
          values: EnabledPreference.values.map(
            (e) => Option(text: e.name.uppercaseFirst, value: e),
          ),
          onChanged: (v) {
            settings.kAllowCrashReports.value = v;
          },
        ),
        if (settings.kShowDebugInfo.value) ...[
          const Divider(),
          ListTile(
            contentPadding: DesktopSettings.horizontalPadding,
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.iconTheme.color,
              child: const Icon(Icons.privacy_tip),
            ),
            title: Text(loc.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            contentPadding: DesktopSettings.horizontalPadding,
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.iconTheme.color,
              child: const Icon(Icons.policy),
            ),
            title: Text(loc.termsOfService),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
        if (!kIsWeb) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubHeader(
                loc.updates,
                subtext: loc.runningOn(() {
                  if (kIsWeb) {
                    return 'WEB';
                  } else if (Platform.isLinux) {
                    return loc.linux(UpdateManager.linuxEnvironment.name);
                  } else if (Platform.isWindows) {
                    return loc.windows;
                  }

                  return defaultTargetPlatform.name;
                }()),
                padding: DesktopSettings.horizontalPadding,
              ),
            ],
          ),
          const AppUpdateCard(),
          if (!isMacOS)
            CheckboxListTile.adaptive(
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
              contentPadding: DesktopSettings.horizontalPadding,
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
          if (kDebugMode && !isMacOS)
            CheckboxListTile.adaptive(
              secondary: CircleAvatar(
                backgroundColor: Colors.transparent,
                foregroundColor: theme.iconTheme.color,
                child: const Icon(Icons.memory),
              ),
              title: Text(loc.showReleaseNotes),
              subtitle: Text(loc.showReleaseNotesDescription),
              contentPadding: DesktopSettings.horizontalPadding,
              value: true,
              onChanged: (v) {},
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              foregroundColor: theme.iconTheme.color,
              child: const Icon(Icons.history),
            ),
            contentPadding: DesktopSettings.horizontalPadding,
            title: Text(loc.updateHistory),
            trailing: const Icon(Icons.navigate_next),
            onTap: () => showUpdateHistory(context),
          ),
          const Divider(height: 1.0),
        ],
        // TODO(bdlukaa): Show option to download the native client when running
        //                on the web.
        const About(),
      ],
    );
  }

  void showUpdateHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final settings = context.watch<SettingsProvider>();
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
                  title: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: version.version),
                            const TextSpan(text: '   '),
                            TextSpan(
                              text: settings.kDateFormat.value.format(
                                DateFormat(
                                  'EEE, d MMM yyyy',
                                  'en_US',
                                ).parse(version.publishedAt),
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
                    ],
                  ),
                  subtitle: Text(version.description),
                  isThreeLine: true,
                  trailing: Link(
                    uri: Uri.parse(
                      'https://github.com/bluecherrydvr/unity/releases/tag/v${version.version}',
                    ),
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

/// The card that displays the update information.
class AppUpdateCard extends StatelessWidget {
  const AppUpdateCard({super.key});

  @override
  Widget build(BuildContext context) {
    assert(!kIsWeb, 'This widget should not be used on the web');
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final textDirection = Directionality.of(context);
    final update = context.watch<UpdateManager>();

    final horizontalPadding = DesktopSettings.horizontalPadding.resolve(
      textDirection,
    );
    final cardMargin = EdgeInsetsDirectional.only(
      top: 8.0,
      start: horizontalPadding.left,
      end: horizontalPadding.right,
      bottom: 6.0,
    );

    final isMacOs = isDesktopPlatform && Platform.isMacOS;

    if (update.hasUpdateAvailable) {
      final executable =
          isMacOs ? null : update.executableFor(update.latestVersion!.version);
      return Card(
        margin: cardMargin,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: Row(
            children: [
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
                  if (isMacOs)
                    Link(
                      uri: Uri.parse(update.downloadMacOSRedirect),
                      builder: (context, followLink) {
                        return FilledButton(
                          onPressed: followLink,
                          child: const Text('Download at website'),
                        );
                      },
                    )
                  else if (update.downloading)
                    SizedBox(
                      height: 32.0,
                      width: 32.0,
                      child:
                          isCupertino
                              ? CupertinoActivityIndicator.partiallyRevealed(
                                progress: update.downloadProgress,
                              )
                              : CircularProgressIndicator(
                                value: update.downloadProgress,
                                strokeWidth: 2.0,
                              ),
                    )
                  else if (executable != null)
                    FilledButton(
                      onPressed:
                          () => update.install(
                            onFail:
                                (type) => showInstallFailDialog(context, type),
                          ),
                      child: Text(loc.installVersion),
                    )
                  else
                    FilledButton(
                      onPressed:
                          () => update.download(update.latestVersion!.version),
                      child: Text(loc.downloadVersion),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        margin: cardMargin,
        child: Padding(
          padding: const EdgeInsetsDirectional.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12.0),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
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
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${loc.upToDate}\n',
                        style: theme.textTheme.headlineMedium,
                      ),
                      TextSpan(
                        text: loc.lastChecked(() {
                          if (update.lastCheck == null) return loc.never;
                          if (DateUtils.isSameDay(
                            update.lastCheck,
                            DateTime.now(),
                          )) {
                            return '${loc.today}, ${DateFormat.Hms().format(update.lastCheck!)}';
                          }

                          if (DateUtils.isSameDay(
                            update.lastCheck,
                            DateTime.now().subtract(
                              const Duration(days: 1, minutes: 12),
                            ),
                          )) {
                            return '${loc.yesterday}, ${DateFormat.Hms().format(update.lastCheck!)}';
                          }

                          return DateFormat().format(update.lastCheck!);
                        }()),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: update.loading ? null : update.checkForUpdates,
                child:
                    update.loading
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
            ],
          ),
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

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final update = context.watch<UpdateManager>();

    return Padding(
      padding: DesktopSettings.horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8.0),
          if (update.packageInfo != null) ...[
            Text(update.packageInfo!.version),
            const SizedBox(height: 8.0),
            Text(loc.versionText, style: theme.textTheme.displayMedium),
          ],
          const SizedBox(height: 8.0),
          Row(
            children: [
              Link(
                uri: Uri.https('bluecherrydvr.com', '/'),
                builder: (context, open) {
                  return TextButton(
                    onPressed: open,
                    child: Text(
                      loc.website,
                      semanticsLabel: 'www.bluecherrydvr.com',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8.0),
              Link(
                uri: Uri.https('bluecherrydvr.com', '/contact/'),
                builder: (context, open) {
                  return TextButton(
                    onPressed: open,
                    child: Text(
                      loc.help,
                      semanticsLabel: 'www.bluecherrydvr.com/contact',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8.0),
              TextButton(
                onPressed: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Bluecherry Client',
                    applicationIcon: Image.asset('assets/images/icon.png'),
                    applicationVersion: update.packageInfo?.version,
                    applicationLegalese: '© 2022 Bluecherry, LLC',
                  );
                },
                child: Text(
                  loc.licenses,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

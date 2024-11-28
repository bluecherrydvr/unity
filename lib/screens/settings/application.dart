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
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/keyboard.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ApplicationSettings extends StatelessWidget {
  const ApplicationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(children: [
      SubHeader(loc.appearance, padding: DesktopSettings.horizontalPadding),
      OptionsChooserTile<ThemeMode>(
        title: loc.theme,
        description: loc.themeDescription,
        icon: Icons.contrast,
        value: settings.kThemeMode.value,
        values: ThemeMode.values.map((mode) {
          return Option(
            value: mode,
            icon: switch (mode) {
              ThemeMode.system => Icons.brightness_auto,
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
            },
            text: switch (mode) {
              ThemeMode.system => loc.system +
                  switch (MediaQuery.platformBrightnessOf(context)) {
                    Brightness.light => ' (${loc.light})',
                    Brightness.dark => ' (${loc.dark})',
                  },
              ThemeMode.light => loc.light,
              ThemeMode.dark => loc.dark,
            },
          );
        }),
        onChanged: (v) {
          settings.kThemeMode.value = v;
        },
      ),
      if (isMobilePlatform) ImmersiveModeTile(),
      const LanguageSection(),
      SubHeader(loc.dateAndTime, padding: DesktopSettings.horizontalPadding),
      const DateFormatSection(),
      const TimeFormatSection(),
      CheckboxListTile.adaptive(
        value: settings.kConvertTimeToLocalTimezone.value,
        onChanged: (v) {
          if (v != null) {
            settings.kConvertTimeToLocalTimezone.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.history_toggle_off),
        ),
        title: Text(loc.convertToLocalTime),
        subtitle: Text(loc.convertToLocalTimeDescription),
        isThreeLine: true,
      ),
      if (isDesktopPlatform) ...[
        const SubHeader('Window', padding: DesktopSettings.horizontalPadding),
        WindowSection(),
      ],
      if (settings.kShowDebugInfo.value) ...[
        const SubHeader(
          'Acessibility',
          padding: DesktopSettings.horizontalPadding,
        ),
        AcessibilitySection(),
      ],
      if (isDesktopPlatform) ...[
        SubHeader(
          'Keyboard Shortcuts',
          padding: DesktopSettings.horizontalPadding,
          trailing: TextButton(
            child: Text(
              'Reset Defaults',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Reset Keyboard Shortcuts'),
                  content: Text(
                    'Are you sure you want to reset all keyboard shortcuts to their default values?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<KeyboardBindings>().restoreDefaults();
                        Navigator.pop(context);
                      },
                      child: Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        KeyboardSection(),
      ],
    ]);
  }
}

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final currentLocale = Localizations.localeOf(context);
    const locales = AppLocalizations.supportedLocales;
    final names = LocaleNames.of(context)!;

    return DropdownButtonHideUnderline(
      child: ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.language),
        ),
        title: Text(loc.language),
        trailing: DropdownButton<Locale>(
          value: currentLocale,
          onChanged: (value) => settings.kLanguageCode.value = value!,
          items: locales.map((locale) {
            final name =
                names.nameOf(locale.toLanguageTag()) ?? locale.toLanguageTag();
            final nativeName = LocaleNamesLocalizationsDelegate
                    .nativeLocaleNames[locale.toLanguageTag()] ??
                locale.toLanguageTag();
            return DropdownMenuItem<Locale>(
              value: locale,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.uppercaseFirst,
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      nativeName.uppercaseFirst,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class DateFormatSection extends StatelessWidget {
  const DateFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final formats = [
      'dd MMMM yyyy',
      'EEEE, dd MMMM yyyy',
      'EE, dd MMMM yyyy',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'MM-dd-yyyy',
      'dd-MM-yyyy',
      'yyyy-MM-dd'
    ].map((e) => DateFormat(e, locale));

    return OptionsChooserTile(
      title: loc.dateFormat,
      description: loc.dateFormatDescription,
      icon: Icons.calendar_month,
      value: settings.kDateFormat.value.pattern,
      values: formats.map((format) {
        return Option(
          value: format.pattern,
          text: format.format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
        );
      }),
      onChanged: (v) {
        settings.kDateFormat.value = DateFormat(v!, locale);
      },
    );
  }
}

class TimeFormatSection extends StatelessWidget {
  const TimeFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final locale = Localizations.localeOf(context).toLanguageTag();

    final patterns = SettingsProvider.availableTimeFormats
        .map((pattern) => DateFormat(pattern, locale));
    final date = DateTime.utc(1969, 7, 20, 14, 18, 04);
    return OptionsChooserTile(
      title: loc.timeFormat,
      description: loc.timeFormatDescription,
      icon: Icons.hourglass_empty,
      value: settings.kTimeFormat.value.pattern,
      values: patterns.map((pattern) {
        return Option(
          value: pattern.pattern,
          text: pattern.format(date),
        );
      }),
      onChanged: (v) {
        settings.kTimeFormat.value = DateFormat(v!, locale);
      },
    );
  }
}

class WindowSection extends StatelessWidget {
  const WindowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (canLaunchAtStartup)
        CheckboxListTile.adaptive(
          value: settings.kLaunchAppOnStartup.value,
          onChanged: (v) {
            if (v != null) {
              settings.kLaunchAppOnStartup.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.launch),
          ),
          title: const Text('Launch app on startup'),
          subtitle: const Text(
            'Whether to launch the app when the system starts',
          ),
        ),
      CheckboxListTile.adaptive(
        value: settings.kFullscreen.value,
        onChanged: (v) {
          if (v != null) settings.kFullscreen.value = v;
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.fullscreen),
        ),
        title: const Text('Fullscreen Mode'),
        subtitle: const Text('Whether the app is in fullscreen mode or not.'),
      ),
      ImmersiveModeTile(),
      if (canUseSystemTray)
        CheckboxListTile.adaptive(
          value: settings.kMinimizeToTray.value,
          onChanged: (v) {
            if (v != null) {
              settings.kMinimizeToTray.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.sensor_door),
          ),
          title: const Text('Minimize to tray'),
          subtitle: const Text(
            'Whether to minimize app to the system tray when the window is '
            'closed. This will keep the app running in the background.',
          ),
        ),
    ]);
  }
}

/// Creates the Immersive Mode tile.
///
/// On Desktop, this is used alonside the Fullscreen mode tile. When in
/// fullscreen, the immersive mode hides the top bar and only shows it when
/// the user hovers over the top of the window.
///
/// On Mobile, this makes the app full-screen and hides the system UI.
class ImmersiveModeTile extends StatelessWidget {
  const ImmersiveModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return CheckboxListTile.adaptive(
      value: settings.kImmersiveMode.value,
      onChanged: settings.kFullscreen.value || isMobilePlatform
          ? (v) {
              if (v != null) settings.kImmersiveMode.value = v;
            }
          : null,
      contentPadding: DesktopSettings.horizontalPadding,
      secondary: CircleAvatar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.iconTheme.color,
        child: const Icon(Icons.web_asset),
      ),
      title: const Text('Immersive Mode'),
      subtitle: const Text(
        'This will hide the title bar and window controls. '
        'To show the top bar, hover over the top of the window. '
        'This only works in fullscreen mode.',
      ),
    );
  }
}

class AcessibilitySection extends StatelessWidget {
  const AcessibilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CheckboxListTile.adaptive(
        value: settings.kAnimationsEnabled.value,
        onChanged: (v) {
          if (v != null) {
            settings.kAnimationsEnabled.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.animation),
        ),
        title: const Text('Animations'),
        subtitle: const Text(
          'Disable animations on low-end devices to improve performance. This '
          'will also disable some visual effects. ',
        ),
      ),
      CheckboxListTile.adaptive(
        value: settings.kHighContrast.value,
        onChanged: (v) {
          if (v != null) {
            settings.kHighContrast.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.filter_b_and_w),
        ),
        title: const Text('High contrast mode'),
        subtitle: const Text(
          'Enable high contrast mode to make the app easier to read and use.',
        ),
      ),
      CheckboxListTile.adaptive(
        value: settings.kLargeFont.value,
        onChanged: (v) {
          if (v != null) {
            settings.kLargeFont.value = v;
          }
        },
        contentPadding: DesktopSettings.horizontalPadding,
        secondary: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.accessibility_new),
        ),
        title: const Text('Large Font'),
        subtitle: const Text(
          'Increase the size of the text in the app to make it easier to read.',
        ),
      ),
    ]);
  }
}

class KeyboardSection extends StatelessWidget {
  const KeyboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final keyboard = context.watch<KeyboardBindings>();
    return DataTable(
      columns: [
        DataColumn(label: Text('System')),
        DataColumn(label: Text('Command')),
        DataColumn(label: Text('Keybinding')),
      ],
      rows: [
        for (final keybinding in keyboard.all)
          DataRow(
            cells: [
              DataCell(Text(keybinding.system)),
              DataCell(Text(keybinding.name)),
              DataCell(
                Text(keybinding.value.debugDescribeKeys()),
                showEditIcon: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => KeybindingDialog(
                      keybinding: keybinding,
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}

class KeybindingDialog extends StatefulWidget {
  final KeybindingSetting keybinding;

  const KeybindingDialog({
    super.key,
    required this.keybinding,
  });

  @override
  State<KeybindingDialog> createState() => _KeybindingDialogState();
}

class _KeybindingDialogState extends State<KeybindingDialog> {
  SingleActivator? _newActivator;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeypress(KeyEvent event) {
    if (event is KeyDownEvent) {
      setState(() {
        final key = LogicalKeyboardKey.findKeyByKeyId(event.logicalKey.keyId)!;
        if (key == LogicalKeyboardKey.control ||
            key == LogicalKeyboardKey.alt ||
            key == LogicalKeyboardKey.shift) return;

        _newActivator = SingleActivator(
          key,
          control: HardwareKeyboard.instance.isControlPressed,
          shift: HardwareKeyboard.instance.isShiftPressed,
          alt: HardwareKeyboard.instance.isAltPressed,
        );
        debugPrint(
          'New activator: '
          '${_newActivator!.debugDescribeKeys()}'
          '/${_newActivator?.trigger.debugName}',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Keybinding for "${widget.keybinding.name}"'),
      content: KeyboardListener(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: _handleKeypress,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Press the new key combination you want to use.'),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              text: 'Current Keybinding: ',
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: widget.keybinding.value.debugDescribeKeys(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              text: 'New Keybinding: ',
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: _newActivator?.debugDescribeKeys() ?? 'Empty',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_newActivator != null) {
              widget.keybinding.value = _newActivator!;
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

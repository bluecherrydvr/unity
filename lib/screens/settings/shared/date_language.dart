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
import 'package:bluecherry_client/screens/settings/desktop/settings.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LocalizationSettings extends StatelessWidget {
  final ScrollController? controller;

  const LocalizationSettings({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ListView(
      padding: DesktopSettings.verticalPadding,
      controller: controller,
      children: [
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const LanguageSection(),
          ),
        ),
        const SizedBox(height: 12.0),
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Text(loc.dateFormat, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Material(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(8.0),
            ),
            child: const DateFormatSection(),
          ),
        ),
        const SizedBox(height: 12.0),
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Text(loc.timeFormat, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8.0),
        Padding(
          padding: DesktopSettings.horizontalPadding,
          child: Material(
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(8.0),
            ),
            child: const TimeFormatSection(),
          ),
        ),
      ],
    );
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
          onChanged: (value) => settings.locale = value!,
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
      title: 'Date Format',
      description: 'What format to use for displaying dates',
      icon: Icons.calendar_month,
      value: '',
      values: formats.map((format) {
        return Option(
          value: format.pattern,
          text: format.format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
        );
      }),
      onChanged: (v) {
        settings.dateFormat = DateFormat(v!, locale);
      },
    );
  }
}

class TimeFormatSection extends StatelessWidget {
  const TimeFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final locale = Localizations.localeOf(context).toLanguageTag();

    final patterns = ['HH:mm', 'hh:mm a'].map((e) => DateFormat(e, locale));
    final date = DateTime.utc(1969, 7, 20, 14, 18, 04);
    return OptionsChooserTile(
      title: 'Time Format',
      description: 'What format to use for displaying time',
      icon: Icons.hourglass_empty,
      value: '',
      values: patterns.map((pattern) {
        return Option(
          value: pattern.pattern,
          text: pattern.format(date),
        );
      }),
      onChanged: (v) {
        settings.timeFormat = DateFormat(v!, locale);
      },
    );
  }
}

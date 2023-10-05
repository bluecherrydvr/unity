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
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/widgets/settings/desktop/settings.dart';
import 'package:bluecherry_client/widgets/settings/mobile/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:provider/provider.dart';

class LocalizationSettings extends StatelessWidget {
  const LocalizationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return ListView(padding: DesktopSettings.verticalPadding, children: [
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
        title: Text(loc.language, style: theme.textTheme.titleMedium),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name.uppercaseFirst(),
                    maxLines: 1,
                    softWrap: false,
                  ),
                  Text(
                    nativeName.uppercaseFirst(),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

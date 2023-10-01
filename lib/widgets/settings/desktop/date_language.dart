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
        child: Text('Language', style: theme.textTheme.titleMedium),
      ),
      const LanguageSection(),
      const SizedBox(height: 12.0),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.dateFormat, style: theme.textTheme.titleMedium),
      ),
      const DateFormatSection(),
      const SizedBox(height: 12.0),
      Padding(
        padding: DesktopSettings.horizontalPadding,
        child: Text(loc.timeFormat, style: theme.textTheme.titleMedium),
      ),
      const TimeFormatSection(),
    ]);
  }
}

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentLocale = Localizations.localeOf(context);
    const locales = AppLocalizations.supportedLocales;
    final names = LocaleNames.of(context)!;

    return LayoutBuilder(builder: (context, consts) {
      if (consts.maxWidth >= 800) {
        final crossAxisCount = consts.maxWidth >= 870 ? 4 : 3;
        return Wrap(
          children: locales.map((locale) {
            final name =
                names.nameOf(locale.toLanguageTag()) ?? locale.toLanguageTag();
            final nativeName = LocaleNamesLocalizationsDelegate
                    .nativeLocaleNames[locale.toLanguageTag()] ??
                locale.toLanguageTag();
            return SizedBox(
              width: consts.maxWidth / crossAxisCount,
              child: RadioListTile<Locale>(
                value: locale,
                groupValue: currentLocale,
                onChanged: (value) {
                  settings.locale = locale;
                },
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(
                  name,
                  maxLines: 1,
                  softWrap: false,
                ),
                subtitle: Text(
                  nativeName,
                ),
              ),
            );
          }).toList(),
        );
      } else {
        return Column(
          children: locales.map<Widget>((locale) {
            final name =
                names.nameOf(locale.toLanguageTag()) ?? locale.toLanguageTag();
            final nativeName = LocaleNamesLocalizationsDelegate
                    .nativeLocaleNames[locale.toLanguageTag()] ??
                locale.toLanguageTag();
            return RadioListTile<Locale>(
              value: locale,
              groupValue: currentLocale,
              onChanged: (value) {
                settings.locale = locale;
              },
              controlAffinity: ListTileControlAffinity.trailing,
              title: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(name),
              ),
              subtitle: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(nativeName),
              ),
            );
          }).toList(),
        );
      }
    });
  }
}

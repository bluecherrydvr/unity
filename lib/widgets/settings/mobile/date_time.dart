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

part of 'settings.dart';

class DateTimeSection extends StatelessWidget {
  const DateTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(children: [
      // SubHeader('Language'),
      // SliverList(
      //   delegate: SliverChildListDelegate(
      //     AppLocalizations.supportedLocales.map((locale) {
      //       return ListTile(
      //         title: Text(locale.languageCode),
      //       );
      //     }).toList(),
      //   ),
      // ),
      SubHeader(loc.dateFormat),
      const DateFormatSection(),
      SubHeader(loc.timeFormat),
      const TimeFormatSection(),
    ]);
  }
}

class DateFormatSection extends StatelessWidget {
  const DateFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return LayoutBuilder(builder: (context, consts) {
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

      if (consts.maxWidth >= 800) {
        final crossAxisCount = consts.maxWidth >= 870 ? 4 : 3;
        return Wrap(
          children: formats.map((format) {
            return SizedBox(
              width: consts.maxWidth / crossAxisCount,
              child: RadioListTile<String?>(
                value: format.pattern,
                groupValue: settings.dateFormat.pattern,
                onChanged: (value) {
                  settings.dateFormat = format;
                },
                controlAffinity: ListTileControlAffinity.trailing,
                title: AutoSizeText(
                  format.format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                  maxLines: 1,
                  softWrap: false,
                ),
                subtitle: Text(format.pattern ?? ''),
              ),
            );
          }).toList(),
        );
      } else {
        return Column(
          children: formats.map<Widget>((format) {
            return RadioListTile<String?>(
              value: format.pattern,
              groupValue: settings.dateFormat.pattern,
              onChanged: (value) {
                settings.dateFormat = format;
              },
              controlAffinity: ListTileControlAffinity.trailing,
              title: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(
                  format.format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                ),
              ),
              subtitle: Text(format.pattern ?? ''),
            );
          }).toList(),
        );
      }
    });
  }
}

class TimeFormatSection extends StatelessWidget {
  const TimeFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final locale = Localizations.localeOf(context).toLanguageTag();

    return LayoutBuilder(builder: (context, constraints) {
      final patterns = ['HH:mm', 'hh:mm a'].map((e) => DateFormat(e, locale));
      final date = DateTime.utc(1969, 7, 20, 14, 18, 04);
      return Column(
        children: patterns.map<Widget>((format) {
          return ListTile(
            onTap: () => settings.timeFormat = format,
            trailing: Radio<String?>(
              value: format.pattern,
              groupValue: settings.timeFormat.pattern,
              onChanged: (value) => settings.timeFormat = format,
            ),
            title: Text(format.format(date)),
            subtitle: Text(format.pattern ?? ''),
          );
        }).toList(),
      );
    });
  }
}

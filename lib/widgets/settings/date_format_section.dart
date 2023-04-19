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

class DateFormatSection extends StatelessWidget {
  const DateFormatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
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
      ];

      if (consts.maxWidth >= 800) {
        final crossAxisCount = consts.maxWidth >= 870 ? 4 : 3;
        return Wrap(
          children: formats.map((format) {
            return SizedBox(
              width: consts.maxWidth / crossAxisCount,
              child: RadioListTile(
                value: format,
                groupValue: settings.dateFormat.pattern,
                onChanged: (value) {
                  settings.dateFormat = DateFormat(format, 'en_US');
                },
                controlAffinity: ListTileControlAffinity.trailing,
                title: AutoSizeText(
                  DateFormat(format, 'en_US')
                      .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            );
          }).toList(),
        );
      } else {
        return Column(
          children: formats.map((format) {
            return RadioListTile(
              value: format,
              groupValue: settings.dateFormat.pattern,
              onChanged: (value) {
                settings.dateFormat = DateFormat(format, 'en_US');
              },
              controlAffinity: ListTileControlAffinity.trailing,
              title: Padding(
                padding: const EdgeInsetsDirectional.only(start: 8.0),
                child: Text(
                  DateFormat(format, 'en_US')
                      .format(DateTime.utc(1969, 7, 20, 14, 18, 04)),
                ),
              ),
            );
          }).toList(),
        );
      }
    });
  }
}

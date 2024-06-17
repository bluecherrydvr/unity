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

import 'dart:async';

import 'package:bluecherry_client/providers/events_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventsDateTimeFilter extends StatelessWidget {
  final VoidCallback? onSelect;

  const EventsDateTimeFilter({super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventsProvider = context.watch<EventsProvider>();

    return ListTile(
      dense: true,
      isThreeLine: true,
      title: Text(
        loc.period,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4.0),
        child: IntrinsicHeight(
          child: Row(children: [
            Expanded(
              child: _FilterCard(
                title: loc.dateFilter,
                value: () {
                  final formatter = DateFormat.MEd();
                  if (eventsProvider.startDate == null ||
                      eventsProvider.endDate == null) {
                    return loc.mostRecent;
                  } else if (DateUtils.isSameDay(
                    eventsProvider.startDate,
                    eventsProvider.endDate,
                  )) {
                    return formatter.format(eventsProvider.startDate!);
                  } else {
                    return loc.fromToDate(
                      formatter.format(eventsProvider.startDate!),
                      formatter.format(eventsProvider.endDate!),
                    );
                  }
                }(),
                onPressed: () => _openDatePicker(context),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _FilterCard(
                title: loc.timeFilter,
                value: () {
                  final formatter = DateFormat.Hm();
                  if (eventsProvider.startDate == null ||
                      eventsProvider.endDate == null) {
                    return loc.mostRecent;
                  } else if (DateUtils.isSameDay(
                    eventsProvider.startDate,
                    eventsProvider.endDate,
                  )) {
                    return formatter.format(eventsProvider.startDate!);
                  } else {
                    return loc.fromToTime(
                      formatter.format(eventsProvider.startDate!),
                      formatter.format(eventsProvider.endDate!),
                    );
                  }
                }(),
                onPressed: eventsProvider.isDateSet
                    ? () => _openTimePicker(context)
                    : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final eventsProvider = context.read<EventsProvider>();

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDateRange:
          eventsProvider.startDate == null || eventsProvider.endDate == null
              ? null
              : DateTimeRange(
                  start: eventsProvider.startDate!,
                  end: eventsProvider.endDate!,
                ),
    );
    if (range != null) {
      eventsProvider
        ..startDate = range.start
        ..endDate = range.end;
      onSelect?.call();
    }
  }

  Future<void> _openTimePicker(BuildContext context) async {
    final eventsProvider = context.read<EventsProvider>();

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(eventsProvider.startDate ?? DateTime.now()),
    );
    if (time != null) {
      eventsProvider.startDate = DateTime(
        eventsProvider.startDate!.year,
        eventsProvider.startDate!.month,
        eventsProvider.startDate!.day,
        time.hour,
        time.minute,
      );
      onSelect?.call();
    }
  }
}

class _FilterCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onPressed;

  const _FilterCard({
    super.key,
    required this.title,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(4.0),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: onPressed == null
                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                    : null,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: onPressed == null
                    ? theme.colorScheme.onSurface.withOpacity(0.5)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

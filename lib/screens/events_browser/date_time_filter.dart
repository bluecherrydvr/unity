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
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventsDateTimeFilter extends StatefulWidget {
  final VoidCallback? onSelect;

  const EventsDateTimeFilter({super.key, this.onSelect});

  @override
  State<EventsDateTimeFilter> createState() => _EventsDateTimeFilterState();
}

class _EventsDateTimeFilterState extends State<EventsDateTimeFilter> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && DateTime.timestamp().second % 5 == 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final eventsProvider = context.watch<EventsProvider>();

    return ExpansionTile(
      title: Text(
        loc.dateTimeFilter,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(loc.fromToDate(
        eventsProvider.startDate.formatDecoratedDateTime(context),
        eventsProvider.endDate.formatDecoratedDateTime(context),
      )),
      children: [
        _FilterTile(
          title: loc.fromDate,
          date: eventsProvider.startDate,
          isFrom: true,
          onDateChanged: (date) {
            eventsProvider.startDate = date;
            widget.onSelect?.call();
          },
        ),
        _FilterTile(
          title: loc.toDate,
          date: eventsProvider.endDate,
          onDateChanged: (date) {
            eventsProvider.endDate = date;
            widget.onSelect?.call();
          },
        ),
      ],
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String title;

  final DateTime? date;
  final bool isFrom;
  final ValueChanged<DateTime> onDateChanged;

  const _FilterTile({
    required this.onDateChanged,
    required this.date,
    this.isFrom = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return ListTile(
      dense: true,
      isThreeLine: true,
      title: Text(
        title,
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
                  if (date == null) {
                    return loc.mostRecent;
                  } else if (DateUtils.isSameDay(
                    date,
                    DateTimeExtension.now(),
                  )) {
                    return loc.today;
                  } else if (DateUtils.isSameDay(
                    date,
                    DateTimeExtension.now().subtract(const Duration(days: 1)),
                  )) {
                    return loc.yesterday;
                  }

                  final formatter = DateFormat.MEd();
                  return formatter.format(date!);
                }(),
                onPressed: () => _openDatePicker(context),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _FilterCard(
                title: loc.timeFilter,
                value: () {
                  if (date == null) {
                    return loc.mostRecent;
                  }
                  return settings.kTimeFormat.value.format(date!);
                }(),
                onPressed: date != null ? () => _openTimePicker(context) : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final defaultDate =
        isFrom ? DateTimeExtension.today() : DateTimeExtension.now();
    final date = this.date ?? defaultDate;
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: defaultDate,
      initialDate: date,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (selectedDate != null) {
      onDateChanged(date.copyWith(
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
      ));
    }
  }

  Future<void> _openTimePicker(BuildContext context) async {
    assert(date != null);

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(date!),
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );
    if (time != null) {
      onDateChanged(DateTime(
        date!.year,
        date!.month,
        date!.day,
        time.hour,
        time.minute,
      ));
    }
  }
}

class _FilterCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onPressed;

  const _FilterCard({
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

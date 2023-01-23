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

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/events_playback_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:unity_video_player/unity_video_player.dart';

extension DurationExtension on Duration {
  /// Return [Duration] as typical formatted string.
  String get label {
    if (this > const Duration(days: 1)) {
      final days = inDays.toString().padLeft(3, '0');
      final hours = (inHours - (inDays * 24)).toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$days:$hours:$minutes:$seconds';
    } else if (this > const Duration(hours: 1)) {
      final hours = inHours.toString().padLeft(2, '0');
      final minutes = (inMinutes - (inHours * 60)).toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = inMinutes.toString().padLeft(2, '0');
      final seconds = (inSeconds - (inMinutes * 60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }

  String humanReadable(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));

    final finalStrings = <String>[];

    final localizations = AppLocalizations.of(context);

    if (hours.isNotEmpty && hours != '00') {
      finalStrings.add(localizations.hours(hours));
    }

    if (minutes.isNotEmpty && minutes != '00') {
      finalStrings.add(localizations.minutes(minutes));
    }

    if (seconds.isNotEmpty && seconds != '00') {
      finalStrings.add(localizations.seconds(seconds));
    }

    return finalStrings.join(', ');
  }

  String humanReadableCompact(BuildContext context, [bool allowEmpty = false]) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));

    final finalStrings = <String>[];

    final localizations = AppLocalizations.of(context);

    if (hours.isNotEmpty && hours != '00' || allowEmpty) {
      finalStrings.add(localizations.hoursCompact(hours));
    }

    if (minutes.isNotEmpty && minutes != '00' || allowEmpty) {
      finalStrings.add(localizations.minutesCompact(minutes));
    }

    if (seconds.isNotEmpty && seconds != '00' || allowEmpty) {
      finalStrings.add(localizations.secondsCompact(seconds));
    }

    return finalStrings.join();
  }
}

extension NotificationExtensions on NotificationClickAction {
  String str(BuildContext context) => {
        NotificationClickAction.showFullscreenCamera:
            AppLocalizations.of(context).showFullscreenCamera,
        NotificationClickAction.showEventsScreen:
            AppLocalizations.of(context).showEventsScreen,
      }[this]!;
}

extension CameraViewFitExtension on UnityVideoFit {
  String str(BuildContext context) => {
        UnityVideoFit.contain: AppLocalizations.of(context).contain,
        UnityVideoFit.cover: AppLocalizations.of(context).cover,
        UnityVideoFit.fill: AppLocalizations.of(context).fill,
      }[this]!;
}

extension StringExtension on String {
  String uppercaseFirst() {
    if (isEmpty) return this;

    return substring(0, 1).toUpperCase() + substring(1);
  }
}

extension NumberExtension on num {
  /// Ensure this number is positive
  num ensurePositive() {
    if (isNegative) return -this;
    return this;
  }
}

extension ServerExtension on List<Server> {
  Device? findDevice(String id) {
    for (final server in this) {
      if (server.devices.any((d) => EventsProvider.idForDevice(d) == id)) {
        return server.devices
            .firstWhere((d) => EventsProvider.idForDevice(d) == id);
      }
    }

    return null;
  }
}

extension DateTimeExtension on DateTime {
  bool hasForDate(DateTime date) {
    return year == date.year &&
        month == date.month &&
        day == date.day &&
        hour == date.hour &&
        minute == date.minute;
  }

  bool isInBetween(DateTime first, DateTime second) {
    return hasForDate(first) ||
        hasForDate(second) ||
        (isAfter(first) && isBefore(second));
  }
}

extension DateTimeListExtension on Iterable<DateTime> {
  bool hasForDate(DateTime date) {
    return any((pd) => pd.hasForDate(date));
  }

  Iterable<DateTime> forDate(DateTime date) {
    return where((pd) => pd.hasForDate(date));
  }

  Iterable<DateTime> inBetween(DateTime d1, DateTime d2) {
    return where((e) => e.isInBetween(d1, d2));
  }

  DateTime get oldest {
    final copy = [...this]..sort((e1, e2) {
        return e1.compareTo(e2);
      });

    return copy.first;
  }

  DateTime get newest {
    final copy = [...this]..sort((e1, e2) {
        return e1.compareTo(e2);
      });

    return copy.first;
  }
}

extension EventsExtension on Iterable<Event> {
  bool hasForDate(DateTime date) {
    return any((event) {
      final pd = event.published;

      final end = event.mediaDuration == null
          ? event.published.add(event.updated.difference(event.published))
          : event.published.add(event.mediaDuration!);

      return pd.hasForDate(date) ||
          end.hasForDate(date) ||
          date.isInBetween(pd, end);
    });
  }

  Event forDate(DateTime date) {
    return firstWhere((event) {
      final pd = event.published;
      return pd.hasForDate(date);
    });
  }

  Iterable<Event> forDateList(DateTime date) {
    return where((event) {
      final pd = event.published;
      return pd.hasForDate(date);
    });
  }

  Event get oldest {
    final copy = [...this]..sort((e1, e2) {
        return e1.published.compareTo(e2.published);
      });

    return copy.first;
  }

  Event get newest {
    final copy = [...this]..sort((e1, e2) {
        return e1.published.compareTo(e2.published);
      });

    return copy.last;
  }

  Iterable<Event> inBetween(DateTime d1, DateTime d2) {
    return where((e) => e.published.isInBetween(d1, d2));
  }
}

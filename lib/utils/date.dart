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
import 'package:bluecherry_client/utils/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Set<String> _loggedErrorredDates = {};

/// Returns the timezone offset in hours from a date string.
Duration dateTimezoneOffset(String originalDateString) {
  try {
    var offsetSign = 1.0;
    var offsetFactors = originalDateString.split('+');
    if (offsetFactors.isEmpty) {
      offsetFactors = originalDateString.split('-');
      if (offsetFactors.length <= 2) return Duration.zero;
      offsetSign = -1.0;
    }
    final offsetString = offsetFactors.last;
    final parts = offsetString.split(':');

    // Convert hours and minutes strings to integers
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);

    // Create a Duration object based on the offset sign
    final offset = Duration(
      hours: (hours * offsetSign).toInt(),
      minutes: (minutes * offsetSign).toInt(),
    );

    return offset;
  } catch (_) {
    return Duration.zero;
  }
}

/// Convert a date string to a DateTime object, considering the timezone offset.
DateTime timezoneAwareDate(String originalDateString) {
  final originalDateTime = DateTime.parse(originalDateString);
  try {
    return originalDateTime.add(dateTimezoneOffset(originalDateString));
  } catch (e) {
    if (!_loggedErrorredDates.contains(originalDateString)) {
      writeLogToFile(
        'Failed to parse date string: $originalDateString',
        print: true,
      );
      _loggedErrorredDates.add(originalDateString);
    }
    return originalDateTime;
  }
}

extension DateSettingsExtension on SettingsProvider {
  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatDate(DateTime date) {
    if (kConvertTimeToLocalTimezone.value) date = date.toLocal();

    return kDateFormat.value.format(date);
  }

  String formatRawTime(String rawDate) {
    return kTimeFormat.value.format(
      kConvertTimeToLocalTimezone.value
          ? DateTime.parse(rawDate).toLocal()
          : timezoneAwareDate(rawDate),
    );
  }

  /// Formats the date according to the current [dateFormat].
  ///
  /// [toLocal] defines if the date will be converted to local time. Defaults to `true`
  String formatTime(
    DateTime time, {
    DateFormat? pattern,
    bool withSeconds = false,
    bool? toLocal,
  }) {
    if (toLocal ?? kConvertTimeToLocalTimezone()) time = time.toLocal();

    pattern ??= DateFormat(kTimeFormat.value.pattern);

    if (withSeconds) {
      pattern = pattern.add_s();
    }

    return pattern.format(time);
  }

  String formatTimeRaw(
    String rawTime, {
    DateFormat? pattern,
    Duration offset = Duration.zero,
  }) {
    return formatTime(
      timezoneAwareDate(rawTime).add(offset),
      pattern: pattern,
    );
  }

  String formatRawDateAndTime(String rawDateTime) {
    final date = formatDate(DateTime.parse(rawDateTime));
    final time = formatRawTime(rawDateTime).toUpperCase();
    return '$date $time';
  }
}

extension DateTimeExtension on DateTime? {
  /// Returns true if this date is between [first] and [second]
  ///
  /// If [allowSameMoment] is true, then the date can be equal to [first] or
  /// [second].
  bool isInBetween(
    DateTime first,
    DateTime second, {
    bool allowSameMoment = false,
  }) {
    assert(this != null);
    final isBetween = this!.toLocal().isAfter(first.toLocal()) &&
        this!.toLocal().isBefore(second.toLocal());

    if (allowSameMoment) return isBetween;
    return isBetween ||
        this!.isAtSameMomentAs(first) ||
        this!.isAtSameMomentAs(second);
  }

  static DateTime now() {
    if (SettingsProvider.instance.kConvertTimeToLocalTimezone.value) {
      return DateTime.now();
    }

    return DateTime.timestamp();
  }

  static DateTime today() {
    return now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  }

  /// Formats the date string.
  String formatDecoratedDate(BuildContext context, [DateFormat? format]) {
    final loc = AppLocalizations.of(context);
    final settings = context.read<SettingsProvider>();
    format ??= settings.kDateFormat.value;

    var date = this;
    if (settings.kConvertTimeToLocalTimezone.value) date = date?.toLocal();
    var dateString = () {
      if (date == null) {
        return loc.mostRecent;
      } else if (DateUtils.isSameDay(date, DateTime.now())) {
        return loc.today;
      } else if (DateUtils.isSameDay(
        date,
        DateTime.now().subtract(const Duration(days: 1)),
      )) {
        return loc.yesterday;
      } else {
        return format!.format(date);
      }
    }();

    return dateString;
  }

  /// Formats the date and time string.
  String formatDecoratedDateTime(BuildContext context) {
    var dateString = formatDecoratedDate(context);
    if (this == null) return dateString;

    final settings = context.read<SettingsProvider>();
    var date = this;
    if (settings.kConvertTimeToLocalTimezone.value) date = date?.toLocal();

    final timeFormatter = settings.kTimeFormat.value;

    return '$dateString ${timeFormatter.format(date!)}';
  }

  String toIso8601StringWithTimezoneOffset() {
    if (this == null) return '${null}';

    late final DateTime date;
    if (SettingsProvider.instance.kConvertTimeToLocalTimezone.value) {
      date = this!.toLocal();
    } else {
      date = this!;
    }

    final offset = date.timeZoneOffset;
    final isoString = date.toIso8601String();
    if (offset == Duration.zero) return isoString;

    final offsetString = '${offset.isNegative ? '-' : '+'}'
        '${offset.inHours.toString().replaceAll('-', '').replaceAll('+', '').padLeft(2, '0')}:'
        '${offset.inMinutes.remainder(60).toString().padLeft(2, '0')}';

    return '$isoString$offsetString';
  }
}

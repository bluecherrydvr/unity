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
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
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
    return prettyDuration(
      this,
      locale: DurationLocale.fromLanguageCode(
            Localizations.localeOf(context).languageCode,
          ) ??
          const EnglishDurationLocale(),
    );
  }

  String humanReadableCompact(BuildContext context, [bool allowEmpty = false]) {
    return prettyDuration(
      this,
      abbreviated: true,
      locale: DurationLocale.fromLanguageCode(
            Localizations.localeOf(context).languageCode,
          ) ??
          const EnglishDurationLocale(),
    );
  }

  Duration ensurePositive() {
    if (isNegative) return this * -1;

    return this;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}

extension NotificationExtensions on NotificationClickAction {
  String str(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return {
      NotificationClickAction.showFullscreenCamera: loc.showFullscreenCamera,
      NotificationClickAction.showEventsScreen: loc.showEventsScreen,
    }[this]!;
  }
}

extension CameraViewFitExtension on UnityVideoFit {
  String str(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return {
      UnityVideoFit.contain: loc.contain,
      UnityVideoFit.cover: loc.cover,
      UnityVideoFit.fill: loc.fill,
    }[this]!;
  }
}

extension UnityVideoQualityExtension on UnityVideoQuality {
  String str(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return {
          UnityVideoQuality.p1080: loc.p1080,
          UnityVideoQuality.p720: loc.p720,
          UnityVideoQuality.p480: loc.p480,
          UnityVideoQuality.p360: loc.p360,
          UnityVideoQuality.p240: loc.p240,
        }[this] ??
        name;
  }
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
    return (isAfter(first) && isBefore(second)) ||
        this == first ||
        this == second;
  }
}

extension EventsExtension on Iterable<Event> {
  bool hasForDate(DateTime date) {
    return any((event) {
      final start = event.published;

      final end = event.published.add(event.duration);

      return date.isInBetween(start, end);
    });
  }

  Event forDate(DateTime date) {
    return forDateList(date).first;
  }

  Iterable<Event> forDateList(DateTime date) {
    return where((event) {
      final start = event.published;

      final end = event.published.add(event.duration);

      return date.isInBetween(start, end);
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

extension DeviceListExtension on Iterable<Device> {
  /// Returns this device list sorted properly
  List<Device> sorted() {
    return [...this]
      ..sort((a, b) => a.name.compareTo(b.name))
      ..sort((a, b) => a.status ? 0 : 1);
  }
}

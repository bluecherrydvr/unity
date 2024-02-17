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
import 'package:bluecherry_client/models/server.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:unity_video_player/unity_video_player.dart';

export 'package:collection/collection.dart' show IterableExtension;

extension DurationExtension on Duration {
  /// Return [Duration] as typical formatted string.
  ///
  /// 00:00:00
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

  double get inDoubleSeconds {
    return inMilliseconds / 1000;
  }
}

extension CameraViewFitExtension on UnityVideoFit {
  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      UnityVideoFit.contain => loc.contain,
      UnityVideoFit.fill => loc.fill,
      UnityVideoFit.cover => loc.cover,
    };
  }

  IconData get icon {
    return switch (this) {
      UnityVideoFit.contain => Icons.fit_screen,
      UnityVideoFit.fill => Icons.rectangle_rounded,
      UnityVideoFit.cover => Icons.aspect_ratio
    };
  }
}

extension UnityVideoQualityExtension on UnityVideoQuality {
  String locale(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return switch (this) {
      UnityVideoQuality.p4k => loc.p4k,
      UnityVideoQuality.p1080 => loc.p1080,
      UnityVideoQuality.p720 => loc.p720,
      UnityVideoQuality.p480 => loc.p480,
      UnityVideoQuality.p360 => loc.p360,
      UnityVideoQuality.p240 => loc.p240,
    };
  }
}

extension StringExtension on String {
  String get uppercaseFirst {
    if (isEmpty) return this;

    return substring(0, 1).toUpperCase() + substring(1);
  }
}

extension ServerExtension on List<Server> {
  Device? findDevice(String id) {
    for (final server in this) {
      if (server.devices.any((d) => d.uuid == id)) {
        return server.devices.firstWhere((d) => d.uuid == id);
      }
    }

    return null;
  }
}

extension DateTimeExtension on DateTime {
  /// Returns true if this date is between [first] and [second]
  ///
  /// If [allowSameMoment] is true, then the date can be equal to [first] or [second].
  bool isInBetween(
    DateTime first,
    DateTime second, {
    bool allowSameMoment = false,
  }) {
    final isBetween = toLocal().isAfter(first.toLocal()) &&
        toLocal().isBefore(second.toLocal());

    if (allowSameMoment) return isBetween;
    return isBetween ||
        toLocal().isAtSameMomentAs(first.toLocal()) ||
        toLocal().isAtSameMomentAs(second.toLocal());
  }
}

extension DeviceListExtension on Iterable<Device> {
  /// Returns this device list sorted properly
  List<Device> sorted({
    Iterable? available,
    String searchQuery = '',
  }) {
    final list = where((device) =>
        device.name.toLowerCase().contains(searchQuery.toLowerCase())).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (available != null) list.sort((a, b) => available.contains(a) ? 0 : 1);
    list.sort((a, b) => a.status ? 0 : 1);

    return list;
  }
}

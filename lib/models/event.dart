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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// An [Event] received from the [Server] logs.
class Event {
  final Server server;
  final int id;
  final int deviceID;
  final String title;
  final DateTime published;
  final DateTime updated;
  final String? category;
  final int? mediaID;
  final Duration? mediaDuration;
  final Uri? mediaURL;

  const Event(
    this.server,
    this.id,
    this.deviceID,
    this.title,
    this.published,
    this.updated,
    this.category,
    this.mediaID,
    this.mediaDuration,
    this.mediaURL,
  );

  Event.dump({
    Server? server,
    this.id = 1,
    this.deviceID = 1,
    this.title = '',
    DateTime? published,
    DateTime? updated,
    this.category,
    this.mediaID,
    this.mediaDuration,
    this.mediaURL,
  })  : server = server ?? ServersProvider.instance.servers.first,
        published = published ?? DateTime.now(),
        updated = updated ?? DateTime.now();

  String get deviceName {
    return title
        .split('device')
        .last
        .trim()
        .split(' ')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  @override
  bool operator ==(dynamic other) {
    return other is Event &&
        id == other.id &&
        deviceID == other.deviceID &&
        title == other.title &&
        published == other.published &&
        updated == other.updated &&
        category == other.category &&
        mediaID == other.mediaID &&
        mediaDuration == other.mediaDuration &&
        mediaURL == other.mediaURL;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      deviceID.hashCode ^
      title.hashCode ^
      published.hashCode ^
      updated.hashCode ^
      category.hashCode ^
      mediaID.hashCode ^
      mediaDuration.hashCode ^
      mediaURL.hashCode;

  @override
  String toString() =>
      'Event($id, $deviceID, $title, $published, $updated, $category, $mediaID, $mediaDuration, $mediaURL)';

  Event copyWith(
    Server? server,
    int? id,
    int? deviceID,
    String? title,
    DateTime? published,
    DateTime? updated,
    String? category,
    int? mediaID,
    Duration? mediaDuration,
    Uri? mediaURL,
  ) =>
      Event(
        server ?? this.server,
        deviceID ?? this.deviceID,
        id ?? this.id,
        title ?? this.title,
        published ?? this.published,
        updated ?? this.updated,
        category ?? this.category,
        mediaID ?? this.mediaID,
        mediaDuration ?? this.mediaDuration,
        mediaURL ?? this.mediaURL,
      );

  Map<String, dynamic> toJson() => {
        'server': server.toJson(devices: false),
        'deviceID': deviceID,
        'id': id,
        'title': title,
        'published': published.toIso8601String(),
        'updated': updated.toIso8601String(),
        'category': category,
        'mediaID': mediaID,
        'mediaDuration': mediaDuration?.inMicroseconds,
        'mediaURL': mediaURL.toString(),
      };

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      Server.fromJson(json['server']),
      json['deviceID'],
      json['id'],
      json['title'],
      DateTime.parse(json['published']),
      DateTime.parse(json['updated']),
      json['category'],
      json['mediaID'],
      Duration(microseconds: json['mediaDuration']),
      Uri.parse(json['mediaURL']),
    );
  }

  bool get isAlarm => priority == EventPriority.alarm;

  EventPriority get priority {
    final parsedCategory = category?.split('/');
    final priority = parsedCategory?[1] ?? '';

    switch (priority) {
      case 'alarm':
      case 'alrm':
        return EventPriority.alarm;
      case 'warn':
        return EventPriority.warning;
      default:
        return EventPriority.notFound;
    }
  }

  EventType get type {
    final parsedCategory = category?.split('/');

    switch (parsedCategory?.last ?? '') {
      case 'motion':
        return EventType.motion;
      case 'continuous':
        return EventType.continuous;
      default:
        return EventType.notFound;
    }
  }
}

enum EventPriority {
  warning,
  alarm,
  notFound;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case EventPriority.warning:
        return localizations.warn;
      case EventPriority.alarm:
        return localizations.alarm;
      case EventPriority.notFound:
        return localizations.notFound;
    }
  }
}

enum EventType {
  motion,
  continuous,
  notFound;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case EventType.motion:
        return localizations.motion;
      case EventType.continuous:
        return localizations.continuous;
      case EventType.notFound:
        return localizations.notFound;
    }
  }
}

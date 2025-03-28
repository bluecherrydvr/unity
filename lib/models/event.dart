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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/widgets.dart';

/// An [Event] received from the [Server].
class Event {
  final Server server;
  final int id;
  final int deviceID;
  final String title;
  final String publishedRaw;
  final DateTime published;
  final String updatedRaw;
  final DateTime updated;
  final String? category;
  final int? mediaID;
  final Uri? mediaURL;

  const Event({
    required this.server,
    required this.id,
    required this.deviceID,
    required this.title,
    required this.publishedRaw,
    required this.published,
    required this.updatedRaw,
    required this.updated,
    required this.category,
    required this.mediaID,
    required this.mediaURL,
  });

  Event.dump({
    Server? server,
    this.id = 1,
    this.deviceID = 1,
    this.title = '',
    String? publishedRaw,
    DateTime? published,
    String? updatedRaw,
    DateTime? updated,
    this.category,
    this.mediaID,
    this.mediaURL,
  }) : server =
           server ??
           ServersProvider.instance.servers.elementAtOrNull(0) ??
           Server.dump(),
       publishedRaw = publishedRaw ?? DateTimeExtension.now().toIso8601String(),
       published = published ?? DateTimeExtension.now(),
       updatedRaw = updatedRaw ?? DateTimeExtension.now().toIso8601String(),
       updated = updated ?? DateTimeExtension.now();

  String get deviceName {
    return title
        .split('device')
        .last
        .trim()
        .split(' ')
        .map((e) => e.uppercaseFirst)
        .join(' ');
  }

  Duration get duration {
    final dur = updated.difference(published);
    if (dur < Duration.zero) return published.difference(updated);
    return dur;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.server == server &&
        other.id == id &&
        other.deviceID == deviceID &&
        other.title == title &&
        other.publishedRaw == publishedRaw &&
        other.published == published &&
        other.updatedRaw == updatedRaw &&
        other.updated == updated &&
        other.category == category &&
        other.mediaID == mediaID &&
        other.mediaURL == mediaURL;
  }

  @override
  int get hashCode {
    return server.hashCode ^
        id.hashCode ^
        deviceID.hashCode ^
        title.hashCode ^
        publishedRaw.hashCode ^
        published.hashCode ^
        updatedRaw.hashCode ^
        updated.hashCode ^
        category.hashCode ^
        mediaID.hashCode ^
        mediaURL.hashCode;
  }

  @override
  String toString() {
    return 'Event(server: ${server.ip}, id: $id, deviceID: $deviceID, title: $title, publishedRaw: $publishedRaw, published: $published, updatedRaw: $updatedRaw, updated: $updated, category: $category, mediaID: $mediaID, mediaURL: $mediaURL)';
  }

  Map<String, dynamic> toJson() => {
    'server': server.toJson(devices: false),
    'deviceID': deviceID,
    'id': id,
    'title': title,
    'published': published.toIso8601String(),
    'updated': updated.toIso8601String(),
    'category': category,
    'mediaID': mediaID,
    'mediaURL': mediaURL.toString(),
  };

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      server: Server.fromJson(json['server']),
      deviceID: json['deviceID'],
      id: json['id'],
      title: json['title'],
      publishedRaw: json['published'],
      published: DateTime.parse(json['published']),
      updatedRaw: json['updated'],
      updated: DateTime.parse(json['updated']),
      category: json['category'],
      mediaID: json['mediaID'],
      mediaURL: Uri.parse(json['mediaURL']),
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
      case 'critical':
        return EventPriority.critical;
      case 'info':
      default:
        return EventPriority.info;
    }
  }

  EventType get type {
    final parsedCategory = category?.split('/');

    switch (parsedCategory?.last ?? '') {
      case 'motion':
        return EventType.motion;
      case 'continuous':
        return EventType.continuous;
      case 'not found':
        return EventType.notFound;
      case 'video signal loss':
        return EventType.cameraVideoLost;
      case 'audio signal loss':
        return EventType.cameraAudioLost;
      case 'disk-space':
        return EventType.systemDiskSpace;
      case 'crash':
        return EventType.systemCrash;
      case 'boot':
        return EventType.systemBoot;
      case 'shutdown':
        return EventType.systemShutdown;
      case 'reboot':
        return EventType.systemReboot;
      case 'power-outage':
        return EventType.systemPowerOutage;
      default:
        return EventType.unknown;
    }
  }

  String get mediaPath {
    return '${mediaURL!.scheme}://'
        // '${Uri.encodeComponent(server.login)}'
        // ':'
        // '${Uri.encodeComponent(server.password)}'
        // '@'
        '${mediaURL!.host}'
        ':'
        '${mediaURL!.port}'
        '${mediaURL!.path}'
        '?'
        '${mediaURL!.query}';
  }

  Event copyWith({
    Server? server,
    int? id,
    int? deviceID,
    String? title,
    String? publishedRaw,
    DateTime? published,
    String? updatedRaw,
    DateTime? updated,
    String? category,
    int? mediaID,
    Uri? mediaURL,
  }) {
    return Event(
      server: server ?? this.server,
      id: id ?? this.id,
      deviceID: deviceID ?? this.deviceID,
      title: title ?? this.title,
      publishedRaw: publishedRaw ?? this.publishedRaw,
      published: published ?? this.published,
      updatedRaw: updatedRaw ?? this.updatedRaw,
      updated: updated ?? this.updated,
      category: category ?? this.category,
      mediaID: mediaID ?? this.mediaID,
      mediaURL: mediaURL ?? this.mediaURL,
    );
  }
}

enum EventPriority {
  info,
  warning,
  alarm,
  critical;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return switch (this) {
      EventPriority.info => localizations.info,
      EventPriority.warning => localizations.warn,
      EventPriority.alarm => localizations.alarm,
      EventPriority.critical => localizations.critical,
    };
  }
}

enum EventType {
  motion,
  continuous,
  notFound,
  cameraVideoLost,
  cameraAudioLost,
  systemDiskSpace,
  systemCrash,
  systemBoot,
  systemShutdown,
  systemReboot,
  systemPowerOutage,
  unknown;

  String locale(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return switch (this) {
      EventType.motion => localizations.motion,
      EventType.continuous => localizations.continuous,
      EventType.notFound => localizations.notFound,
      EventType.cameraVideoLost => localizations.cameraVideoLost,
      EventType.cameraAudioLost => localizations.cameraAudioLost,
      EventType.systemDiskSpace => localizations.systemDiskSpace,
      EventType.systemCrash => localizations.systemCrash,
      EventType.systemBoot => localizations.systemBoot,
      EventType.systemShutdown => localizations.systemShutdown,
      EventType.systemReboot => localizations.systemReboot,
      EventType.systemPowerOutage => localizations.systemPowerOutage,
      EventType.unknown => localizations.unknown,
    };
  }
}

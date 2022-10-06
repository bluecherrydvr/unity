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

  Event(
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
        'id': id,
        'deviceID': deviceID,
        'title': title,
        'published': published.toIso8601String(),
        'updated': updated.toIso8601String(),
        'category': category,
        'mediaID': mediaID,
        'mediaDuration': mediaDuration?.inMilliseconds,
        'mediaURL': mediaURL.toString(),
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        Server.fromJson(json['server']),
        json['deviceID'],
        json['id'],
        json['title'],
        DateTime.parse(json['published']),
        DateTime.parse(json['updated']),
        json['category'],
        json['mediaID'],
        Duration(milliseconds: json['mediaDuration']),
        Uri.parse(json['mediaURL']),
      );
}

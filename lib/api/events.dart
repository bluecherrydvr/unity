import 'dart:convert';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/api/api_helpers.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:xml2json/xml2json.dart';

extension EventsExtension on API {
  /// Gets the [Event]s present on the [server].
  ///
  /// If server is offline, then it returns an empty list.
  Future<Iterable<Event>> getEvents(
    Server server, {
    DateTime? startTime,
    DateTime? endTime,
    Device? device,
  }) async {
    if (!server.online) {
      debugPrint('Can not get events of an offline server: $server');
      return [];
    }

    assert(
      device == null || server.devices.any((d) => d.id == device.id),
      'The device must be present on the server',
    );

    if (startTime != null && endTime != null) {
      if (startTime == endTime) {
        startTime = startTime.subtract(const Duration(
          hours: 23,
          minutes: 59,
          seconds: 59,
        ));
      }
    }
    final startTimeString = startTime?.toIso8601StringWithTimezoneOffset();
    final endTimeString = endTime?.toIso8601StringWithTimezoneOffset();

    return compute(_getEvents, {
      'server': server,
      'limit': (startTime != null && endTime != null) ? -1 : await eventsLimit,
      'startTime': startTimeString,
      'endTime': endTimeString,
      'device_id': device?.id,
    });
  }

  static Future<Iterable<Event>> _getEvents(Map data) async {
    final server = data['server'] as Server;
    if (!server.online) {
      debugPrint('Can not get events of an offline server: $server');
      return [];
    }

    var startTime = data['startTime'] as String?;
    final endTime = data['endTime'] as String?;
    final deviceId = data['device_id'] as int?;
    final limit = (data['limit'] as int?) ?? -1;

    DevHttpOverrides.configureCertificates();

    debugPrint(
      'Getting events for server ${server.name} with limit $limit '
      '${startTime != null ? 'from $startTime ' : ''}'
      '${endTime != null ? 'to $endTime ' : ''}'
      '${deviceId != null ? 'for device $deviceId' : ''}',
    );

    assert(server.serverUUID != null && server.hasCookies);
    final uri = Uri.https(
      '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
      '/events/',
      {
        'XML': '1',
        'limit': '$limit',
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (deviceId != null) 'device_id': '$deviceId',
      },
    );
    final response =
        await API.client.get(uri, headers: {'Cookie': server.cookie!});

    var events = const Iterable<Event>.empty();

    try {
      if (response.headers['content-type'] == 'application/json') {
        debugPrint('Server returned a JSON response');
        events = ((jsonDecode(response.body) as Map)['entry'] as Iterable)
            .map((item) {
          final eventObject = item as Map;
          final published = DateTime.parse(eventObject['published']);
          final event = Event(
            server: server,
            id: () {
              final idObject = eventObject['id'].toString();

              if (int.tryParse(idObject) != null) {
                return int.parse(idObject);
              }

              final parts = idObject.split('id=');
              if (parts.isEmpty) {
                return -1;
              }

              return int.parse(parts.last);
            }(),
            deviceID: int.parse(
              (eventObject['category']['term'] as String?)?.split('/').first ??
                  '-1',
            ),
            title: eventObject['title'],
            publishedRaw: eventObject['published'],
            published: published,
            updatedRaw: eventObject['updated'] ?? eventObject['published'],
            updated: eventObject['updated'] == null
                ? published
                : DateTime.parse(eventObject['updated']),
            category: eventObject['category']['term'],
            mediaID: eventObject.containsKey('content')
                ? int.parse(eventObject['content']['media_id'])
                : null,
            mediaURL: eventObject.containsKey('content')
                ? Uri.parse(
                    (eventObject['content']['content'] as String).replaceAll(
                      'https://',
                      'https://${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@',
                    ),
                  )
                : null,
          );
          return event;
        });
      } else {
        debugPrint('Server returned a XML response');
        final parser = Xml2Json()..parse(response.body);
        events = (jsonDecode(parser.toGData())['feed']['entry'] as Iterable)
            .map<Event>((item) {
          final e = item as Map;
          if (!e.containsKey('content')) debugPrint(e.toString());
          return Event(
            server: server,
            id: int.parse(e['id']['raw']),
            deviceID:
                int.parse((e['category']['term'] as String).split('/').first),
            title: e['title']['\$t'],
            publishedRaw: e['published']['\$t'],
            published: e['published'] == null || e['published']['\$t'] == null
                ? DateTimeExtension.now()
                : DateTime.parse(e['published']['\$t']),
            updatedRaw: e['updated']['\$t'] ?? e['published']['\$t'],
            updated: e['updated'] == null || e['updated']['\$t'] == null
                ? DateTimeExtension.now()
                : DateTime.parse(e['updated']['\$t']),
            category: e['category']['term'],
            mediaID: !e.containsKey('content')
                ? null
                : int.parse(e['content']['media_id']),
            mediaURL: !e.containsKey('content')
                ? null
                : Uri.parse(
                    e['content'][r'$t'].replaceAll(
                      'https://',
                      'https://${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@',
                    ),
                  ),
          );
        });
      }
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to getEvents on server ${server.name} $uri ${response.body}',
      );
    }

    debugPrint(
      'Loaded ${events.length} events for server ${server.name}'
      '${deviceId != null ? ' for device $deviceId' : ''}',
    );

    return events.where((e) => e.duration > const Duration(seconds: 5));
  }
}

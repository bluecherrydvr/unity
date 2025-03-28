import 'dart:convert';
import 'dart:io';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/api/api_helpers.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/date.dart';
import 'package:bluecherry_client/utils/logging.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:xml2json/xml2json.dart';

extension EventsExtension on API {
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

    if (startTime != null && endTime != null && startTime == endTime) {
      startTime = startTime.subtract(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
    }

    final startTimeString = startTime?.toIso8601StringWithTimezoneOffset();
    final endTimeString = endTime?.toIso8601StringWithTimezoneOffset();
    final settings = SettingsProvider.instance;

    return compute(_getEvents, {
      'server': server,
      'limit': (startTime != null && endTime != null) ? -1 : await eventsLimit,
      'startTime': startTimeString,
      'endTime': endTimeString,
      'device_id': device?.id,
      'allowUntrustedCertificates': settings.kAllowUntrustedCertificates.value,
    });
  }

  static Future<Iterable<Event>> _getEvents(Map data) async {
    final server = data['server'] as Server;
    if (!server.online) return [];

    final startTime = data['startTime'] as String?;
    final endTime = data['endTime'] as String?;
    final deviceId = data['device_id'] as int?;
    final limit = (data['limit'] as int?) ?? -1;

    DevHttpOverrides.configureCertificates(
      allowUntrustedCertificates: data['allowUntrustedCertificates'] as bool,
    );

    writeLogToFile(
      'Getting events for server ${server.name} with limit $limit '
      '${startTime != null ? 'from $startTime ' : ''}'
      '${endTime != null ? 'to $endTime ' : ''}'
      '${deviceId != null ? 'for device $deviceId' : ''}',
      print: true,
    );

    assert(server.serverUUID != null);

    final basicAuth =
        'Basic ${base64Encode(utf8.encode('${server.login}:${server.password}'))}';

    final uri = Uri.https('${server.ip}:${server.port}', '/events/', {
      'XML': '1',
      'limit': '$limit',
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (deviceId != null) 'device_id': '$deviceId',
    });

    final response = await API.client.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: basicAuth,
        if (server.cookie != null) HttpHeaders.cookieHeader: server.cookie!,
      },
    );

    var events = <Event>[];

    try {
      if (response.headers['content-type'] == 'application/json') {
        final json = jsonDecode(response.body) as Map;
        final entries = json['entry'] as Iterable;
        events =
            entries.map<Event>((item) {
              final eventObject = item as Map;
              final published = DateTime.parse(eventObject['published']);
              return Event(
                server: server,
                id: () {
                  final idObject = eventObject['id'].toString();
                  if (int.tryParse(idObject) != null) {
                    return int.parse(idObject);
                  }
                  final parts = idObject.split('id=');
                  return parts.isNotEmpty ? int.parse(parts.last) : -1;
                }(),
                deviceID: int.parse(
                  (eventObject['category']['term'] as String?)
                          ?.split('/')
                          .first ??
                      '-1',
                ),
                title: eventObject['title'],
                publishedRaw: eventObject['published'],
                published: published,
                updatedRaw: eventObject['updated'] ?? eventObject['published'],
                updated:
                    eventObject['updated'] == null
                        ? published
                        : DateTime.parse(eventObject['updated']),
                category: eventObject['category']['term'],
                mediaID:
                    eventObject.containsKey('content')
                        ? int.tryParse(
                          eventObject['content']['media_id'].toString(),
                        )
                        : null,
                mediaURL:
                    eventObject.containsKey('content')
                        ? Uri.tryParse(
                          eventObject['content']['content'] as String,
                        )
                        : null,
              );
            }).toList();
      } else {
        final parser = Xml2Json()..parse(response.body);
        final entries =
            jsonDecode(parser.toGData())['feed']['entry'] as Iterable;
        events =
            entries.map<Event>((item) {
              final e = item as Map;
              return Event(
                server: server,
                id: int.parse(e['id']['raw']),
                deviceID: int.parse(
                  (e['category']['term'] as String).split('/').first,
                ),
                title: e['title']['\$t'],
                publishedRaw: e['published']['\$t'],
                published:
                    e['published'] == null || e['published']['\$t'] == null
                        ? DateTimeExtension.now()
                        : DateTime.parse(e['published']['\$t']),
                updatedRaw: e['updated']['\$t'] ?? e['published']['\$t'],
                updated:
                    e['updated'] == null || e['updated']['\$t'] == null
                        ? DateTimeExtension.now()
                        : DateTime.parse(e['updated']['\$t']),
                category: e['category']['term'],
                mediaID:
                    e.containsKey('content')
                        ? int.tryParse(e['content']['media_id'].toString())
                        : null,
                mediaURL:
                    e.containsKey('content')
                        ? Uri.tryParse(e['content'][r'$t'])
                        : null,
              );
            }).toList();
      }
    } catch (error, stack) {
      handleError(
        error,
        stack,
        'Failed to _getEvents on server ${server.name} $uri ${response.body}',
      );
    }

    writeLogToFile(
      'Loaded ${events.length} events for server ${server.name}'
      '${deviceId != null ? ' for device $deviceId' : ''}',
      print: true,
    );

    return events;
  }
}

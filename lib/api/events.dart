import 'dart:convert';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/api/api_helpers.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

extension EventsExtension on API {
  /// Gets the [Event]s present on the [server].
  ///
  /// If server is offline, then it returns an empty list.
  Future<Iterable<Event>> getEvents(Server server) async {
    if (!server.online) {
      debugPrint('Can not get events of an offline server: $server');
      return [];
    }

    return compute(_getEvents, {'server': server, 'limit': await eventsLimit});
  }

  static Future<Iterable<Event>> _getEvents(Map data) async {
    final server = data['server'] as Server;
    if (!server.online) {
      debugPrint('Can not get events of an offline server: $server');
      return [];
    }

    final limit = data['limit'] as int;

    DevHttpOverrides.configureCertificates();

    assert(server.serverUUID != null && server.cookie != null);
    final response = await http.get(
      Uri.https(
        '${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@${server.ip}:${server.port}',
        '/events/',
        {'XML': '1', 'limit': '$limit'},
      ),
      headers: {'Cookie': server.cookie!},
    );

    var events = const Iterable<Event>.empty();

    try {
      debugPrint('Getting events for server ${server.name}');

      final parser = Xml2Json()..parse(response.body);
      events = (jsonDecode(parser.toGData())['feed']['entry'] as Iterable)
          .cast<Map>()
          .map((e) {
            if (!e.containsKey('content')) debugPrint(e.toString());
            return Event(
              server,
              int.parse(e['id']['raw']),
              int.parse((e['category']['term'] as String).split('/').first),
              e['title']['\$t'],
              e['published'] == null || e['published']['\$t'] == null
                  ? DateTime.now()
                  : DateTime.parse(e['published']['\$t']),
              e['updated'] == null || e['updated']['\$t'] == null
                  ? DateTime.now()
                  : DateTime.parse(e['updated']['\$t']),
              e['category']['term'],
              !e.containsKey('content')
                  ? null
                  : int.parse(e['content']['media_id']),
              !e.containsKey('content')
                  ? null
                  : Uri.parse(
                      e['content'][r'$t'].replaceAll(
                        'https://',
                        'https://${Uri.encodeComponent(server.login)}:${Uri.encodeComponent(server.password)}@',
                      ),
                    ),
            );
          })
          .where((e) => e.duration > const Duration(minutes: 1))
          .cast<Event>();
    } on Xml2JsonException {
      debugPrint('Failed to parse XML response from server ${server.name}');
      debugPrint('Attempting to parse using JSON');

      events = ((jsonDecode(response.body) as Map)['entry'] as Iterable)
          .cast<Map>()
          .map((eventObject) {
        final published = DateTime.parse(eventObject['published']);
        final event = Event.factory(
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
          published: published,
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
    } catch (exception, stacktrace) {
      debugPrint('Failed to getEvents on server ${server.name}');
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }

    debugPrint('Loaded ${events.length} events for server ${server.name}');

    return events;
  }
}

import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event buildEvent({
    Duration? mediaDuration,
    DateTime? published,
    DateTime? updated,
  }) {
    published ??= DateTime(2024, 1, 1, 12, 0, 0);
    updated ??= DateTime(2024, 1, 1, 12, 0, 30);
    return Event.dump(
      server: Server.dump(),
      publishedRaw: published.toIso8601String(),
      published: published,
      updatedRaw: updated.toIso8601String(),
      updated: updated,
      mediaDuration: mediaDuration,
    );
  }

  group('Event.duration', () {
    test('prefers the server-provided media duration', () {
      final event = buildEvent(mediaDuration: const Duration(seconds: 90));

      expect(event.duration, const Duration(seconds: 90));
    });

    test(
      'falls back to updated - published when media duration is missing',
      () {
        final event = buildEvent();

        expect(event.duration, const Duration(seconds: 30));
      },
    );

    test('falls back when the server reports a zero media duration', () {
      // The server reports 0 when the media length is unknown.
      final event = buildEvent(mediaDuration: Duration.zero);

      expect(event.duration, const Duration(seconds: 30));
    });

    test('keeps the absolute difference as fallback', () {
      final event = buildEvent(
        published: DateTime(2024, 1, 1, 12, 0, 30),
        updated: DateTime(2024, 1, 1, 12, 0, 0),
      );

      expect(event.duration, const Duration(seconds: 30));
    });
  });

  group('Event.tryParseMediaDuration', () {
    test('parses integer seconds', () {
      expect(Event.tryParseMediaDuration(90), const Duration(seconds: 90));
    });

    test('parses numeric strings', () {
      expect(Event.tryParseMediaDuration('90'), const Duration(seconds: 90));
    });

    test('returns null for missing values', () {
      expect(Event.tryParseMediaDuration(null), isNull);
    });

    test('returns null for unexpected values', () {
      expect(Event.tryParseMediaDuration('unknown'), isNull);
      expect(Event.tryParseMediaDuration(-5), isNull);
      expect(Event.tryParseMediaDuration(4.5), isNull);
    });
  });

  test('toJson/fromJson round-trips the media duration', () {
    final event = Event.dump(
      server: Server.dump(),
      publishedRaw: '2024-01-01T12:00:00',
      published: DateTime(2024, 1, 1, 12, 0, 0),
      updatedRaw: '2024-01-01T12:00:30',
      updated: DateTime(2024, 1, 1, 12, 0, 30),
      mediaDuration: const Duration(seconds: 90),
      mediaURL: Uri.parse('https://example.com/media?id=1'),
    );

    final restored = Event.fromJson(event.toJson());

    expect(restored.mediaDuration, const Duration(seconds: 90));
    expect(restored.duration, const Duration(seconds: 90));
  });
}

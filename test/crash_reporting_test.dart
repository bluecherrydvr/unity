import 'package:bluecherry_client/utils/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const _leakyUrl =
    'https://manager:fvmDVRAcce55@fvm-bcdvr1.fvm.local:7001/media/request.php?id=1';
const _redactedUrl =
    'https://manager:***@fvm-bcdvr1.fvm.local:7001/media/request.php?id=1';

SentryEvent _eventWithLeak() {
  return SentryEvent(
    message: SentryMessage('Failed to open $_leakyUrl'),
    exceptions: [
      SentryException(type: 'StateError', value: 'Failed $_leakyUrl'),
    ],
    breadcrumbs: [Breadcrumb(message: 'Playing $_leakyUrl')],
    request: SentryRequest(url: _leakyUrl),
  );
}

void main() {
  group('scrubSentryEvent', () {
    test('redacts credentials from message, exceptions, breadcrumbs', () {
      final scrubbed = scrubSentryEvent(_eventWithLeak(), Hint());

      expect(scrubbed, isNotNull);
      expect(scrubbed!.message!.formatted, contains(_redactedUrl));
      expect(scrubbed.message!.formatted, isNot(contains('fvmDVRAcce55')));
      expect(scrubbed.exceptions!.single.value, contains(_redactedUrl));
      expect(scrubbed.breadcrumbs!.single.message, contains(_redactedUrl));
      expect(scrubbed.request!.url, _redactedUrl);
    });

    test('redacts credentials inside breadcrumb data', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(
            message: 'http request',
            data: {'url': _leakyUrl, 'status_code': 200},
          ),
        ],
      );
      final scrubbed = scrubSentryEvent(event, Hint());

      expect(scrubbed!.breadcrumbs!.single.data!['url'], _redactedUrl);
      expect(scrubbed.breadcrumbs!.single.data!['status_code'], 200);
    });

    test('leaves credential-less events untouched', () {
      final scrubbed = scrubSentryEvent(
        SentryEvent(message: SentryMessage('plain failure')),
        Hint(),
      );

      expect(scrubbed!.message!.formatted, 'plain failure');
      expect(scrubbed.exceptions, isNull);
      expect(scrubbed.breadcrumbs, isNull);
    });
  });
}

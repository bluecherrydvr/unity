import 'package:bluecherry_client/utils/crash_reporting.dart';
import 'package:flutter/services.dart';
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

/// In-memory backing store for the flutter_secure_storage mock below.
final _secureStorage = <String, String?>{};

/// When true, the secure-storage mock throws, simulating broken storage.
bool _failSecureStorage = false;

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // The event budget persists through flutter_secure_storage. Back it with
    // an in-memory map so save/restore can be tested without a device.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            if (_failSecureStorage) {
              throw PlatformException(code: 'unavailable');
            }
            final args = (call.arguments as Map?)?.cast<String, Object?>();
            switch (call.method) {
              case 'read':
                return _secureStorage[args?['key'] as String?];
              case 'write':
                _secureStorage[args?['key'] as String] =
                    args?['value'] as String?;
              case 'delete':
                _secureStorage.remove(args?['key'] as String?);
              case 'deleteAll':
                _secureStorage.clear();
            }
            return null;
          },
        );
  });

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

  group('beforeSendSentryEvent', () {
    setUp(resetSentryEventBudget);

    test('passes events while in budget', () {
      final event = beforeSendSentryEvent(
        SentryEvent(message: SentryMessage('plain failure')),
        Hint(),
      );

      expect(event, isNotNull);
      expect(event!.message!.formatted, 'plain failure');
    });

    test('drops events once the hourly budget is exhausted', () {
      SentryEvent? last;
      for (var i = 0; i <= kMaxSentryEventsPerHour; i++) {
        last = beforeSendSentryEvent(
          SentryEvent(message: SentryMessage('loop failure $i')),
          Hint(),
        );
      }

      expect(last, isNull);
    });

    test('still scrubs events that pass the budget', () {
      final event = beforeSendSentryEvent(_eventWithLeak(), Hint());

      expect(event, isNotNull);
      expect(event!.message!.formatted, contains(_redactedUrl));
      expect(event.message!.formatted, isNot(contains('fvmDVRAcce55')));
    });
  });

  group('event budget persistence', () {
    setUp(() {
      resetSentryEventBudget();
      _secureStorage.clear();
    });

    void seedBudget({required int windowStartMillis, required int count}) {
      _secureStorage[sentryBudgetWindowStartKey] = '$windowStartMillis';
      _secureStorage[sentryBudgetCountKey] = '$count';
    }

    SentryEvent? passEvent() => beforeSendSentryEvent(
      SentryEvent(message: SentryMessage('probe')),
      Hint(),
    );

    test('starts with a full budget when nothing was persisted', () async {
      await restoreSentryEventBudget();

      expect(passEvent(), isNotNull);
    });

    test('restores an exhausted budget across a restart', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      seedBudget(windowStartMillis: now, count: kMaxSentryEventsPerHour);

      await restoreSentryEventBudget();

      expect(passEvent(), isNull);
    });

    test('restarts the budget when the persisted window expired', () async {
      final twoHoursAgo =
          DateTime.now().millisecondsSinceEpoch - 2 * 60 * 60 * 1000;
      seedBudget(
        windowStartMillis: twoHoursAgo,
        count: kMaxSentryEventsPerHour,
      );

      await restoreSentryEventBudget();

      expect(passEvent(), isNotNull);
    });

    test('persists increments so a restart keeps the budget', () async {
      for (var i = 0; i < kMaxSentryEventsPerHour; i++) {
        expect(passEvent(), isNotNull);
      }
      // Let the fire-and-forget writes land, then simulate a restart: a
      // fresh process has empty memory but intact storage.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      resetSentryEventBudget();
      await restoreSentryEventBudget();

      expect(passEvent(), isNull);
    });
  });

  group('install ID', () {
    setUp(() {
      _secureStorage.clear();
      _failSecureStorage = false;
    });

    test('generates and persists a stable ID', () async {
      final first = await loadSentryInstallId();
      final second = await loadSentryInstallId();

      expect(first, matches(_uuidV4Pattern));
      expect(second, first);
      expect(_secureStorage[sentryInstallIdKey], first);
    });

    test('falls back to a session-stable ID when storage fails', () async {
      _failSecureStorage = true;

      final first = await loadSentryInstallId();
      final second = await loadSentryInstallId();

      expect(first, matches(_uuidV4Pattern));
      expect(second, first);
    });
  });

  group('server context', () {
    test('fingerprints are stable, short, and opaque', () {
      final fingerprint = sentryServerFingerprint('192.168.1.5:7001');

      expect(fingerprint, hasLength(16));
      expect(fingerprint, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(sentryServerFingerprint('192.168.1.5:7001'), fingerprint);
      expect(fingerprint, isNot(contains('192.168')));
      expect(sentryServerFingerprint('10.0.0.2:7001'), isNot(fingerprint));
    });

    test('applies count tag and fingerprint context to a scope', () {
      final scope = Scope(SentryOptions());
      applySentryServerContext(
        scope,
        serverCount: 2,
        serverFingerprints: const ['aaaabbbbccccdddd', 'eeeeffffgggghhhh'],
      );

      expect(scope.tags['server_count'], '2');
      final servers = scope.contexts['servers'] as Map;
      expect(servers['count'], 2);
      expect(servers['fingerprints'], ['aaaabbbbccccdddd', 'eeeeffffgggghhhh']);
    });

    test('update is a no-op when Sentry is not initialized', () {
      // Sentry is never initialized in tests; this must not throw.
      updateSentryServerContext(
        serverCount: 1,
        serverFingerprints: const ['aaaabbbbccccdddd'],
      );
    });
  });
}

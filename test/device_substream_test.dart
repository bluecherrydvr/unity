import 'package:bluecherry_client/models/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Device.buildRtspUrl', () {
    test('builds the standard live URL without rendition', () {
      expect(
        Device.buildRtspUrl(
          login: 'manager',
          password: 's3cret',
          host: '192.168.1.10',
          port: 7002,
          deviceId: 1,
        ),
        'rtsp://manager:s3cret@192.168.1.10:7002/live/1',
      );
    });

    test('appends the sub rendition suffix', () {
      expect(
        Device.buildRtspUrl(
          login: 'manager',
          password: 's3cret',
          host: '192.168.1.10',
          port: 7002,
          deviceId: 1,
          rendition: 'sub',
        ),
        'rtsp://manager:s3cret@192.168.1.10:7002/live/1/sub',
      );
    });

    test('appends the main rendition suffix', () {
      expect(
        Device.buildRtspUrl(
          login: 'manager',
          password: 's3cret',
          host: '192.168.1.10',
          port: 7002,
          deviceId: 1,
          rendition: 'main',
        ),
        'rtsp://manager:s3cret@192.168.1.10:7002/live/1/main',
      );
    });

    test('percent-encodes credentials', () {
      expect(
        Device.buildRtspUrl(
          login: 'user@domain',
          password: 'p@ss:word',
          host: 'host',
          port: 7002,
          deviceId: 2,
        ),
        'rtsp://user%40domain:p%40ss%3Aword@host:7002/live/2',
      );
    });
  });

  group('Device.parseSubstreamEnabled', () {
    test('accepts server string flags', () {
      expect(Device.parseSubstreamEnabled('1'), isTrue);
      expect(Device.parseSubstreamEnabled('0'), isFalse);
    });

    test('accepts numbers and booleans', () {
      expect(Device.parseSubstreamEnabled(1), isTrue);
      expect(Device.parseSubstreamEnabled(0), isFalse);
      expect(Device.parseSubstreamEnabled(true), isTrue);
      expect(Device.parseSubstreamEnabled(false), isFalse);
    });

    test('rejects missing and unknown values', () {
      expect(Device.parseSubstreamEnabled(null), isFalse);
      expect(Device.parseSubstreamEnabled(''), isFalse);
      expect(Device.parseSubstreamEnabled('off'), isFalse);
    });
  });
}

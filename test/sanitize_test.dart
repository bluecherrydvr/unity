import 'package:bluecherry_client/utils/sanitize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeSensitiveData', () {
    test('redacts password but keeps user and host', () {
      expect(
        sanitizeSensitiveData(
          'Failed to open https://manager:fvmDVRAcce55@fvm-bcdvr1.fvm.local:7001/media/request.php?id=19420673',
        ),
        'Failed to open https://manager:***@fvm-bcdvr1.fvm.local:7001/media/request.php?id=19420673',
      );
    });

    test('redacts bare user without password', () {
      expect(
        sanitizeSensitiveData('Failed to open https://manager@host/media'),
        'Failed to open https://***@host/media',
      );
    });

    test('redacts percent-encoded credentials', () {
      expect(
        sanitizeSensitiveData('https://user:p%40ss%3Aw0rd@host:7001/media'),
        'https://user:***@host:7001/media',
      );
    });

    test('redacts every URL in the message', () {
      expect(
        sanitizeSensitiveData('a https://u1:p1@h1/x then rtsp://u2:p2@h2/y'),
        'a https://u1:***@h1/x then rtsp://u2:***@h2/y',
      );
    });

    test('leaves credential-less text untouched', () {
      const text = 'Failed to open https://host:7001/media/request.php?id=1';
      expect(sanitizeSensitiveData(text), text);
      expect(
        sanitizeSensitiveData('plain error without url'),
        'plain error without url',
      );
    });

    test('redacts session tokens in query parameters', () {
      expect(
        sanitizeSensitiveData(
          'https://host:7001/hls/1/0/playlist.m3u8?authtoken=abc123',
        ),
        'https://host:7001/hls/1/0/playlist.m3u8?authtoken=***',
      );
      expect(
        sanitizeSensitiveData('Failed ?token=abc123&other=1'),
        'Failed ?token=***&other=1',
      );
      expect(sanitizeSensitiveData('x?AUTHTOKEN=abc123'), 'x?AUTHTOKEN=***');
    });

    test('leaves similar parameter names untouched', () {
      expect(
        sanitizeSensitiveData('media/hls?tokenOnly=true&id=1'),
        'media/hls?tokenOnly=true&id=1',
      );
      expect(
        sanitizeSensitiveData('https://host/path?user=a@b'),
        'https://host/path?user=a@b',
      );
    });
  });

  group('stripUrlCredentials', () {
    test('removes user info while keeping path and query', () {
      final uri = Uri.parse(
        'https://manager:fvmDVRAcce55@fvm-bcdvr1.fvm.local:7001/media/request.php?id=19420673',
      );
      expect(
        stripUrlCredentials(uri).toString(),
        'https://fvm-bcdvr1.fvm.local:7001/media/request.php?id=19420673',
      );
      expect(stripUrlCredentials(uri).userInfo, isEmpty);
    });

    test('leaves URIs without credentials untouched', () {
      final uri = Uri.parse('https://host:7001/media/request.php?id=1');
      expect(stripUrlCredentials(uri), uri);
    });

    test('leaves non-authority URIs untouched', () {
      final uri = Uri.parse('file:///tmp/event.mp4');
      expect(stripUrlCredentials(uri).toString(), 'file:///tmp/event.mp4');
    });
  });
}

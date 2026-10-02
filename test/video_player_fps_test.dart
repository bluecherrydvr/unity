import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:unity_video_player_flutter/unity_video_player_flutter.dart';

// Minimal stand-ins for fvp's MediaInfo/VideoStreamInfo/VideoCodecParameters,
// which aren't exported from fvp's public API. The fps parsing only relies on
// the dynamic shape: `mediaInfo.video[].codec.frameRate`.
class _FakeCodec {
  _FakeCodec(this.frameRate);
  final Object? frameRate;
}

class _FakeStream {
  _FakeStream(this.codec);
  final _FakeCodec? codec;
}

class _FakeMediaInfo {
  _FakeMediaInfo(this.video);
  final List<_FakeStream>? video;
}

void main() {
  group('UnityVideoPlayerFlutter.fpsFromMediaInfo', () {
    test('returns the first video stream frame rate', () {
      // Sentry FLUTTER-6: a single-element video list used to throw
      // NoSuchMethodError via a dynamic `firstOrNull` call.
      final info = _FakeMediaInfo([_FakeStream(_FakeCodec(29.97))]);

      expect(UnityVideoPlayerFlutter.fpsFromMediaInfo(info), 29.97);
    });

    test('returns the first stream rate when several exist', () {
      final info = _FakeMediaInfo([
        _FakeStream(_FakeCodec(60.0)),
        _FakeStream(_FakeCodec(30.0)),
      ]);

      expect(UnityVideoPlayerFlutter.fpsFromMediaInfo(info), 60.0);
    });

    test('coerces integer frame rates to double', () {
      final info = _FakeMediaInfo([_FakeStream(_FakeCodec(30))]);

      expect(UnityVideoPlayerFlutter.fpsFromMediaInfo(info), 30.0);
    });

    test('returns 0.0 when no frame rate is available', () {
      expect(UnityVideoPlayerFlutter.fpsFromMediaInfo(null), 0.0);
      expect(
        UnityVideoPlayerFlutter.fpsFromMediaInfo(_FakeMediaInfo(null)),
        0.0,
      );
      expect(UnityVideoPlayerFlutter.fpsFromMediaInfo(_FakeMediaInfo([])), 0.0);
      expect(
        UnityVideoPlayerFlutter.fpsFromMediaInfo(
          _FakeMediaInfo([_FakeStream(null)]),
        ),
        0.0,
      );
      expect(
        UnityVideoPlayerFlutter.fpsFromMediaInfo(
          _FakeMediaInfo([_FakeStream(_FakeCodec(null))]),
        ),
        0.0,
      );
    });
  });
}

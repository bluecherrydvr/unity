import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/layouts_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:unity_video_player/unity_video_player.dart';

/// Player backend stub. Settings read its capabilities at startup; playback
/// itself is never exercised here.
class _FakeVideoPlayerInterface
    with MockPlatformInterfaceMixin
    implements UnityVideoPlayerInterface {
  @override
  Future<void> initialize([dynamic arguments]) async {}

  @override
  UnityVideoPlayer createPlayer({
    int? width,
    int? height,
    bool enableCache = false,
    RTSPProtocol? rtspProtocol,
  }) => throw UnimplementedError();

  @override
  Widget createVideoView({
    Key? key,
    required UnityVideoPlayer player,
    UnityVideoFit fit = UnityVideoFit.contain,
    UnityVideoPaneBuilder? paneBuilder,
    UnityVideoBuilder? videoBuilder,
    Color color = const Color(0xFF000000),
  }) => throw UnimplementedError();

  @override
  bool get supportsFPS => false;

  @override
  bool get supportsHardwareZoom => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // LayoutsProvider.save persists through flutter_secure_storage. Sink the
    // reads and writes so reorder can be tested without a device.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
    // Devices read their default volume from the settings, and the settings
    // read the player capabilities at startup.
    UnityVideoPlayerInterface.instance = _FakeVideoPlayerInterface();
    await SettingsProvider.ensureInitialized();
  });

  LayoutsProvider setupView() {
    final view = LayoutsProvider.instance;
    view.layouts = [
      Layout.raw(
        name: 'test',
        devices: List.generate(
          6,
          (i) => Device.dump(id: i, name: 'd$i', matrixType: MatrixType.t16),
        ),
        type: DesktopLayoutType.multipleView,
      ),
    ];
    view.lockedLayouts.clear();
    return view;
  }

  List<int> ids(LayoutsProvider view) =>
      view.currentLayout.devices.map((d) => d.id).toList();

  group('LayoutsProvider.reorder', () {
    test('moves the device', () async {
      final view = setupView();

      await view.reorder(0, 2);

      expect(ids(view), [1, 2, 0, 3, 4, 5]);
    });

    test('drop past the end moves to the last position', () async {
      // https://github.com/bluecherrydvr/unity/issues/367
      final view = setupView();

      await view.reorder(0, 7);

      expect(ids(view), [1, 2, 3, 4, 5, 0]);
    });

    test('negative end index is ignored', () async {
      final view = setupView();

      await view.reorder(2, -1);

      expect(ids(view), [0, 1, 2, 3, 4, 5]);
    });

    test('out-of-range initial index is ignored', () async {
      final view = setupView();

      await view.reorder(9, 1);
      await view.reorder(-1, 1);

      expect(ids(view), [0, 1, 2, 3, 4, 5]);
    });

    test('same index is a no-op', () async {
      final view = setupView();

      await view.reorder(2, 2);

      expect(ids(view), [0, 1, 2, 3, 4, 5]);
    });

    test('locked layout is a no-op', () async {
      final view = setupView();
      view.lockedLayouts.add(view.currentLayout);

      await view.reorder(0, 2);

      expect(ids(view), [0, 1, 2, 3, 4, 5]);
    });
  });
}

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/theme.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';

class SingleCameraWindow extends StatelessWidget {
  final Device device;
  final ThemeMode mode;

  const SingleCameraWindow({
    Key? key,
    required this.device,
    required this.mode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider.value(value: DesktopViewProvider.instance),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [NObserver()],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        themeMode: mode,
        theme: createTheme(themeMode: ThemeMode.light),
        darkTheme: createTheme(themeMode: ThemeMode.dark),
        home: CameraView(device: device),
      ),
    );
  }
}

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.device,
  }) : super(key: key);

  final Device device;

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late UnityVideoPlayer controller;

  @override
  void initState() {
    super.initState();
    controller = UnityVideoPlayer.create();

    controller
      ..setDataSource(widget.device.streamURL)
      ..setVolume(0.0)
      ..setSpeed(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(children: [
        // WindowButtons(title: widget.device.fullName, showNavigator: false),
        Expanded(
          child: UnityVideoView(
            player: controller,
            color: Colors.grey.shade900,
            paneBuilder: (context, controller) {
              return DesktopTileViewport(
                controller: controller,
                device: widget.device,
                isSubView: true,
              );
            },
          ),
        ),
      ]),
    );
  }
}

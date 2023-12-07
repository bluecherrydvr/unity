/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:ui';

import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/event.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/events/events_screen.dart';
import 'package:bluecherry_client/widgets/events_timeline/events_playback.dart';
import 'package:bluecherry_client/widgets/home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:unity_video_player/unity_video_player.dart';
import 'package:window_manager/window_manager.dart';

final navigationStream = StreamController.broadcast();

class NObserver extends NavigatorObserver {
  void update(Route? route) {
    if (route == null) return;

    // do not update if it's a popup
    if (route is PopupRoute) return;
    if (route is DialogRoute) return;

    navigationStream.add(route.settings.arguments);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    update(previousRoute ?? route);
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    update(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    update(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    update(newRoute ?? oldRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({
    super.key,
    this.title,
    this.showNavigator = true,
    this.onBack,
  });

  /// The current window title.
  ///
  /// If not provided, the title if fetched from the data of the current
  /// route
  final String? title;

  /// Whether the navigator will be show.
  ///
  /// Usually disabled on sub windows.
  ///
  /// Defaults to true.
  final bool showNavigator;

  /// Called when the back button is pressed.
  final Future<void> Function()? onBack;

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener {
  @override
  void initState() {
    super.initState();

    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _init() async {
    if (isDesktopPlatform) {
      // Add this line to override the default close handler
      await windowManager.setPreventClose(true);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop || isMobile) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    final navData = NavigatorData.of(context);

    final isMacOSPlatform =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

    return StreamBuilder(
      stream: navigationStream.stream,
      builder: (context, arguments) {
        final canPop = navigatorKey.currentState?.canPop() ?? false;

        return Material(
          child: Stack(children: [
            DragToMoveArea(
              child: Row(children: [
                if (isMacOSPlatform) const SizedBox(width: 70.0, height: 40.0),
                if (canPop)
                  InkWell(
                    onTap: () async {
                      await widget.onBack?.call();
                      await navigatorKey.currentState?.maybePop();
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      height: 40.0,
                      width: 40.0,
                      alignment: AlignmentDirectional.center,
                      child: Icon(
                        Icons.arrow_back,
                        size: 20.0,
                        color: theme.hintColor,
                      ),
                    ),
                  )
                else if (!isMacOSPlatform)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8.0),
                    child: Image.asset(
                      'assets/images/icon.png',
                      height: 16.0,
                      width: 16.0,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 10.0),
                    child: Text(
                      () {
                        if (widget.title != null) return widget.title!;

                        if (arguments.data != null) {
                          if (arguments.data is Event) {
                            final event = arguments.data as Event;
                            return event.deviceName;
                          }

                          if (arguments.data is Device) {
                            final device = arguments.data as Device;
                            return device.fullName;
                          }
                        }

                        // If it is in another screen, show the title or fallback to "Bluecherry"
                        if (tab.index >= UnityTab.values.length) {
                          return widget.title ?? 'Bluecherry';
                        }

                        if (!isMacOSPlatform) {
                          return navData.firstWhere((d) => d.tab == tab).text;
                        }

                        return '';
                      }(),
                      style: TextStyle(
                        color: theme.brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (home.isLoading)
                  const Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                    child: UnityLoadingIndicator(),
                  )
                else if (home.tab == UnityTab.eventsScreen ||
                    home.tab == UnityTab.eventsPlayback && !canPop)
                  SquaredIconButton(
                    onPressed: () {
                      eventsScreenKey.currentState?.fetch();
                      eventsPlaybackScreenKey.currentState?.fetch();
                    },
                    icon: const Icon(Icons.refresh, size: 20.0),
                    tooltip: loc.refresh,
                  ),
                // Do not render the Window Buttons on web nor macOS. macOS render the buttons natively.
                if (!kIsWeb && !isMacOSPlatform)
                  SizedBox(
                    width: 138,
                    height: 40,
                    child: WindowCaption(
                      brightness: theme.brightness,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ]),
            ),
            if (!canPop && widget.showNavigator)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4.0),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ...navData.map((data) {
                    final isSelected = tab == data.tab;
                    final icon = isSelected ? data.selectedIcon : data.icon;
                    final text = data.text;

                    return SquaredIconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          icon,
                          key: ValueKey(isSelected),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.hintColor,
                          fill: isSelected ? 1.0 : 0.0,
                          size: 22.0,
                        ),
                      ),
                      tooltip: text,
                      onPressed: () => home.setTab(data.tab, context),
                    );
                  }),
                ]),
              ),
          ]),
        );
      },
    );
  }

  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    // We ensure all the players are disposed in order to not keep the app alive
    // in background, wasting unecessary resources!
    if (isPreventClose) {
      windowManager.hide();
      await Future.microtask(() async {
        for (final player in UnityVideoPlayerInterface.players.toList()) {
          debugPrint('Disposing player ${player.hashCode}');
          await player.dispose();
        }
      });
      windowManager.destroy();
    }
  }
}

/// A widget that shows whether something in the app is loading
class UnityLoadingIndicator extends StatefulWidget {
  const UnityLoadingIndicator({super.key});

  @override
  State<UnityLoadingIndicator> createState() => _UnityLoadingIndicatorState();
}

class _UnityLoadingIndicatorState extends State<UnityLoadingIndicator> {
  OverlayEntry? _overlayEntry;
  void showCurrentTasks() {
    final overlay = Overlay.of(context);

    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(builder: (context) {
      return LayoutBuilder(builder: (context, constraints) {
        final willFitY = constraints.maxHeight - (pos.dy + box.size.height) >
            CurrentTasks.width;

        return Stack(children: [
          Positioned(
            top: willFitY ? pos.dy + box.size.height : null,
            bottom: willFitY ? null : constraints.maxHeight - pos.dy + 1.0,
            left: clampDouble(
              pos.dx - (CurrentTasks.width / 2),
              0,
              constraints.maxWidth,
            ),
            child: const CurrentTasks(),
          ),
        ]);
      });
    });

    overlay.insert(_overlayEntry!);
  }

  void dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool _openedWithTap = false;

  @override
  void dispose() {
    dismissOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasOverlay(context));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) {
        if (d.kind == PointerDeviceKind.touch) {
          if (_overlayEntry != null) {
            dismissOverlay();
            _openedWithTap = false;
          } else {
            showCurrentTasks();
            _openedWithTap = true;
          }
        }
      },
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.opaque,
        onHover: (_) {
          if (_overlayEntry != null) return;
          showCurrentTasks();
          _openedWithTap = false;
        },
        onExit: (_) {
          if (!_openedWithTap) dismissOverlay();
        },
        child: const SizedBox(
          height: 20.0,
          width: 20.0,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
    );
  }
}

class CurrentTasks extends StatelessWidget {
  const CurrentTasks({super.key});

  static const width = 250.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final home = context.watch<HomeProvider>();

    return Card(
      child: Container(
        width: width,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12.0,
          vertical: 10.0,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                loc.currentTasks,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              '${home.loadReasons.length}',
              style: theme.textTheme.labelSmall,
            ),
          ]),
          if (home.loadReasons.isEmpty)
            Text(loc.noCurrentTasks, style: theme.textTheme.labelSmall)
          else
            ...home.loadReasons.map((reason) {
              return Text(
                reason.locale(context),
                style: theme.textTheme.bodyMedium,
              );
            }),
        ]),
      ),
    );
  }
}

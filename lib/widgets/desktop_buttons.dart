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
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/providers/update_provider.dart';
import 'package:bluecherry_client/screens/events_browser/events_screen.dart';
import 'package:bluecherry_client/screens/events_timeline/events_playback.dart';
import 'package:bluecherry_client/screens/home.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:titlebar_buttons/titlebar_buttons.dart';
import 'package:window_manager/window_manager.dart';

final navigationStream = StreamController.broadcast();

final navigatorObserver = NObserver();

class NObserver extends NavigatorObserver {
  bool poppableRoute = false;

  void update(Route? route) {
    if (route == null || route is DialogRoute || route is PopupRoute) {
      poppableRoute = false;
      return;
    }

    poppableRoute = true;

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
    this.flexible,
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

  /// The widget displayed in the remaining space.
  final Widget? flexible;

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons>
    with SingleTickerProviderStateMixin {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktop || isMobile) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final settings = context.watch<SettingsProvider>();
    final home = context.watch<HomeProvider>();
    final tab = home.tab;

    final navData = NavigatorData.of(context);

    final isMacOSPlatform =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final isWindowsPlatform =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final isLinuxPlatform =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    final centerTitle =
        (AppBarTheme.of(context).centerTitle ?? false) && !widget.showNavigator;

    final bar = StreamBuilder(
      stream: navigationStream.stream,
      builder: (context, arguments) {
        final canPop = (navigatorKey.currentState?.canPop() ?? false) &&
            navigatorObserver.poppableRoute;
        final showNavigator = !canPop && widget.showNavigator;

        final titleWidget = Text(
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

            if (!(isMacOSPlatform || kIsWeb)) {
              return navData
                  .firstWhere((d) => d.tab == tab, orElse: () => navData.first)
                  .text;
            }

            return '';
          }(),
          style: TextStyle(
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: 12.0,
          ),
          textAlign: centerTitle ? TextAlign.center : null,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

        return Material(
          child: SizedBox(
            height: 40.0,
            child: Stack(children: [
              if (centerTitle) Center(child: titleWidget),
              DragToMoveArea(
                child: Row(children: [
                  if (isMacOSPlatform)
                    const SizedBox(width: 70.0, height: 40.0),
                  if (canPop)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: SquaredIconButton(
                        onPressed: () async {
                          await widget.onBack?.call();
                          await navigatorKey.currentState?.maybePop();
                        },
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        icon: Container(
                          padding: const EdgeInsetsDirectional.all(4.0),
                          // height: 40.0,
                          // width: 40.0,
                          alignment: AlignmentDirectional.center,
                          child: Icon(
                            Icons.adaptive.arrow_back,
                            size: 20.0,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    )
                  else if (isWindowsPlatform)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8.0),
                      child: Image.asset(
                        'assets/images/icon.png',
                        height: 16.0,
                        width: 16.0,
                      ),
                    ),
                  if (centerTitle)
                    const Spacer()
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 10.0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: titleWidget,
                        ),
                      ),
                    ),
                  if (home.isLoading)
                    const Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 8.0),
                      child: UnityLoadingIndicator(),
                    )
                  else if (home.tab == UnityTab.eventsHistory ||
                      home.tab == UnityTab.eventsTimeline && !canPop)
                    SquaredIconButton(
                      onPressed: () {
                        eventsScreenKey.currentState?.fetch();
                        eventsPlaybackScreenKey.currentState?.fetch();
                      },
                      icon: const Icon(Icons.refresh, size: 20.0),
                      tooltip: loc.refresh,
                    ),
                  if (widget.flexible != null) widget.flexible!,

                  // Do not render the Window Buttons on web nor macOS nor when
                  // in fullscreen. macOS render the buttons natively.
                  if (!kIsWeb &&
                      !isMacOSPlatform &&
                      !UpdateManager.isEmbedded &&
                      !settings.kFullscreen.value)
                    SizedBox(
                      width: 138,
                      child: Builder(builder: (context) {
                        if (isLinuxPlatform) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              DecoratedMinimizeButton(
                                onPressed: windowManager.minimize,
                              ),
                              DecoratedMaximizeButton(
                                onPressed: () async {
                                  if (await windowManager.isMaximized()) {
                                    windowManager.unmaximize();
                                  } else {
                                    windowManager.maximize();
                                  }
                                },
                              ),
                              DecoratedCloseButton(
                                onPressed: () => performWindowClose(context),
                              ),
                            ].map((button) {
                              return Padding(
                                padding: const EdgeInsetsDirectional.all(2.0),
                                child: button,
                              );
                            }).toList(),
                          );
                        }
                        return Row(children: [
                          WindowCaptionButton.minimize(
                            brightness: theme.brightness,
                            onPressed: () async {
                              final isMinimized =
                                  await windowManager.isMinimized();
                              if (isMinimized) {
                                windowManager.restore();
                              } else {
                                windowManager.minimize();
                              }
                            },
                          ),
                          FutureBuilder<bool>(
                            future: windowManager.isMaximized(),
                            builder: (BuildContext context,
                                AsyncSnapshot<bool> snapshot) {
                              if (snapshot.data == true) {
                                return WindowCaptionButton.unmaximize(
                                  brightness: theme.brightness,
                                  onPressed: windowManager.unmaximize,
                                );
                              }
                              return WindowCaptionButton.maximize(
                                brightness: theme.brightness,
                                onPressed: windowManager.maximize,
                              );
                            },
                          ),
                          WindowCaptionButton.close(
                            brightness: theme.brightness,
                            onPressed: () => performWindowClose(context),
                          ),
                        ]);
                      }),
                    ),
                ]),
              ),
              if (showNavigator)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 4.0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...navData.map((data) {
                          final isSelected = tab == data.tab;
                          final icon =
                              isSelected ? data.selectedIcon : data.icon;
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
          ),
        );
      },
    );

    if (settings.kFullscreen.value && settings.kImmersiveMode.value) {
      return MouseRegion(
        onEnter: (_) {
          showOverlayEntry(context, bar);
        },
        child: const SizedBox(
          height: 4,
          width: double.infinity,
        ),
      );
    }

    return bar;
  }

  OverlayEntry? _overlayEntry;
  void showOverlayEntry(BuildContext context, Widget bar) {
    _overlayEntry = OverlayEntry(builder: (context) {
      return AnimatedBuilder(
        animation: _animationController,
        child: bar,
        builder: (context, animation) {
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: _animationController.status == AnimationStatus.forward,
              child: MouseRegion(
                onExit: (_) {
                  dismissOverlayEntry();
                },
                child: Material(
                  color: Colors.transparent,
                  elevation: 8,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeInOut,
                    )),
                    child: animation,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  Future<void> dismissOverlayEntry() async {
    await _animationController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
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
        const margin = 12.0;

        return Stack(children: [
          Positioned(
            top: willFitY ? pos.dy + box.size.height : null,
            bottom: willFitY ? null : constraints.maxHeight - pos.dy + 1.0,
            left: clampDouble(
              pos.dx - (CurrentTasks.width / 2),
              margin,
              constraints.maxWidth - CurrentTasks.width - margin,
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

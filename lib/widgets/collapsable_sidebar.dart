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

import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const kSidebarConstraints = BoxConstraints(maxWidth: 256.0);
const kCompactSidebarConstraints = BoxConstraints(maxWidth: 48.0);

typedef SidebarBuilder = Widget Function(
  BuildContext context,
  bool collapsed,
  Widget collapseButton,
);

class CollapsableSidebar extends StatefulWidget {
  final SidebarBuilder builder;

  /// Whether the sidebar is positioned at the left
  final bool left;

  final ValueChanged<bool>? onCollapseStateChange;

  final bool initiallyClosed;

  const CollapsableSidebar({
    super.key,
    required this.builder,
    this.left = true,
    this.onCollapseStateChange,
    this.initiallyClosed = false,
  });

  @override
  State<CollapsableSidebar> createState() => _CollapsableSidebarState();
}

class _CollapsableSidebarState extends State<CollapsableSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController collapseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    value: widget.initiallyClosed ? 1.0 : 0.0,
  );

  Animation<double> get collapseAnimation {
    return CurvedAnimation(
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
      parent: collapseController,
    );
  }

  final collapseButtonKey = GlobalKey();
  final sidebarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    collapseController.addListener(() {
      if (collapseController.isCompleted) {
        widget.onCollapseStateChange?.call(true);
      } else if (collapseController.isDismissed) {
        widget.onCollapseStateChange?.call(false);
      }
    });
  }

  @override
  void dispose() {
    collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: collapseAnimation,
      builder: (context, child) {
        final isTransitioning = collapseAnimation.value > 0.0 &&
            collapseAnimation.value < 1.0 &&
            collapseController.status != AnimationStatus.completed &&
            collapseController.status != AnimationStatus.dismissed;
        final collapsed = collapseController.isCompleted;
        final collapseButton = Container(
          alignment: isTransitioning
              ? (widget.left
                  ? AlignmentDirectional.topStart
                  : AlignmentDirectional.topEnd)
              : AlignmentDirectional.center,
          padding: collapsed
              ? EdgeInsetsDirectional.zero
              : widget.left
                  ? const EdgeInsetsDirectional.symmetric(horizontal: 5.0)
                  : const EdgeInsetsDirectional.only(end: 5.0),
          child: SquaredIconButton(
            key: collapseButtonKey,
            tooltip: collapsed ? loc.expand : loc.collapse,
            icon: RotationTransition(
              turns: (widget.left
                      ? Tween(
                          begin: 0.5,
                          end: 1.0,
                        )
                      : Tween(
                          begin: 1.0,
                          end: 0.5,
                        ))
                  .animate(collapseAnimation),
              child: const Icon(Icons.keyboard_arrow_right),
            ),
            onPressed: () {
              if (collapseController.isCompleted) {
                collapseController.reverse();
              } else {
                collapseController.forward();
              }
            },
          ),
        );

        return ConstrainedBox(
          constraints: BoxConstraintsTween(
            begin: kSidebarConstraints,
            end: kCompactSidebarConstraints,
          ).evaluate(collapseAnimation),
          child: () {
            if (collapseAnimation.value > 0.35) {
              return Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 6.0),
                child: Center(
                  child: widget.builder(context, true, collapseButton),
                ),
              );
            }

            return widget.builder(context, false, collapseButton);
          }(),
        );
      },
    );
  }
}

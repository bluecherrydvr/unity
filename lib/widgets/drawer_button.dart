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

import 'package:flutter/material.dart';

/// A helper function that returns a [UnityDrawerButton] if the parent
/// [Scaffold] has a drawer.
///
/// This is useful for when you want to display a drawer button in the appbar
/// but only if the parent [Scaffold] has a drawer.
// ignore: non_constant_identifier_names
Widget? MaybeUnityDrawerButton(
  BuildContext context, {
  EdgeInsetsGeometry padding = EdgeInsetsDirectional.zero,
  VoidCallback? open,
}) {
  if (Scaffold.hasDrawer(context)) {
    return Padding(
      padding: padding,
      child: UnityDrawerButton(
        enforce: true,
        open: Scaffold.of(context).openDrawer,
      ),
    );
  }

  return null;
}

/// A button that listen to updates to the parent [Scaffold] and display the
/// drawer button accordingly
class UnityDrawerButton extends StatelessWidget {
  final Color? iconColor;
  final double? iconSize;
  final double splashRadius;

  final bool enforce;
  final VoidCallback? open;

  const UnityDrawerButton({
    super.key,
    this.iconColor,
    this.iconSize = 22.0,
    this.splashRadius = 20.0,
    this.enforce = false,
    this.open,
  });

  @override
  Widget build(BuildContext context) {
    if (Scaffold.hasDrawer(context) || enforce) {
      return Tooltip(
        message: MaterialLocalizations.of(context).openAppDrawerTooltip,
        child: Center(
          child: SizedBox(
            height: 44.0,
            width: 44.0,
            child: InkWell(
              onTap: open ?? () => Scaffold.of(context).openDrawer(),
              radius: 10.0,
              borderRadius: BorderRadius.circular(100.0),
              child: Icon(Icons.menu, color: iconColor, size: iconSize),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

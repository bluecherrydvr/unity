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

import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/screens/layouts/device_grid.dart';
import 'package:bluecherry_client/widgets/desktop_buttons.dart';
import 'package:flutter/material.dart';

class AlternativeLayoutView extends StatefulWidget {
  const AlternativeLayoutView({super.key, required this.layout});

  final Layout layout;

  @override
  State<AlternativeLayoutView> createState() => _AlternativeLayoutViewState();
}

class _AlternativeLayoutViewState extends State<AlternativeLayoutView> {
  bool _isHovering = false;
  Timer? _hoverTimer;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) {
        if (mounted) setState(() => _isHovering = true);
      },
      onExit: (d) {
        _hoverTimer?.cancel();
        if (mounted) setState(() => _isHovering = false);
      },
      onHover: (event) {
        if (mounted) setState(() => _isHovering = true);
        _hoverTimer?.cancel();
        _hoverTimer = Timer(const Duration(milliseconds: 2000), () {
          if (mounted) setState(() => _isHovering = false);
        });
      },
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutView(layout: widget.layout, showOptions: false),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOut,
                top: _isHovering ? 0.0 : -64.0,
                left: 0.0,
                right: 0.0,
                height: 40.0,
                child: WindowButtons(
                  title: widget.layout.name,
                  showNavigator: false,
                  flexible: LayoutOptions(
                    layout: widget.layout,
                    isFullscreen: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

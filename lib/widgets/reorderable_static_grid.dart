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

import 'package:bluecherry_client/utils/methods.dart';
import 'package:flutter/material.dart';
import 'package:reorderables/reorderables.dart';

/// The default spacing between the grid items
const kGridInnerPadding = 8.0;

/// The default padding for the grid
const kGridPadding = EdgeInsetsDirectional.all(10.0);

/// A non-scrollable reorderable grid view
class StaticGrid extends StatefulWidget {
  final int crossAxisCount;
  final List<Widget> children;

  /// The child to show when the grid is empty
  final Widget? emptyChild;

  /// The aspect ratio of each child
  final double childAspectRatio;

  final double mainAxisSpacing;
  final double crossAxisSpacing;

  final ReorderCallback onReorder;

  /// Whether reordering is enabled
  final bool reorderable;

  /// The padding around the grid
  final EdgeInsetsGeometry padding;

  /// Creates a static grid
  const StaticGrid({
    super.key,
    required this.crossAxisCount,
    required this.children,
    this.emptyChild,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = kGridInnerPadding,
    this.crossAxisSpacing = kGridInnerPadding,
    required this.onReorder,
    this.reorderable = true,
    this.padding = kGridPadding,
  });

  @override
  State<StaticGrid> createState() => StaticGridState();
}

class StaticGridState extends State<StaticGrid> {
  List<Widget> realChildren = [];
  int get gridRows => (realChildren.length / widget.crossAxisCount).round();
  void generateRealChildren() {
    realChildren = [...widget.children];

    bool check() {
      if (realChildren.isEmpty) return false;

      // if the children length is multiple of the crossAxisCount, return. This
      // avoids adding multiple emtpy areas in the view
      if (realChildren.length % widget.crossAxisCount == 0) return false;
      if (gridRows == 1) return false;

      return true;
    }

    while (check()) {
      realChildren.add(const SizedBox.shrink());
    }
  }

  @override
  void initState() {
    super.initState();
    generateRealChildren();
  }

  @override
  void didUpdateWidget(covariant StaticGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children != widget.children) {
      generateRealChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty && widget.emptyChild != null) {
      return widget.emptyChild!;
    }

    return Padding(
      padding: widget.padding.add(EdgeInsetsDirectional.only(
        start: widget.crossAxisSpacing,
        top: widget.mainAxisSpacing,
      )),
      child: LayoutBuilder(builder: (context, constraints) {
        var width = (constraints.biggest.width / widget.crossAxisCount) -
            widget.mainAxisSpacing;

        final height = width / widget.childAspectRatio;
        final gridHeight =
            height * gridRows + widget.crossAxisSpacing * gridRows;

        // If the items heights summed will overflow the available space, reduce
        // the width of the items, making it possible to fit all the items in the
        // view
        if (gridHeight > constraints.biggest.height) {
          width -= gridHeight - constraints.biggest.height;
        }

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ReorderableWrap(
            enableReorder: widget.reorderable,
            spacing: widget.mainAxisSpacing,
            runSpacing: widget.crossAxisSpacing,
            minMainAxisCount: widget.crossAxisCount,
            maxMainAxisCount: widget.crossAxisCount,
            onReorder: widget.onReorder,
            needsLongPressDraggable: isMobile,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            children: List.generate(realChildren.length, (index) {
              return SizedBox(
                key: ValueKey(index),
                width: width,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.childAspectRatio,
                    child: realChildren[index],
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

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
const kGridInnerPadding = 4.0;

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
  late var crossAxisCount = widget.crossAxisCount;
  List<Widget> realChildren = [];
  int get gridRows => (realChildren.length / crossAxisCount).ceil();
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
      crossAxisCount = widget.crossAxisCount;
      generateRealChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty && widget.emptyChild != null) {
      return widget.emptyChild!;
    }
    return Padding(
      padding: widget.padding.add(EdgeInsetsDirectional.symmetric(
        horizontal: widget.crossAxisSpacing,
        vertical: widget.mainAxisSpacing,
      )),
      child: LayoutBuilder(builder: (context, constraints) {
        late double gridHeight, childWidth;
        void calculate() {
          var availableWidth = constraints.biggest.width -
              widget.padding.horizontal -
              (widget.crossAxisCount - 1) * widget.crossAxisSpacing;

          childWidth = availableWidth / crossAxisCount;
          final childHeight = childWidth / widget.childAspectRatio;
          gridHeight =
              childHeight * gridRows + widget.crossAxisSpacing * (gridRows - 1);

          if (gridRows == 1) {
            // If there is enough space for another row, try to accomodate it
            if (gridHeight * 2 < constraints.biggest.height) {
              crossAxisCount -= 1;
              calculate();
            }

            // For a single row, ensure childHeight does not exceed the
            // available height
            if (childHeight > constraints.biggest.height) {
              final maxHeight = constraints.biggest.height;
              childWidth = maxHeight * widget.childAspectRatio;
              gridHeight = maxHeight;
            }
          } else {
            // For multiple rows, calculate gridHeight and adjust childWidth if
            // necessary
            gridHeight = (childHeight * gridRows) +
                (widget.crossAxisSpacing * (gridRows - 1));

            if (gridHeight > constraints.biggest.height) {
              // Calculate the maximum height each child can have to fit
              // within the available height
              final maxHeight = constraints.biggest.height / gridRows -
                  widget.crossAxisSpacing;

              // Calculate the new width based on the maximum height and
              // the aspect ratio
              childWidth = maxHeight * widget.childAspectRatio;
            }
          }
        }

        calculate();

        return SizedBox(
          height: gridHeight,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: true),
            child: ReorderableWrap(
              enableReorder: widget.reorderable,
              spacing: widget.mainAxisSpacing,
              runSpacing: widget.crossAxisSpacing,
              minMainAxisCount: crossAxisCount,
              maxMainAxisCount: crossAxisCount,
              onReorder: widget.onReorder,
              needsLongPressDraggable: isMobile,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              children: List.generate(realChildren.length, (index) {
                return SizedBox(
                  key: ValueKey(index),
                  width: childWidth,
                  child: AspectRatio(
                    aspectRatio:
                        widget.childAspectRatio.clamp(0.1, double.infinity),
                    child: realChildren[index],
                  ),
                );
              }),
            ),
          ),
        );
      }),
    );
  }
}

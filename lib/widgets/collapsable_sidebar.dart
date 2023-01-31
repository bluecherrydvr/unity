import 'package:flutter/material.dart';

const kSidebarConstraints = BoxConstraints(maxWidth: 220.0);
const kCompactSidebarConstraints = BoxConstraints(maxWidth: 50.0);

typedef SidebarBuilder = Widget Function(
  BuildContext context,
  Widget collapseButton,
);

class CollapsableSidebar extends StatefulWidget {
  final SidebarBuilder builder;

  /// Whether the sidebar is positioned at the left
  final bool left;

  const CollapsableSidebar({
    Key? key,
    required this.builder,
    this.left = true,
  }) : super(key: key);

  @override
  State<CollapsableSidebar> createState() => _CollapsableSidebarState();
}

class _CollapsableSidebarState extends State<CollapsableSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController collapseController;
  Animation<double> get collapseAnimation => CurvedAnimation(
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
        parent: collapseController,
      );
  final collapseButtonKey = GlobalKey();
  final sidebarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: collapseAnimation,
      builder: (context, child) {
        final collapseButton = Padding(
          padding: widget.left
              ? const EdgeInsetsDirectional.only(start: 5.0)
              : const EdgeInsetsDirectional.only(end: 5.0),
          child: IconButton(
            key: collapseButtonKey,
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
              child: const Icon(
                Icons.keyboard_arrow_right,
              ),
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
                alignment: widget.left
                    ? AlignmentDirectional.topStart
                    : AlignmentDirectional.topEnd,
                child: collapseButton,
              );
            }

            return widget.builder(context, collapseButton);
          }(),
        );
      },
    );
  }
}

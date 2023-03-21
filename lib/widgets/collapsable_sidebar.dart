import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  final ValueChanged<bool>? onCollapseStateChange;

  const CollapsableSidebar({
    Key? key,
    required this.builder,
    this.left = true,
    this.onCollapseStateChange,
  }) : super(key: key);

  @override
  State<CollapsableSidebar> createState() => _CollapsableSidebarState();
}

class _CollapsableSidebarState extends State<CollapsableSidebar>
    with SingleTickerProviderStateMixin {
  late final AnimationController collapseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
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
    final localizations = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: collapseAnimation,
      builder: (context, child) {
        final collapseButton = Padding(
          padding: widget.left
              ? const EdgeInsetsDirectional.only(start: 5.0)
              : const EdgeInsetsDirectional.only(end: 5.0),
          child: IconButton(
            key: collapseButtonKey,
            tooltip: collapseController.isCompleted
                ? localizations.open
                : localizations.close,
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

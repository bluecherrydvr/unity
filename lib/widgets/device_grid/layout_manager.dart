import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayoutManager extends StatefulWidget {
  const LayoutManager({Key? key}) : super(key: key);

  @override
  State<LayoutManager> createState() => _LayoutManagerState();
}

class _LayoutManagerState extends State<LayoutManager> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final view = context.watch<DesktopViewProvider>();

    return SizedBox(
      height: 200.0,
      child: Column(children: [
        const Divider(height: 1.0),
        Material(
          color: theme.appBarTheme.backgroundColor,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 4.0,
              bottom: 4.0,
              start: 12.0,
              end: 8.0,
            ),
            child: Row(children: [
              const Icon(Icons.view_agenda),
              const SizedBox(width: 12.0),
              const Expanded(child: Text('View')),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New layout',
                onPressed: () {},
              ),
            ]),
          ),
        ),
        Expanded(
          child: ListView(
            children: view.layouts.map((layout) {
              return LayoutTile(
                layout: layout,
                selected: view.currentLayout == layout,
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1.0),
      ]),
    );
  }
}

class LayoutTile extends StatelessWidget {
  const LayoutTile({
    Key? key,
    required this.layout,
    required this.selected,
  }) : super(key: key);

  final Layout layout;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        selected
            ? selectedIconForLayout(layout.layoutType)
            : iconForLayout(layout.layoutType),
      ),
      horizontalTitleGap: 16.0,
      minLeadingWidth: 24.0,
      contentPadding: EdgeInsetsDirectional.only(
        start: 12.0,
        end: 16.0,
      ),
      title: Text(layout.name),
      trailing: PopupMenuButton(
        child: Icon(isDesktop ? Icons.more_horiz : Icons.more_vert),
        position: isDesktop ? PopupMenuPosition.under : PopupMenuPosition.over,
        itemBuilder: (context) {
          return [
            buildPopupItem(const Icon(Icons.delete), 'Delete'),
          ];
        },
      ),
    );
  }

  PopupMenuItem buildPopupItem(Icon icon, String text) {
    return PopupMenuItem(
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10.0),
          Text(text),
        ],
      ),
    );
  }

  IconData iconForLayout(DesktopLayoutType type) {
    switch (type) {
      case DesktopLayoutType.singleView:
        return Icons.crop_square;
      case DesktopLayoutType.multipleView:
        return Icons.view_comfy_outlined;
      case DesktopLayoutType.compactView:
        return Icons.view_compact_outlined;
    }
  }

  IconData selectedIconForLayout(DesktopLayoutType type) {
    switch (type) {
      case DesktopLayoutType.singleView:
        return Icons.square_rounded;
      case DesktopLayoutType.multipleView:
        return Icons.view_comfy;
      case DesktopLayoutType.compactView:
        return Icons.view_compact;
    }
  }
}

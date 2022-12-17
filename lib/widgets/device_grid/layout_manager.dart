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
              end: 16.0,
            ),
            child: Row(children: [
              const Icon(Icons.view_agenda),
              const SizedBox(width: 12.0),
              const Expanded(child: Text('View')),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New layout',
                padding: EdgeInsets.zero,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const NewLayoutDialog(),
                  );
                },
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
      selected: selected,
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Icon(
          selected
              ? selectedIconForLayout(layout.layoutType)
              : iconForLayout(layout.layoutType),
          key: ValueKey(layout.layoutType),
          size: 20.0,
        ),
      ),
      horizontalTitleGap: 16.0,
      minLeadingWidth: 24.0,
      contentPadding: const EdgeInsetsDirectional.only(
        start: 12.0,
        end: 16.0,
      ),
      title: Text(layout.name),
      trailing: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(isDesktop ? Icons.more_horiz : Icons.more_vert),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => EditLayoutDialog(layout: layout),
          );
        },
      ),
      onTap: () {
        DesktopViewProvider.instance.updateCurrentLayout(
          DesktopViewProvider.instance.layouts.indexOf(layout),
        );
      },
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

String textForLayout(DesktopLayoutType type) {
  switch (type) {
    case DesktopLayoutType.singleView:
      return 'Single view';
    case DesktopLayoutType.multipleView:
      return 'Multiple view';
    case DesktopLayoutType.compactView:
      return 'Compact view';
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

class _LayoutTypeChooser extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _LayoutTypeChooser({
    Key? key,
    required this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: DesktopLayoutType.values.map<Widget>((type) {
        final isSelected = type.index == selected;
        final icon =
            isSelected ? selectedIconForLayout(type) : iconForLayout(type);

        return Row(children: [
          const SizedBox(width: 12.0),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(icon, key: ValueKey(icon), size: 22.0),
          ),
          const SizedBox(width: 8.0),
          Text(textForLayout(type)),
          const SizedBox(width: 16.0),
        ]);
      }).toList(),
      isSelected: DesktopLayoutType.values.map((type) {
        return type.index == selected;
      }).toList(),
      onPressed: onSelect,
    );
  }
}

class NewLayoutDialog extends StatefulWidget {
  const NewLayoutDialog({Key? key}) : super(key: key);

  @override
  State<NewLayoutDialog> createState() => _NewLayoutDialogState();
}

class _NewLayoutDialogState extends State<NewLayoutDialog> {
  final controller = TextEditingController();
  int selected = 1;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create new layout'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Layout name',
            label: Text('Layout name'),
          ),
        ),
        const SubHeader('Layout type', padding: EdgeInsets.zero),
        _LayoutTypeChooser(
          selected: selected,
          onSelect: (index) => setState(() => selected = index),
        ),
      ]),
      actions: [
        OutlinedButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            DesktopViewProvider.instance.addLayout(Layout(
              name: controller.text.isNotEmpty
                  ? controller.text
                  : 'Layout ${DesktopViewProvider.instance.layouts.length + 1}',
              layoutType: DesktopLayoutType.values[selected],
              devices: [],
            ));
            Navigator.of(context).pop();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class EditLayoutDialog extends StatefulWidget {
  const EditLayoutDialog({Key? key, required this.layout}) : super(key: key);

  final Layout layout;

  @override
  State<EditLayoutDialog> createState() => _EditLayoutDialogState();
}

class _EditLayoutDialogState extends State<EditLayoutDialog> {
  late final controller = TextEditingController(text: widget.layout.name);
  late int selected = widget.layout.layoutType.index;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Edit ${widget.layout.name}')),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 18.0,
            onPressed: () {
              DesktopViewProvider.instance.removeLayout(widget.layout);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Layout name',
            label: Text('Layout name'),
          ),
        ),
        const SubHeader('Layout type', padding: EdgeInsets.zero),
        _LayoutTypeChooser(
          selected: selected,
          onSelect: (index) => setState(() => selected = index),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            DesktopViewProvider.instance.updateLayout(
              widget.layout,
              widget.layout.copyWith(
                name: controller.text.isEmpty ? null : controller.text,
                layoutType: DesktopLayoutType.values[selected],
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

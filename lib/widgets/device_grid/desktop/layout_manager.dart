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
import 'dart:io';

import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/utils/window.dart';
import 'package:bluecherry_client/widgets/hover_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class LayoutManager extends StatefulWidget {
  final Widget collapseButton;

  const LayoutManager({
    super.key,
    required this.collapseButton,
  });

  @override
  State<LayoutManager> createState() => _LayoutManagerState();
}

class _LayoutManagerState extends State<LayoutManager> {
  Timer? timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsProvider>();
    timer?.cancel();
    timer = Timer.periodic(settings.layoutCyclingTogglePeriod, (timer) {
      if (!mounted) return;

      final view = DesktopViewProvider.instance;

      if (settings.layoutCyclingEnabled) {
        final currentIsLast =
            view.currentLayoutIndex == view.layouts.length - 1;

        view.updateCurrentLayout(
          currentIsLast ? 0 : view.currentLayoutIndex + 1,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final settings = context.watch<SettingsProvider>();

    return SizedBox(
      height: 210.0,
      child: Column(children: [
        Material(
          color: theme.appBarTheme.backgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                top: 2.0,
                bottom: 2.0,
                end: 12.0,
              ),
              child: Row(children: [
                widget.collapseButton,
                const SizedBox(width: 5.0),
                Expanded(
                  child: Text(
                    loc.view,
                    maxLines: 1,
                  ),
                ),
                SquaredIconButton(
                  icon: Icon(
                    Icons.cyclone,
                    size: 18.0,
                    color: settings.layoutCyclingEnabled
                        ? theme.colorScheme.primary
                        : IconTheme.of(context).color,
                  ),
                  tooltip: loc.cycle,
                  onPressed: settings.toggleCycling,
                ),
                SquaredIconButton(
                  icon: Icon(
                    Icons.add,
                    size: 18.0,
                    color: IconTheme.of(context).color,
                  ),
                  tooltip: loc.newLayout,
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
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            onReorder: view.reorderLayout,
            itemCount: view.layouts.length,
            itemBuilder: (context, index) {
              final layout = view.layouts[index];
              return LayoutTile(
                key: ValueKey(layout),
                layout: layout,
                selected: view.currentLayout == layout,
                reorderableIndex: index,
              );
            },
          ),
        ),
        const Divider(height: 1.0),
      ]),
    );
  }
}

class LayoutTile extends StatefulWidget {
  const LayoutTile({
    super.key,
    required this.layout,
    required this.selected,
    required this.reorderableIndex,
  });

  final Layout layout;
  final bool selected;
  final int reorderableIndex;

  @override
  State<LayoutTile> createState() => _LayoutTileState();
}

class _LayoutTileState extends State<LayoutTile> {
  PointerDeviceKind? longPressKind;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final view = context.watch<DesktopViewProvider>();

    return ReorderableDragStartListener(
      index: widget.reorderableIndex,
      enabled: widget.selected,
      child: HoverButton(
        hitTestBehavior: HitTestBehavior.translucent,
        onSecondaryTap: () => _displayOptions(context),
        onLongPressDown: (d) => longPressKind = d.kind,
        onLongPressStart: (d) {
          switch (longPressKind) {
            case PointerDeviceKind.touch:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              _displayOptions(context);
              break;
            default:
              break;
          }
        },
        onLongPressEnd: (d) => longPressKind = null,
        onLongPressCancel: () => longPressKind = null,
        onLongPressUp: () => longPressKind = null,
        builder: (context, states) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: widget.selected,
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: ReorderableDragStartListener(
              index: widget.reorderableIndex,
              enabled: !widget.selected,
              child: Icon(
                widget.selected
                    ? selectedIconForLayout(widget.layout.type)
                    : iconForLayout(widget.layout.type),
                key: ValueKey(widget.layout.type),
                size: 20.0,
              ),
            ),
          ),
          minLeadingWidth: 24.0,
          title: Text(widget.layout.name, maxLines: 1),
          subtitle: Text(
            loc.nDevices(widget.layout.devices.length),
            maxLines: 1,
          ),
          trailing: states.isHovering
              ? Tooltip(
                  message: loc.cameraOptions,
                  preferBelow: false,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4.0),
                    onTap: () => _displayOptions(context),
                    child: Icon(moreIconData),
                  ),
                )
              : null,
          onTap: !widget.selected
              ? () =>
                  view.updateCurrentLayout(view.layouts.indexOf(widget.layout))
              : null,
        ),
      ),
    );
  }

  Future<void> _displayOptions(BuildContext context) async {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    const padding = EdgeInsets.symmetric(horizontal: 16.0);

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset(
      padding.left,
      padding.top,
    ));
    final size = Size(
      renderBox.size.width - padding.right * 2,
      renderBox.size.height - padding.bottom,
    );

    await showMenu(
      context: context,
      elevation: 4.0,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      constraints: BoxConstraints(
        maxWidth: size.width,
        minWidth: size.width,
      ),
      items: <PopupMenuEntry>[
        PopupLabel(
          label: Padding(
            padding: padding.add(const EdgeInsets.symmetric(vertical: 6.0)),
            child: Text(
              widget.layout.name,
              maxLines: 1,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: Text(loc.editLayout),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EditLayoutDialog(layout: widget.layout),
            );
          },
        ),
        if (isDesktopPlatform)
          PopupMenuItem(
            onTap: widget.layout.openInANewWindow,
            child: Text(loc.openInANewWindow),
          ),
        PopupMenuItem(
          onTap: () {
            widget.layout.export(dialogTitle: loc.exportLayout);
          },
          child: Text(loc.exportLayout),
        ),
      ],
    );
  }
}

String textForLayout(BuildContext context, DesktopLayoutType type) {
  final loc = AppLocalizations.of(context);

  switch (type) {
    case DesktopLayoutType.singleView:
      return loc.singleView;
    case DesktopLayoutType.multipleView:
      return loc.multipleView;
    case DesktopLayoutType.compactView:
      return loc.compactView;
  }
}

IconData iconForLayout(DesktopLayoutType type) {
  switch (type) {
    case DesktopLayoutType.singleView:
      return Icons.crop_square;
    case DesktopLayoutType.multipleView:
      return Icons.view_compact_outlined;
    case DesktopLayoutType.compactView:
      return Icons.view_comfy_outlined;
  }
}

IconData selectedIconForLayout(DesktopLayoutType type) {
  switch (type) {
    case DesktopLayoutType.singleView:
      return Icons.square_rounded;
    case DesktopLayoutType.multipleView:
      return Icons.view_compact;
    case DesktopLayoutType.compactView:
      return Icons.view_comfy;
  }
}

class _LayoutTypeChooser extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _LayoutTypeChooser({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: DesktopLayoutType.values.map((type) {
        return type.index == selected;
      }).toList(),
      onPressed: onSelect,
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
          Text(textForLayout(context, type)),
          const SizedBox(width: 16.0),
        ]);
      }).toList(),
    );
  }
}

class NewLayoutDialog extends StatefulWidget {
  const NewLayoutDialog({super.key});

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

  Stream<Layout>? import(BuildContext context, String fallbackName) async* {
    final loc = AppLocalizations.of(context);
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['xml'],
      allowCompression: false,
      allowMultiple: true,
      type: FileType.custom,
      dialogTitle: loc.importLayout,
      lockParentWindow: true,
    );
    if (result != null) {
      for (final platformFile in result.files) {
        String xml;
        if (platformFile.path == null) {
          xml = String.fromCharCodes(platformFile.bytes!.buffer.asUint8List());
        } else {
          final file = File(platformFile.path!);
          xml = await file.readAsString();
        }
        final Layout layout;
        try {
          layout = Layout.fromXML(xml, fallbackName: fallbackName);
        } on ArgumentError catch (e) {
          if (mounted) {
            showImportFailedMessage(
              context,
              loc.layoutImportFileCorruptedWithMessage(e.message),
            );
          }
          return;
        } on DeviceServerNotFound catch (e) {
          if (mounted) {
            showImportFailedMessage(
              context,
              loc.failedToImportMessage(
                e.layoutName,
                e.server.ip,
                e.server.port,
              ),
            );
          }
          return;
        } catch (e) {
          if (mounted) {
            showImportFailedMessage(
              context,
              loc.layoutImportFileCorrupted,
            );
          }
          return;
        }

        yield layout;
      }
    }
  }

  void showImportFailedMessage(BuildContext context, String message) {
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsetsDirectional.only(
          start: 16.0,
          top: 8.0,
          bottom: 8.0,
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          Builder(builder: (context) {
            return TextButton(
              child: Text(loc.close),
              onPressed: () {
                ScaffoldMessenger.of(context).removeCurrentMaterialBanner();
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final view = context.watch<DesktopViewProvider>();
    final fallbackName = loc.fallbackLayoutName(view.layouts.length + 1);

    return AlertDialog(
      title: Text(loc.createNewLayout),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: loc.layoutNameHint,
            label: Text(loc.layoutName),
          ),
          textInputAction: TextInputAction.none,
        ),
        SubHeader(loc.layoutTypeLabel, padding: EdgeInsetsDirectional.zero),
        _LayoutTypeChooser(
          selected: selected,
          onSelect: (index) {
            if (mounted) setState(() => selected = index);
          },
        ),
      ]),
      actions: [
        Row(children: [
          ElevatedButton(
            onPressed: () async {
              final layouts = await import(context, fallbackName)?.toList();
              if (layouts != null) {
                for (final layout in layouts) {
                  view.addLayout(layout);
                }
              }
              if (mounted) Navigator.of(context).pop();
            },
            child: Text(loc.importLayout),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: Navigator.of(context).pop,
            child: Text(loc.cancel),
          ),
          const SizedBox(width: 12.0),
          FilledButton(
            onPressed: () {
              view.addLayout(Layout(
                name:
                    controller.text.isNotEmpty ? controller.text : fallbackName,
                type: DesktopLayoutType.values[selected],
                devices: [],
              ));
              Navigator.of(context).pop();
            },
            child: Text(loc.finish),
          ),
        ]),
      ],
    );
  }
}

class EditLayoutDialog extends StatefulWidget {
  const EditLayoutDialog({super.key, required this.layout});

  final Layout layout;

  @override
  State<EditLayoutDialog> createState() => _EditLayoutDialogState();
}

class _EditLayoutDialogState extends State<EditLayoutDialog> {
  late final controller = TextEditingController(text: widget.layout.name);
  late int selected = widget.layout.type.index;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final view = context.watch<DesktopViewProvider>();

    return AlertDialog(
      title: Row(children: [
        Expanded(child: Text(loc.editSpecificLayout(widget.layout.name))),
        if (view.layouts.length > 1)
          SquaredIconButton(
            icon: Icon(
              Icons.delete,
              color: theme.colorScheme.error,
              size: 18.0,
            ),
            tooltip: loc.delete,
            // iconSize: 18.0,
            onPressed: () {
              view.removeLayout(widget.layout);
              Navigator.of(context).pop();
            },
          ),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: loc.layoutNameHint,
            label: Text(loc.layoutName),
          ),
          textInputAction: TextInputAction.none,
        ),
        SubHeader(loc.layoutName, padding: EdgeInsetsDirectional.zero),
        _LayoutTypeChooser(
          selected: selected,
          onSelect: (index) {
            if (mounted) setState(() => selected = index);
          },
        ),
      ]),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            view.updateLayout(
              widget.layout,
              widget.layout.copyWith(
                name: controller.text.isEmpty ? null : controller.text,
                type: DesktopLayoutType.values[selected],
              ),
            );
            Navigator.of(context).pop();
          },
          child: Text(loc.finish),
        ),
      ],
    );
  }
}

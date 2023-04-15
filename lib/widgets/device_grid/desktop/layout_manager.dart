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
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/widgets/misc.dart';
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
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(kCycleTogglePeriod, (timer) {
      final settings = SettingsProvider.instance;
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
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = context.watch<DesktopViewProvider>();
    final settings = context.watch<SettingsProvider>();

    return SizedBox(
      height: 210.0,
      child: Column(children: [
        Material(
          color: theme.appBarTheme.backgroundColor,
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
                  AppLocalizations.of(context).view,
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.cyclone,
                  size: 18.0,
                  color: settings.layoutCyclingEnabled
                      ? theme.colorScheme.primary
                      : IconTheme.of(context).color,
                ),
                padding: EdgeInsets.zero,
                tooltip: AppLocalizations.of(context).cycle,
                onPressed: settings.toggleCycling,
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  size: 18.0,
                  color: IconTheme.of(context).color,
                ),
                tooltip: AppLocalizations.of(context).newLayout,
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
    super.key,
    required this.layout,
    required this.selected,
  });

  final Layout layout;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();

    return GestureDetector(
      onSecondaryTap: () {
        showDialog(
          context: context,
          builder: (context) => EditLayoutDialog(layout: layout),
        );
      },
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
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
          end: 8.0,
        ),
        title: Text(layout.name, maxLines: 1),
        subtitle: Text(
          AppLocalizations.of(context).nDevices(layout.devices.length),
          maxLines: 1,
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(moreIconData),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => EditLayoutDialog(layout: layout),
            );
          },
        ),
        onLongPress: isDesktop
            ? null
            : () {
                showDialog(
                  context: context,
                  builder: (context) => EditLayoutDialog(layout: layout),
                );
              },
        onTap: () {
          view.updateCurrentLayout(view.layouts.indexOf(layout));
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
}

String textForLayout(BuildContext context, DesktopLayoutType type) {
  switch (type) {
    case DesktopLayoutType.singleView:
      return AppLocalizations.of(context).singleView;
    case DesktopLayoutType.multipleView:
      return AppLocalizations.of(context).multipleView;
    case DesktopLayoutType.compactView:
      return AppLocalizations.of(context).compactView;
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

  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();

    return AlertDialog(
      title: Text(AppLocalizations.of(context).createNewLayout),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).layoutNameHint,
            label: Text(AppLocalizations.of(context).layoutNameHint),
          ),
        ),
        SubHeader(
          AppLocalizations.of(context).layoutTypeHint,
          padding: EdgeInsets.zero,
        ),
        _LayoutTypeChooser(
          selected: selected,
          onSelect: (index) {
            if (mounted) setState(() => selected = index);
          },
        ),
      ]),
      actions: [
        OutlinedButton(
          onPressed: Navigator.of(context).pop,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            view.addLayout(Layout(
              name: controller.text.isNotEmpty
                  ? controller.text
                  : 'Layout ${view.layouts.length + 1}',
              layoutType: DesktopLayoutType.values[selected],
              devices: [],
            ));
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).finish),
        ),
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
  late int selected = widget.layout.layoutType.index;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<DesktopViewProvider>();

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Edit ${widget.layout.name}')),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 18.0,
            onPressed: view.layouts.length == 1
                ? null
                : () {
                    view.removeLayout(widget.layout);
                    Navigator.of(context).pop();
                  },
          ),
        ],
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).layoutNameHint,
            label: Text(AppLocalizations.of(context).layoutNameHint),
          ),
        ),
        SubHeader(
          AppLocalizations.of(context).layoutTypeHint,
          padding: EdgeInsets.zero,
        ),
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
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            view.updateLayout(
              widget.layout,
              widget.layout.copyWith(
                name: controller.text.isEmpty ? null : controller.text,
                layoutType: DesktopLayoutType.values[selected],
              ),
            );
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).finish),
        ),
      ],
    );
  }
}

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
import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/models/layout.dart';
import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/desktop_view_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

enum MatrixType {
  t16(4),
  t9(3),
  t4(2),
  t1(1);

  final int size;

  const MatrixType(this.size);

  @override
  String toString() {
    return switch (this) {
      MatrixType.t16 => '4x4',
      MatrixType.t9 => '3x3',
      MatrixType.t4 => '2x2',
      MatrixType.t1 => '1x1',
    };
  }

  Widget get icon {
    return switch (this) {
      MatrixType.t16 => const Icon(Icons.grid_4x4),
      MatrixType.t9 => const Icon(Icons.grid_3x3),
      MatrixType.t4 => const Icon(Icons.add),
      MatrixType.t1 => const Icon(Icons.square_outlined),
    };
  }
}

class AddExternalStreamDialog extends StatefulWidget {
  final String? defaultUrl;

  const AddExternalStreamDialog({
    super.key,
    this.defaultUrl,
  });

  static Future<void> show(
    BuildContext context, {
    String? defaultUrl,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddExternalStreamDialog(
        defaultUrl: defaultUrl,
      ),
    );
  }

  static void addStream(
    BuildContext context,
    String url, {
    String? name,
    MatrixType matrixType = MatrixType.t16,
  }) {
    final loc = AppLocalizations.of(context);
    AppLocalizations.localizationsDelegates;
    final device = Device.dump(
      name: name ?? loc.externalStream,
      url: url,
      id: const Uuid().v4().hashCode,
      matrixType: matrixType,
    )..server = Server.dump(name: url);

    final view = context.read<DesktopViewProvider>();
    final layout = view.layouts
        .firstWhereOrNull((layout) => layout.name == loc.externalStream);
    if (layout == null) {
      view.addLayout(Layout(name: loc.externalStream, devices: [device]));
    } else {
      view.add(device, layout);
    }

    view.updateCurrentLayout(
      view.layouts.indexOf(
        view.layouts.firstWhere((layout) => layout.name == loc.externalStream),
      ),
    );
  }

  @override
  State<AddExternalStreamDialog> createState() =>
      _AddExternalStreamDialogState();
}

class _AddExternalStreamDialogState extends State<AddExternalStreamDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  late final urlController = TextEditingController(text: widget.defaultUrl);

  var matrixType = MatrixType.t16;

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    return AlertDialog(
      title: Text(loc.addExternalStream),
      content: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width * 0.425,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      autofocus: true,
                      controller: nameController,
                      decoration: InputDecoration(label: Text(loc.streamName)),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.streamNameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: urlController,
                      decoration: InputDecoration(label: Text(loc.streamURL)),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _finish(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.streamNameRequired;
                        } else if (Uri.tryParse(value) == null) {
                          return loc.streamURLNotValid;
                        }

                        return null;
                      },
                    ),
                  ),
                ]),
                if (settings.betaMatrixedZoomEnabled) ...[
                  const SizedBox(height: 16.0),
                  Text('Matrix type', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 6.0),
                  Center(
                    child: ToggleButtons(
                      isSelected: MatrixType.values.map((type) {
                        return type.index == matrixType.index;
                      }).toList(),
                      onPressed: (type) => setState(() {
                        matrixType = MatrixType.values[type];
                      }),
                      // constraints: buttonConstraints,
                      children: MatrixType.values.map<Widget>((type) {
                        return Row(children: [
                          const SizedBox(width: 12.0),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: KeyedSubtree(
                              key: ValueKey(type),
                              child: IconTheme.merge(
                                data: const IconThemeData(size: 22.0),
                                child: type.icon,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(type.toString()),
                          const SizedBox(width: 16.0),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: Navigator.of(context).pop,
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _finish,
          child: Text(loc.finish),
        ),
      ],
    );
  }

  Future<void> _finish() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    AddExternalStreamDialog.addStream(
      context,
      urlController.text,
      name: nameController.text,
      matrixType: matrixType,
    );

    Navigator.of(context).pop();
  }
}

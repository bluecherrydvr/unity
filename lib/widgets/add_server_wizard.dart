/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
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

import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

class AddServerWizard extends StatefulWidget {
  const AddServerWizard({Key? key}) : super(key: key);

  @override
  State<AddServerWizard> createState() => _AddServerWizardState();
}

class _AddServerWizardState extends State<AddServerWizard> {
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: PageView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 960.0, maxHeight: 640.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 4.0,
                        margin: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4.0,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/icon.png',
                                      height: 168.0,
                                      width: 168.0,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 24.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('project_name'.tr(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline1
                                                ?.copyWith(
                                                  fontSize: 36.0,
                                                )),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          'project_description'.tr(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Spacer(),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'website'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'purchase'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline3
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                ],
                              ),
                            ),
                            ClipRect(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/background.webp',
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 12.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 96.0,
                                          padding: const EdgeInsets.only(
                                            left: 24.0,
                                            top: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'welcome'.tr(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline1
                                                    ?.copyWith(
                                                      fontSize: 24.0,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(height: 8.0),
                                              Text(
                                                'welcome_description'.tr(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headline3
                                                    ?.copyWith(
                                                        color: Colors.white
                                                            .withOpacity(0.87)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: FloatingActionButton(
                                              onPressed: () {
                                                controller.nextPage(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                );
                                              },
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              child: const Icon(
                                                  Icons.arrow_forward),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 1024.0, maxHeight: 640.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 4.0,
                        margin: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4.0,
                              child: Container(
                                height: 108.0,
                                color: Theme.of(context).primaryColor,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    left: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      NavigatorPopButton(
                                        color: Colors.white,
                                        onTap: () {
                                          controller.previousPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                                top: 8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'configure'.tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline1
                                                        ?.copyWith(
                                                          fontSize: 24.0,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Text(
                                                    'configure_description'
                                                        .tr(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline3
                                                        ?.copyWith(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.87)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Form(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: TextFormField(
                                            autofocus: true,
                                            cursorWidth: 1.0,
                                            keyboardType: TextInputType.url,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline3,
                                            decoration: InputDecoration(
                                              label: Text('hostname'.tr()),
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            autofocus: true,
                                            cursorWidth: 1.0,
                                            keyboardType: TextInputType.number,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline3,
                                            decoration: InputDecoration(
                                              label: Text('port'.tr()),
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    TextFormField(
                                      textCapitalization:
                                          TextCapitalization.words,
                                      keyboardType: TextInputType.name,
                                      style:
                                          Theme.of(context).textTheme.headline3,
                                      decoration: InputDecoration(
                                        label: Text('name'.tr()),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            keyboardType: TextInputType.none,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline3,
                                            decoration: InputDecoration(
                                              label: Text('username'.tr()),
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        MaterialButton(
                                          onPressed: () {},
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'use_default'.tr().toUpperCase(),
                                            ),
                                          ),
                                          textColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            obscureText: true,
                                            keyboardType: TextInputType.none,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headline3,
                                            decoration: InputDecoration(
                                              label: Text('password'.tr()),
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Checkbox(
                                          value: true,
                                          onChanged: (_) {},
                                        ),
                                        Text(
                                          'save_password'.tr(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3,
                                        ),
                                        const SizedBox(width: 16.0),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: true,
                                          onChanged: (_) {},
                                        ),
                                        Text(
                                          'connect_automatically_at_startup'
                                              .tr(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headline3,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          MaterialButton(
                                            onPressed: () {
                                              controller.nextPage(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'skip'.tr().toUpperCase(),
                                              ),
                                            ),
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                          MaterialButton(
                                            onPressed: () {},
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'finish'.tr().toUpperCase(),
                                              ),
                                            ),
                                            textColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 1024.0, maxHeight: 640.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 4.0,
                        margin: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              elevation: 4.0,
                              child: Container(
                                height: 108.0,
                                color: Theme.of(context).primaryColor,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    left: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      NavigatorPopButton(
                                        color: Colors.white,
                                        onTap: () {
                                          controller.previousPage(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                                top: 8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'lets_go'.tr(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline1
                                                        ?.copyWith(
                                                          fontSize: 24.0,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 8.0),
                                                  Text(
                                                    'lets_go_description'.tr(),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headline3
                                                        ?.copyWith(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.87)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            ...List.generate(
                                4, (index) => ' • ' + 'tip_$index'.tr()).map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: Text(e),
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: FloatingActionButton(
                                  onPressed: () {
                                    controller.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  child: const Icon(Icons.check),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

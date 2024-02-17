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

import 'package:bluecherry_client/models/server.dart';
import 'package:bluecherry_client/providers/home_provider.dart';
import 'package:bluecherry_client/screens/servers/add_server_info.dart';
import 'package:bluecherry_client/screens/servers/additional_server_settings.dart';
import 'package:bluecherry_client/screens/servers/configure_dvr_server.dart';
import 'package:bluecherry_client/screens/servers/finish.dart';
import 'package:bluecherry_client/widgets/drawer_button.dart';
import 'package:bluecherry_client/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget buildCardAppBar({
  required String title,
  required String description,
  VoidCallback? onBack,
}) {
  return Builder(builder: (context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: SquaredIconButton(
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  onBack();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          Text(
            title,
            style: theme.textTheme.displayMedium,
          ),
        ]),
        const SizedBox(height: 12.0),
        Text(
          description,
          style: theme.textTheme.headlineMedium,
          softWrap: true,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  });
}

class AddServerWizard extends StatefulWidget {
  final VoidCallback onFinish;

  const AddServerWizard({super.key, required this.onFinish});

  @override
  State<AddServerWizard> createState() => _AddServerWizardState();
}

class _AddServerWizardState extends State<AddServerWizard> {
  Server? server;
  final controller = PageController(
    initialPage:
        HomeProvider.instance.automaticallyGoToAddServersScreen ? 1 : 0,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onNext() {
    controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onBack() {
    controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white12,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            Padding(
              padding: MediaQuery.viewInsetsOf(context),
              child: PageView(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Center(child: AddServerInfoScreen(onNext: _onNext)),
                  Center(
                    child: ConfigureDVRServerScreen(
                      onBack: _onBack,
                      onNext: _onNext,
                      server: server,
                      onServerChange: (server) =>
                          setState(() => this.server = server),
                    ),
                  ),
                  Center(
                    child: AdditionalServerSettings(
                      onBack: _onBack,
                      onNext: _onNext,
                      server: server,
                      onServerChanged: (server) async {
                        if (this.server != null) {
                          setState(() => this.server = server);
                        }
                      },
                    ),
                  ),
                  Center(
                    child: LetsGoScreen(
                      server: server,
                      onFinish: widget.onFinish,
                      onBack: _onBack,
                    ),
                  ),
                ],
              ),
            ),
            if (Scaffold.hasDrawer(context))
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top,
                start: 0,
                child: const Material(
                  type: MaterialType.transparency,
                  color: Colors.amber,
                  child: SizedBox(
                    height: kToolbarHeight,
                    width: kToolbarHeight,
                    child: UnityDrawerButton(iconColor: Colors.white),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

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

import 'package:bluecherry_client/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class AddServerInfoScreen extends StatelessWidget {
  final VoidCallback onNext;

  const AddServerInfoScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width / 2.5,
        ),
        alignment: AlignmentDirectional.center,
        child: Card(
          color: theme.cardColor,
          elevation: 4.0,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(16) + MediaQuery.paddingOf(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icon.png',
                      height: 124.0,
                      width: 124.0,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      loc.projectName,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 36.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      loc.projectDescription,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Link(
                          uri: Uri.https('bluecherrydvr.com', '/'),
                          builder: (context, open) {
                            return TextButton(
                              onPressed: open,
                              child: Text(loc.website),
                            );
                          },
                        ),
                        const SizedBox(width: 8.0),
                        Link(
                          uri: Uri.https(
                            'bluecherrydvr.com',
                            '/product/v3license/',
                          ),
                          builder: (context, open) {
                            return TextButton(
                              onPressed: open,
                              child: Text(loc.purchase),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(thickness: 1.0),
                    const SizedBox(height: 16.0),
                    Text(
                      loc.welcome,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      loc.welcomeDescription,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Material(
                child: InkWell(
                  onTap: onNext,
                  child: Container(
                    alignment: AlignmentDirectional.center,
                    width: double.infinity,
                    height: 56.0,
                    child: Text(
                      loc.letsGo.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

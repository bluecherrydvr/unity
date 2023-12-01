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

import 'package:bluecherry_client/utils/extensions.dart';
import 'package:bluecherry_client/utils/widgets/squared_icon_button.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:unity_video_player/unity_video_player.dart';

class CameraViewFitButton extends StatelessWidget {
  final UnityVideoFit fit;
  final ValueChanged<UnityVideoFit> onChanged;

  const CameraViewFitButton({
    super.key,
    required this.fit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SquaredIconButton(
      tooltip: fit.locale(context),
      onPressed: () => onChanged(fit.next),
      icon: Icon(
        fit.icon,
        size: 18.0,
        shadows: outlinedText(),
        color: Colors.white,
      ),
    );
  }
}

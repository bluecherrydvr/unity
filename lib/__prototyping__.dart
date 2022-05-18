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

// TODO: Remove this data after prototyping is complete.

import 'package:bluecherry_client/models/camera.dart';
import 'package:bluecherry_client/models/server.dart';

const kServer = Server(
  '7007cams.bluecherry.app',
  7002,
  'admin',
  'bluecherry',
  [
    Camera('Garage', 'live/6'),
    Camera('Pool', 'live/7'),
    Camera('Trampoline', 'live/8'),
    Camera('Under Deck', 'live/9'),
  ],
);

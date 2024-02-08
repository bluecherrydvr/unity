# Usage

## Overview

The Bluecherry Client lets you watch live and recorded video from your Bluecherry server. It is a cross-platform application that runs on Android, iOS, Windows, macOS, and Linux.

## Download, Installation

Refer to [README.md](./README.md#download) for installation instructions.

## Requirements

You will need a Bluecherry server to use this application. You can buy a license from the [Bluecherry website](https://www.bluecherrydvr.com/).

## Connecting to the server

These steps will guide you through easily connecting to your Bluecherry server. You can add as much servers as necessary. The steps are similar for all platforms.

`1.` Enter the hostname or IP address of the Bluecherry server. The default login and password for new installations is `Admin` and `bluecherry`. You can optionally click `Use default` to have this information automatically entered for you.

![Connect to server](./screenshots/add_server/insert_credentials.png)

Click `Next` to connect.

`2.` You can optionally change some settings for the server, such as the streaming type, RTSP protocol, and rendering quality.

![Apply server settings](./screenshots/add_server/apply_server_settings.png)

You can optionally leave these as they are. Click `Finish` to add the server.

`3.` If the server was successfully added, you will be able to see the server in the server list and view the cameras.

![Server successfully added](./screenshots/add_server/server_added.png)

Click `Finish` to close the process.

## Viewing cameras

After your server is added, you will be redirected to the camera list. You can view the live video from the cameras by clicking on them or by dragging them to the layout.

![Drag and drop cameras](./screenshots/cameras/drag-to-add.gif)

You can repeat this process or any camera or DVR that you have listed on the left side. Note: It’s possible to connect as many devices together as you need, and mix and match the videos in different layouts.

## Open app from configuration file

You can open the app from a configuration file. This is useful for opening the app from a web browser or from a file manager. The configuration file is a `.bluecherry` file that contains the devices data.

Here is an example of a configuration file:

```
[stream]
video = rtsp://demo.bluecherry.app:7002/live/1

[videoscreen]
fullscreen = false

[audio]
sound = true
```

`*` The `stream` section contains the video URL. The app will try to connect to this URL when it is opened.

`*` The `videoscreen` section contains the fullscreen setting, which determines if the app should open in fullscreen mode or add the video to the layout.

`*` The `audio` section contains the sound setting, which determines if the stream should have sound or not.

You can open the app from the configuration file by double-clicking it and opening it with the Bluecherry Client.

Additionally, you can add overlays to the video by adding the following sections to the configuration file:

```
[overlay]
text = "This is overlay number threee"
size = 24
color = #000000
opacity = 80
show = true
position_x = 10
position_y = 30
```

`*` The `overlay` section contains the text, size, color, opacity, show, position_x, and position_y settings. The overlay is persistent and will be shown on top of the video.

The `position_x` and `position_y` determines the position of the overlay on the video, being `0` the top-left corner of the video.

The overlay can be edited from within the app:

![Edit overlay](./screenshots/cameras/stream_configuration_file.png)

Press `Finish` to add the stream to the layout.

## [beta] Matrix zoom

The matrix view is a feature that allows you to zoom into a camera. This is useful for multicast streams. This works better with cameras with larger resolutions.

To enable it, go to `Settings` -> `Updates` -> `Beta Features` -> `Matrix view zoom`.

![Matrix view](./screenshots/cameras/matrix-zoom.gif)

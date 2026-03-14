<div align="center">
  <img src="https://avatars.githubusercontent.com/u/618428?s=200&v=4" width="20%" height="20%" />
  <h1><a href="https://www.bluecherrydvr.com/">Bluecherry Client</a></h1>
  <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" />
  <img src="https://img.shields.io/github/downloads/bluecherrydvr/unity/total.svg" />
  <img src="https://github.com/bluecherrydvr/unity/actions/workflows/main.yml/badge.svg" />

  <br/>
  <b text-align="center"> Bluecherry DVR client to run across range of devices.</b>
  <br/>

<a href="https://www.bluecherrydvr.com/">Website</a> •
<a href="https://www.bluecherrydvr.com/product/v3license/">Purchase</a> •
<a href="https://www.bluecherrydvr.com/chat/">Chat</a>

</div>

## Features

- 🖲️ Ability to add multiple [Bluecherry DVR servers](https://www.bluecherrydvr.com/downloads/).
- 📺 Play any stream or recording from the web.
- 🎛️ Interactive camera grid viewer, with support for multiple layouts:
  <br /> $~~~~$
  💻 For larger screens, compact and multiple layout views are available.
  <br /> $~~~~~$📱 For smaller screens, see multiple cameras in 2x3, 2x2, 2x1 or 1x1 view
  <br /> $~~~~~$👆 Re-orgderable drag-and-drop camera viewer
  <br /> $~~~~~$🛞 Cycle through different layout views automatically
- 🔎 Pinch-to-zoom fullscreen camera viewer
- 📹 Multicast streams support
- 🏃 Events List Viewer
- 🚡 Events Timeline Viewer
- 🎮 **P**an-**T**ilt-**Z**oom controls for supported cameras.
- 🌓 Light & dark app theme
- 📰 System camera event notifications
- 📺 Adaptive and responsive design for larger screens
- 📱 Cross-platform
- 📦 Automatic updates

## Download

| Android                                                                                                                            | iOS                                                                       | Windows                                                                                                              | GNU/Linux                                                                                                                         | MacOS                                                                     |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [arm64 `.apk`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-android-arm64-v8a-release.apk)    | [App Store](https://apps.apple.com/us/app/bluecherry-mobile/id1555805139) | [Windows Setup](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-windows-setup.exe) | [SnapStore](https://snapcraft.io/bluecherry-client)                                                                               | [App Store](https://apps.apple.com/us/app/bluecherry-mobile/id6474160553) |
| [armabi `.apk`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-android-armeabi-v7a-release.apk) |                                                                           | 🚧 **SOON** ~~`winget install bluecherry`~~                                                                          | [Ubuntu/Debian `.deb`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-linux-x86_64.deb)        |                                                                           |
| [x86_64 `.apk`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-android-x86_64-release.apk)      |                                                                           | 🚧 **SOON** ~~Microsoft Store~~                                                                                      | [Raw Executable `.tar.gz`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-linux-x86_64.tar.gz) |                                                                           |
| 🚧 **SOON** ~~Play Store~~                                                                                                         |                                                                           |                                                                                                                      | [Fedora/Red Hat Linux `.rpm`](https://github.com/bluecherrydvr/unity/releases/download/v3.0.0-beta24/bluecherry-linux-x86_64.rpm) |                                                                           |

Or download the latest release [here](https://github.com/bluecherrydvr/unity/releases/tag/bleeding_edge)\*.

### Installation

Most platforms will not require any extra steps to install the app.

#### Android

Download the APK file and install it. You may need to enable installation from unknown sources in your settings.

#### Windows

Download the installer and run it. The app will be installed in the `Program Files` directory.

#### Linux

To install the `.deb` file, download it and run:

```bash
sudo apt install ./bluecherry-linux-x86_64.deb
```

The `libsecret-1-0` and `libjsoncpp-dev` libraries are required. If asked, install them.

## Usage

Refer to [USAGE.md](./USAGE.md) for detailed usage instructions.

## License

[![](https://camo.githubusercontent.com/317e8956b95d7cd7ebdc2a75b836f19dee3c1ae5fa0fce5b277338e648880d4f/68747470733a2f2f7777772e676e752e6f72672f67726170686963732f67706c76332d3132377835312e706e67)](https://www.gnu.org/licenses/gpl-3.0.en.html)

Copyright © 2022, [Bluecherry DVR](https://www.bluecherrydvr.com/).

This project & work under this repository is licensed under [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Bug-Reports

Send us details about any issues you discover [in the issues](https://github.com/bluecherrydvr/unity/issues) or [in the forums](https://forums.bluecherrydvr.com/).

## Contribute

### Translate

You may provide translations for the application to see it running in your own language. Please follow these steps:

Let's say, we're adding French (`fr`) translation.

1. Fork the repository & navigate [here](https://github.com/bluecherrydvr/unity/tree/main/lib/l10n).
2. Create a new file named `app_fr.arb`.
3. Add your translations to your new `app_fr.arb` file in correspondence to existing [English translations](https://github.com/bluecherrydvr/unity/tree/main/lib/l10n/app_en.arb).
4. Send us a new pull-request. 🎉

When adding new strings, run `bin/l10n_organizer.dart`. This script will ensure that the new strings are added to all l10n files and that they are in the same location. It will also remove any unused strings. The base file is `app_en.arb`, so all strings must be added there first.

Note that the app is constantly changing and new strings are added all the time. The translations need to be updated constantly.

### Technical Details

The code uses [Provider](https://github.com/rrousselGit/provider) for state-management because it is widely known by Flutter community, doesn't bring any unnecessary complexity to the codebase & is scalable/stable enough.

Most `ChangeNotifier`s are available as singletons, though de-coupled from each other. This is important to handle things like loading app configuration before `runApp`, handling background notification button actions & few other asynchronous operations performed outside the widget tree. By having singletons, we are able to avoid a strict dependency on the `BuildContext` & do certain things in a more performant way.

Current source tree has following files:

```
lib
│
├───api                                                [API wrapper around Bluecherry DVR server.]
│   └──api.dart
│   └──ptz.dart  [API related to Pan-Tilt-Zoom controls]
│
├───l10n [Tranlations]
│
├───models                                             [model classes to serve & bind type-safe data together in various entities.]
│   ├───device.dart
│   ├───event.dart
│   ├───layout.dart
│   └───server.dart
│
├───providers                                          [core business logic of the application.]
│   ├───desktop_view_provider.dart                     [stores, provides & caches desktop camera layout]
│   ├───downloads_provider.dart                        [manages events downloading and progress]
│   ├───events_playback_provider.dart                  [caches data about the events playback view]
│   ├───home_provider.dart                             [stores, provides & caches data about the home page]
│   ├───mobile_view_provider.dart                      [stores, provides & caches mobile camera layout etc.]
│   ├───server_provider.dart                           [stores, provides & caches multiple DVR servers added by the user.]
│   └───settings_provider.dart                         [stores, provides & caches various in-app configurations & settings.]
│   └───update_provider.dart                           [manages app updates and app status.]
│
├───utils                                              [constant values, helper functions & theme-related stuff.]
│   ├───constants.dart
│   ├───extensions.dart
│   ├───methods.dart
│   ├───storage.dart
│   ├───theme.dart
│   ├───video_player.dart
│   └───window.dart
│
├───screens                                            [All the screens of the application.]
│
├───widgets                                            [UI/UX & widgets used to display content.]
│
├───firebase_messaging_background_handler.dart         [handles in-app notifications, snoozing, thumbnails etc. & other Firebase related hooks.]
├───firebase_options.dart                              [auto-generated firebase configuration.]
└───main.dart                                          [entry-point of the application.]

packages
│
├───unity_multi_window                                 [multi-window support for desktop platforms.]
│
├───unity_video_player
│   ├───unity_video_player                             [the core video player logic.]
│   ├───unity_video_player_flutter                     [video player used as fallback, used on embedded platforms.]
│   ├───unity_video_player_main                        [main video player logic, used on most platforms.]
│   ├───unity_video_player_platform_interface          [the platform interface for the video player.]
│   └───unity_video_player_web                         [web specific video player logic, used on web.]
```

Feel free to send any pull-requests to add any features you wish or fix any bugs you notice.

### Video Rendering

We support multiple platforms and each platform uses its own rendering backend.

| Platform     | Rendering Backend | Flutter Package |
| ------------ | ----------------- | --------------- |
| Android      | MPV               | media_kit       |
| iOS          | MPV               | media_kit       |
| Windows      | MDK               | fvp             |
| MacOS        | MDK               | fvp             |
| Web          | HTML5             | media_kit       |
| Linux        | MDK               | fvp             |
| Raspberry Pi | MDK               | fvp             |

MDK is used for Desktop platforms because MPV has shown to be unstable on these platforms, causing crashes. Additionally, `fvp` doesn't require the user to install any additional dependencies on Linux and Raspberry Pi.

### Build

The build process is pretty straight-forward. You need to have [Flutter](https://flutter.dev/docs/get-started/install) installed on your system.

```bash
git clone https://github.com/bluecherrydvr/unity
cd unity
flutter pub get
flutter build [linux|windows|macos|android|ios]
```

The automated build process is done using GitHub Actions. You may find the workflow [here](.github/workflows/main.yml). The workflow builds the app for all supported platforms & uploads the artifacts to the release page.

#### Linux

On Linux, a Flutter executable with different environment variables is used to build the app for different distributions. This tells the app how the system is configured and how it should install updates. To run for Linux, you need to provide the following environment variables based on your system, where `[DISTRO_ENV]` can be `appimage` (AppImage), `deb` (Ubuntu/Debian), `rpm` (RedHat), `tar.gz` (Tarball) or `pi` (Raspberry Pi).

```bash
flutter run -d linux --dart-define-from-file=linux/env/[DISTRO_ENV].json
```

#### Linux Snapcraft

To build the Snapcraft, follow the instructions [here](https://docs.flutter.dev/deployment/linux)

```bash
sudo snap install snapcraft --classic
sudo snap install lxd
sudo lxd init
snapcraft
```

#### Web

When running on debug, you must disable the CORS policy in your browser. Note that this is only for debugging purposes and should not be used in production. To do this, run the following command:

```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Running and debugging

If running on a desktop platform, it is possible to emulate a mobile platform by passing the `--dart-define="FORCE_MOBILE=true"` argument when running. This will force the app to adapt itself to the mobile layout. This will remove any desktop-specific features and will make the app look like a mobile app.

```bash
flutter run -d [windows|linux|macos] --dart-define="FORCE_MOBILE=true"
```
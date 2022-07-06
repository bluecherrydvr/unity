<img align="left" src="https://avatars.githubusercontent.com/u/618428?s=200&v=4" width="72" height="72"></img>

<h1 align="left"><a href="https://www.bluecherrydvr.com/">Bluecherry Client</a></h1>

**Bluecherry DVR client to run across range of devices.**

<a href="https://www.bluecherrydvr.com/">Website</a> •
<a href="https://www.bluecherrydvr.com/product/v3license/">Purchase</a> •
<a href="https://www.bluecherrydvr.com/chat/">Chat</a>

[work-in-progress]

## Download

<!-- TODO: Add links. -->

- [iOS](#)
- [Android](#)

## Screenshots

<table>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177609508-3af6c12b-4579-4c05-813b-6607973ab665.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177609575-fde660f3-ab03-4d8a-bfd7-a97542e4ed8c.jpg"></img>
    </td>
  </tr>
</table>
<table>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177609733-07d7fdd2-24bb-4977-98b4-8d04d4425950.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177609754-0f993bd7-bf11-43ba-8d88-5c25cf6c4a01.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177609742-57d93982-8b85-4ea8-b172-9f131a701459.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177610286-43e8b910-a44c-40f8-a773-4f7752fa360d.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177610405-7b528cb2-e24d-4fda-85c9-b68cfd2bb0cc.jpg"></img>
    </td>
  </tr>
</table>
<table>
  <tr>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177611699-21f16db0-04a6-4fd4-a1d9-e961dce3f40e.jpg"></img>
    </td>
    <td>
      <img src="https://user-images.githubusercontent.com/28951144/177611704-0c79353e-f8fe-43b5-b63d-188d25325df2.jpg"></img>
    </td>
  </tr>
</table>

## Features

- Ability to add multiple [Bluecherry DVR servers](https://www.bluecherrydvr.com/downloads/).
- Re-orderable drag-and-drop camera grid viewer. See multiple cameras in 4x4, 2x1 or 1x1 view.
- Pinch-to-zoom fullscreen camera viewer.
- Events viewer.
- Direct camera viewer.
- Consistent & configurable system-aware, light & dark app theme.
- Configurable in-app date & time format.
- Event notifications with camera screenshot thumbnail. View any camera or event directly by single notifcation tap.
- Ability to snooze notifications directly from notification or within the app.
- Cross-platform. Currently targets mobile platforms. Desktop support coming in future.
  - [x] Android
  - [ ] iOS ([_coming soon_](https://github.com/bluecherrydvr/unity/issues/5))
  - [ ] Windows
  - [ ] Linux
  - [ ] macOS

## Videos

_[demo data & footage is shown]_

https://user-images.githubusercontent.com/28951144/177617726-8a08d71b-7830-4628-823a-1a039ed48cd8.mp4

https://user-images.githubusercontent.com/28951144/177617785-fa81d120-6eac-44b1-bf92-ddbc32451d39.mp4

## Translate

You may provide translations for the application to see it running in your own language. Please follow these steps:

Let's say, we're adding French (`fr-FR`) translation.

1. Fork the repository & navigate [here](https://github.com/bluecherrydvr/unity/tree/main/assets/translations).
2. Create a new file named `fr-FR.json`.
3. Add your translations to your new `fr-FR.json` file in correspondence to existing [en-US translations](https://github.com/bluecherrydvr/unity/blob/main/assets/translations/en-US.json).
4. Add your language [here](https://github.com/bluecherrydvr/unity/blob/fce2aad3213298f70e91eb549a71699826e5c6e4/lib/utils/constants.dart#L26). Example:

```diff
  const kSupportedLocales = [
    Locale('en', 'US'),
+   Locale('fr', 'FR'),
  ];
```

4. Send us a new pull-request. 🎉

**NOTE:** Do not translate the value of `tip_count`.

## Bug-Reports

Send us details about any issues you discover [in the issues](https://github.com/bluecherrydvr/unity/issues) or [in the forums](https://forums.bluecherrydvr.com/).

## Contribute

The code _in-general_ follows OOPs & uses [provider](https://github.com/rrousselGit/provider) for state-management because it is widely known by developers in Flutter community.
Everything is well-documented (e.g. [this](https://github.com/bluecherrydvr/unity/blob/fce2aad3213298f70e91eb549a71699826e5c6e4/lib/providers/mobile_view_provider.dart#L28-L35)) & other little quirks/tweaks at places are also noted.

Current source tree has following files:

```
lib
|
├───api                                                [API wrapper around Bluecherry DVR server.]
|   └──api.dart
│
├───models                                             [model classes to serve & bind type-safe data together in various entities.]
│   ├───device.dart
│   ├───event.dart
│   └───server.dart
│
├───providers                                          [core business logic of the application.]
│   ├───mobile_view_provider.dart                      [stores, provides & caches mobile camera layout etc.]
│   ├───server_provider.dart                           [stores, provides & caches multiple DVR servers added by the user.]
│   └───settings_provider.dart                         [stores, provides & caches various in-app configurations & settings.]
│
├───utils                                              [constant values, helper functions & theme-related stuff.]
│   ├───constants.dart
│   ├───methods.dart
│   └───theme.dart
│
├───widgets                                            [UI/UX & widgets used to display content.]
│   ├───add_server_wizard.dart
│   ├───device_grid.dart
│   ├───device_selector_screen.dart
│   ├───device_tile.dart
│   ├───device_tile_selector.dart
│   ├───direct_camera.dart
│   ├───events_screen.dart
│   ├───home.dart
│   ├───misc.dart
│   └───settings.dart
│
├───firebase_messaging_background_handler.dart         [handles in-app notifications, snoozing, thumbnails etc. & other Firebase related hooks.]
├───firebase_options.dart                              [auto-generated firebase configuration.]
└───main.dart                                          [entry-point of the application.]

```

Feel free to send any pull-requests to add any features you wish or fix any bugs you notice.

## License 

[![](https://camo.githubusercontent.com/317e8956b95d7cd7ebdc2a75b836f19dee3c1ae5fa0fce5b277338e648880d4f/68747470733a2f2f7777772e676e752e6f72672f67726170686963732f67706c76332d3132377835312e706e67)](https://www.gnu.org/licenses/gpl-3.0.en.html)

Copyright © 2022, [Bluecherry DVR](https://www.bluecherrydvr.com/).

This project & work under this repository is licensed under [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

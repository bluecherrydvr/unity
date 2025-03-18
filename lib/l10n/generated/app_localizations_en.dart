// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Welcome';

  @override
  String get welcomeDescription => 'Welcome to the Bluecherry Surveillance DVR!\nLet\'s connect to your DVR server quickly.';

  @override
  String get configure => 'Configure a DVR Server';

  @override
  String get configureDescription => 'Setup a connection to your remote DVR server. You can connect to any number of servers from anywhere in the world.';

  @override
  String get hostname => 'Hostname';

  @override
  String get hostnameExample => 'demo.bluecherry.app';

  @override
  String get port => 'Port';

  @override
  String get rtspPort => 'RTSP Port';

  @override
  String get serverName => 'Server Name';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Admin';

  @override
  String get password => 'Password';

  @override
  String get savePassword => 'Save password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get useDefault => 'Use Default';

  @override
  String get connect => 'Connect';

  @override
  String get connectAutomaticallyAtStartup => 'Connect automatically at startup';

  @override
  String get connectAutomaticallyAtStartupDescription => 'If enabled, the server will be automatically connected when the app starts.';

  @override
  String get checkingServerCredentials => 'Checking server credentials';

  @override
  String get skip => 'Skip';

  @override
  String get cancel => 'Cancel';

  @override
  String get disabled => 'Disabled';

  @override
  String get letsGo => 'Let\'s Go!';

  @override
  String get finish => 'Finish';

  @override
  String get letsGoDescription => 'Here\'s some tips on how to get started:';

  @override
  String get projectName => 'Bluecherry';

  @override
  String get projectDescription => 'Powerful Video Surveillance Software';

  @override
  String get website => 'Website';

  @override
  String get purchase => 'Purchase';

  @override
  String get tip0 => 'Cameras are shown on left. You can double-click or drag the camera into the live area to view it.';

  @override
  String get tip1 => 'Use the buttons above the live view to create, save and switch layouts - even with cameras from multiple servers.';

  @override
  String get tip2 => 'Double-click on a server to open its configuration page in a new window, where you can configure cameras and recordings.';

  @override
  String get tip3 => 'Click the events icon to open the history and watch or save recordings.';

  @override
  String errorTextField(String field) {
    return '$field must not be empty.';
  }

  @override
  String get serverAdded => 'Server has been added';

  @override
  String serverNotAddedError(String serverName) {
    return '$serverName could not be added.';
  }

  @override
  String serverNotAddedErrorDescription(String port, String rtspPort) {
    return 'Please check the entered details and ensure the server is online.\n\nIf you are connecting remote, make sure the $port and $rtspPort ports are open to the Bluecherry server!';
  }

  @override
  String serverAlreadyAdded(String serverName) {
    return 'The $serverName server is already added.';
  }

  @override
  String get serverVersionMismatch => 'Tried to add a server with an unsupported version. Please upgrade your server and try again!';

  @override
  String get serverVersionMismatchShort => 'Unsupported server version';

  @override
  String get serverWrongCredentials => 'The credentials for the server are wrong. Please check the username and password and try again.';

  @override
  String get serverWrongCredentialsShort => 'Wrong credentials. Please check the username and password.';

  @override
  String get noServersAvailable => 'No servers available';

  @override
  String get error => 'Error';

  @override
  String get videoError => 'An error happened while trying to play the video.';

  @override
  String copiedToClipboard(String message) {
    return 'Copied $message to clipboard';
  }

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get serverSettings => 'Server settings';

  @override
  String get serverSettingsDescription => 'Settings that will only be applied to this server. If they are not provided, the values from General Settings will be used. You can change these values later.';

  @override
  String get editServerSettingsInfo => 'Edit server settings';

  @override
  String editServerSettings(String serverName) {
    return 'Edit server settings $serverName';
  }

  @override
  String get removeCamera => 'Remove Camera';

  @override
  String get removePlayer => 'Remove all devices attached to this player';

  @override
  String get replaceCamera => 'Replace Camera';

  @override
  String get reloadCamera => 'Reload Camera';

  @override
  String get selectACamera => 'Select a camera';

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get status => 'Status';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get live => 'LIVE';

  @override
  String get timedOut => 'TIMED OUT';

  @override
  String get loading => 'LOADING';

  @override
  String get recorded => 'RECORDED';

  @override
  String get late => 'LATE';

  @override
  String get removeFromView => 'Remove from view';

  @override
  String get addToView => 'Add to view';

  @override
  String get addAllToView => 'Add all to view';

  @override
  String get removeAllFromView => 'Remove all from view';

  @override
  String get streamName => 'Stream name';

  @override
  String get streamNameRequired => 'The stream name is required';

  @override
  String get streamURL => 'Stream URL';

  @override
  String get streamURLRequired => 'The stream URL is required';

  @override
  String get streamURLNotValid => 'The stream URL is not valid';

  @override
  String get uri => 'URI';

  @override
  String get oldestRecording => 'Oldest recording';

  @override
  String get eventBrowser => 'Events History';

  @override
  String get eventsTimeline => 'Timeline of Events';

  @override
  String get server => 'Server';

  @override
  String get device => 'Device';

  @override
  String get viewDeviceDetails => 'View device details';

  @override
  String get event => 'Event';

  @override
  String get duration => 'Duration';

  @override
  String get priority => 'Priority';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get lastImageUpdate => 'Last Image Update';

  @override
  String get fps => 'FPS';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get lastUpdate => 'Last Update';

  @override
  String screens(String layout) {
    return 'Screens • $layout';
  }

  @override
  String get directCamera => 'Direct Camera';

  @override
  String get addServer => 'Add Server';

  @override
  String get settings => 'Settings';

  @override
  String get noServersAdded => 'You haven\'t added any servers yet :/';

  @override
  String get howToAddServer => 'Go to the \"Add Server\" tab to add a server.';

  @override
  String get editServerInfo => 'Edit server info';

  @override
  String editServer(String serverName) {
    return 'Edit server $serverName';
  }

  @override
  String get servers => 'Servers';

  @override
  String nServers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n servers',
      one: '1 server',
      zero: 'No servers',
    );
    return '$_temp0';
  }

  @override
  String nDevices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n devices',
      one: '1 device',
      zero: 'No devices',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Remove ?';

  @override
  String removeServerDescription(String serverName) {
    return '$serverName will be removed from the application. You\'ll not be able to view cameras from this server & will no longer receive notifications.';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get about => 'About';

  @override
  String get versionText => 'Copyright © 2022, Bluecherry LLC.\nAll rights reserved.';

  @override
  String get gettingDevices => 'Getting devices';

  @override
  String get noDevices => 'No devices';

  @override
  String get noEventsLoaded => 'NO EVENTS LOADED';

  @override
  String get noEventsLoadedTips => '•  Select the cameras you want to see the events\n•  Use the calendar to select a specific date or a date range \n•  Use the \"Filter\" button to perform the search';

  @override
  String get timelineKeyboardShortcutsTips => '•  Use the space bar to play/pause the timeline\n•  Use the left and right arrow keys to move the timeline\n•  Use the M key to mute/unmute the timeline\n•  Use the mouse wheel to zoom in/out the timeline';

  @override
  String get invalidResponse => 'Invalid response received from the server';

  @override
  String get cameraOptions => 'Options';

  @override
  String get showFullscreenCamera => 'Show in fullscreen';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get openInANewWindow => 'Open in a new window';

  @override
  String get enableAudio => 'Enable audio';

  @override
  String get disableAudio => 'Disable audio';

  @override
  String get addNewServer => 'Add new server';

  @override
  String get disconnectServer => 'Disconnect';

  @override
  String get serverOptions => 'Server options';

  @override
  String get browseEvents => 'Browse events';

  @override
  String get eventType => 'Event type';

  @override
  String get configureServer => 'Configure server';

  @override
  String get refreshDevices => 'Refresh devices';

  @override
  String get refreshServer => 'Refresh server';

  @override
  String get viewDevices => 'View devices';

  @override
  String serverDevices(String server) {
    return '$server devices';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get view => 'View';

  @override
  String get cycle => 'Cycle';

  @override
  String fallbackLayoutName(int layout) {
    return 'Layout $layout';
  }

  @override
  String get newLayout => 'New layout';

  @override
  String get editLayout => 'Edit layout';

  @override
  String editSpecificLayout(String layoutName) {
    return 'Edit $layoutName';
  }

  @override
  String get exportLayout => 'Export layout';

  @override
  String get importLayout => 'Import layout';

  @override
  String failedToImportMessage(String layoutName, String server_ip, int server_port) {
    return 'While attempting to import $layoutName, we found a device that is connected to a server you are not connected to. Please, connect to the server and try again.\nServer: $server_ip:$server_port';
  }

  @override
  String get layoutImportFileCorrupted => 'The file you attempted to import is corrupted or missing information.';

  @override
  String layoutImportFileCorruptedWithMessage(Object message) {
    return 'The file you attempted to import is corrupted or missing information: \"$message\"';
  }

  @override
  String get singleView => 'Single view';

  @override
  String get multipleView => 'Multiple view';

  @override
  String get compactView => 'Compact view';

  @override
  String get createNewLayout => 'Create new layout';

  @override
  String get layoutName => 'Layout name';

  @override
  String get layoutNameHint => 'First floor';

  @override
  String get layoutTypeLabel => 'Layout type';

  @override
  String clearLayout(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'devices',
      one: 'device',
    );
    return 'Remove $amount $_temp0';
  }

  @override
  String get switchToNext => 'Switch to next';

  @override
  String get unlockLayout => 'Unlock layout';

  @override
  String get lockLayout => 'Lock layout';

  @override
  String layoutVolume(int volume) {
    return 'Layout Volume • $volume%';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get download => 'Download';

  @override
  String downloadN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n events',
      one: '1 event',
    );
    return 'Download $_temp0';
  }

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloading => 'Downloading';

  @override
  String get seeInDownloads => 'See in Downloads';

  @override
  String get downloadPath => 'Download directory';

  @override
  String get delete => 'Delete';

  @override
  String get showInFiles => 'Show in Files';

  @override
  String get noDownloads => 'You haven\'t downloaded anything yet :/';

  @override
  String nDownloadsProgress(int n) {
    return 'You have $n downloads in progress!';
  }

  @override
  String get howToDownload => 'Go to the \"Events History\" tab to download events.';

  @override
  String downloadTitle(String event, String device, String server, String date) {
    return '$event on $device ($server) at $date';
  }

  @override
  String get playbackOptions => 'PLAYBACK OPTIONS';

  @override
  String get play => 'Play';

  @override
  String get playing => 'Playing';

  @override
  String get pause => 'Pause';

  @override
  String get paused => 'Paused';

  @override
  String volume(String v) {
    return 'Volume • $v';
  }

  @override
  String speed(String s) {
    return 'Speed • $s';
  }

  @override
  String get noRecords => 'This camera has no records in the current period.';

  @override
  String get filter => 'Filter';

  @override
  String loadEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Load from $n devices',
      one: 'Load from 1 device',
      zero: 'Load',
    );
    return '$_temp0';
  }

  @override
  String get period => 'Period';

  @override
  String get dateTimeFilter => 'Date and Time Filter';

  @override
  String get dateFilter => 'Date Filter';

  @override
  String get timeFilter => 'Time Filter';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get never => 'Never';

  @override
  String fromToDate(String from, String to) {
    return '$from - $to';
  }

  @override
  String get mostRecent => 'Most recent';

  @override
  String get allowAlarms => 'Allow alarms';

  @override
  String get nextEvents => 'Next events';

  @override
  String nEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n events',
      one: '1 event',
      zero: 'No events',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Info';

  @override
  String get warn => 'Warning';

  @override
  String get alarm => 'Alarm';

  @override
  String get critical => 'Critical';

  @override
  String get motion => 'Motion';

  @override
  String get continuous => 'Continouous';

  @override
  String get notFound => 'Not found';

  @override
  String get cameraVideoLost => 'Video Lost';

  @override
  String get cameraAudioLost => 'Audio Lost';

  @override
  String get systemDiskSpace => 'Disk Space';

  @override
  String get systemCrash => 'Crash';

  @override
  String get systemBoot => 'Startup';

  @override
  String get systemShutdown => 'Shutdown';

  @override
  String get systemReboot => 'Reboot';

  @override
  String get systemPowerOutage => 'Power Lost';

  @override
  String get unknown => 'Unknown';

  @override
  String get close => 'Close';

  @override
  String get closeAnyway => 'Close anyway';

  @override
  String get closeWhenDone => 'Close when done';

  @override
  String get open => 'Open';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get more => 'More';

  @override
  String get isPtzSupported => 'Supports PTZ?';

  @override
  String get ptzSupported => 'PTZ is supported';

  @override
  String get enabledPTZ => 'PTZ is enabled';

  @override
  String get disabledPTZ => 'PTZ is disabled';

  @override
  String get move => 'Movement';

  @override
  String get stop => 'Stop';

  @override
  String get noMovement => 'No movement';

  @override
  String get moveNorth => 'Move up';

  @override
  String get moveSouth => 'Move down';

  @override
  String get moveWest => 'Move west';

  @override
  String get moveEast => 'Move east';

  @override
  String get moveWide => 'Zoom out';

  @override
  String get moveTele => 'Zoom in';

  @override
  String get presets => 'Presets';

  @override
  String get noPresets => 'No presets found';

  @override
  String get newPreset => 'New preset';

  @override
  String get goToPreset => 'Go to preset';

  @override
  String get renamePreset => 'Rename preset';

  @override
  String get deletePreset => 'Delete preset';

  @override
  String get refreshPresets => 'Refresh presets';

  @override
  String get resolution => 'Resolution';

  @override
  String get selectResolution => 'Select resolution';

  @override
  String get setResolution => 'Set resolution';

  @override
  String get setResolutionDescription => 'The resolution of the video stream can highly impact the performance of the app. Set the resolution to a lower value to improve performance, or to a higher value to improve quality. You can set the default resolution to every camera in the settings';

  @override
  String get hd => 'High definition';

  @override
  String get defaultResolution => 'Default resolution';

  @override
  String get automaticResolution => 'Automatic';

  @override
  String get p4k => '4K';

  @override
  String get p1080 => '1080p';

  @override
  String get p720 => '720p';

  @override
  String get p480 => '480p';

  @override
  String get p360 => '360p';

  @override
  String get p240 => '240p';

  @override
  String get updates => 'Updates';

  @override
  String get upToDate => 'You are up to date.';

  @override
  String lastChecked(String date) {
    return 'Last checked: $date';
  }

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking for updates';

  @override
  String get automaticDownloadUpdates => 'Automatic download updates';

  @override
  String get automaticDownloadUpdatesDescription => 'Be among the first to get the latest updates, fixes and improvements as they roll out.';

  @override
  String get updateHistory => 'Update history';

  @override
  String get showReleaseNotes => 'Show release notes';

  @override
  String get showReleaseNotesDescription => 'Display release notes when a new version is installed';

  @override
  String get newVersionAvailable => 'New version available';

  @override
  String get installVersion => 'Install';

  @override
  String get downloadVersion => 'Download';

  @override
  String get learnMore => 'Learn more';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get executableNotFound => 'Executable not found';

  @override
  String runningOn(String platform) {
    return 'Running on $platform';
  }

  @override
  String get windows => 'Windows';

  @override
  String linux(String env) {
    return 'Linux $env';
  }

  @override
  String get currentTasks => 'Current tasks';

  @override
  String get noCurrentTasks => 'No tasks';

  @override
  String get taskFetchingEvent => 'Fetching events';

  @override
  String get taskFetchingEventsPlayback => 'Fetching events playback';

  @override
  String get taskDownloadingEvent => 'Downloading event';

  @override
  String get defaultField => 'Default';

  @override
  String get general => 'General';

  @override
  String get generalSettingsSuggestion => 'Notifications, Data Usage, Wakelock, etc';

  @override
  String get serverAndDevices => 'Servers and Devices';

  @override
  String get serverAndDevicesSettingsSuggestion => 'Connect to servers, manage devices, etc';

  @override
  String get eventsAndDownloads => 'Events and Downloads';

  @override
  String get eventsAndDownloadsSettingsSuggestion => 'Events history, downloads, etc';

  @override
  String get application => 'Application';

  @override
  String get applicationSettingsSuggestion => 'Appearance, theme, date and time, etc';

  @override
  String get privacyAndSecurity => 'Privacy and Security';

  @override
  String get privacyAndSecuritySettingsSuggestion => 'Data collection, error reporting, etc';

  @override
  String get updatesHelpAndPrivacy => 'Updates, Help and Privacy';

  @override
  String get updatesHelpAndPrivacySettingsSuggestion => 'Check for updates, update history, privacy policy, etc';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get advancedOptionsSettingsSuggestion => 'Funcionalidades em Beta, Opções de Desenvolvedor, etc';

  @override
  String get cycleTogglePeriod => 'Layout cycle toggle period';

  @override
  String get cycleTogglePeriodDescription => 'The interval between layout changes when the cycle mode is enabled.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationClickBehavior => 'Notification Click Behavior';

  @override
  String get notificationClickBehaviorDescription => 'Choose what happens when you click on a notification.';

  @override
  String get showEventsScreen => 'Show events history';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get streamsOnBackground => 'Keep streams playing on background';

  @override
  String get streamsOnBackgroundDescription => 'When to keep streams playing when the app is in background';

  @override
  String get automatic => 'Automatic';

  @override
  String get wifiOnly => 'Wifi Only';

  @override
  String get chooseEveryDownloadsLocation => 'Choose the location for every download';

  @override
  String get chooseEveryDownloadsLocationDescription => 'Whether to choose the location for each download or use the default location. When enabled, you will be prompted to choose the download directory for each download.';

  @override
  String get allowCloseWhenDownloading => 'Allow closing the app when downloading';

  @override
  String get events => 'Events';

  @override
  String get initialEventSpeed => 'Initial event speed';

  @override
  String get initialEventVolume => 'Initial event volume';

  @override
  String get differentEventColors => 'Different events by colors';

  @override
  String get differentEventColorsDescription => 'Whether to show different colors for events in the timeline. This assists to easily differentiate the events.';

  @override
  String get initialTimelinePoint => 'Initial point';

  @override
  String get initialTimelinePointDescription => 'The initial point of the timeline.';

  @override
  String get beginningInitialPoint => 'Beginning';

  @override
  String get firstEventInitialPoint => 'First event';

  @override
  String get hourAgoInitialPoint => '1 hour ago';

  @override
  String get automaticallySkipEmptyPeriods => 'Automatically skip empty periods';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeDescription => 'Change the appearance of the app';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get dateAndTime => 'Date and Time';

  @override
  String get dateFormat => 'Date Format';

  @override
  String get dateFormatDescription => 'What format to use for displaying dates';

  @override
  String get timeFormat => 'Time Format';

  @override
  String get timeFormatDescription => 'What format to use for displaying time';

  @override
  String get convertToLocalTime => 'Convert dates to the local timezone';

  @override
  String get convertToLocalTimeDescription => 'This will affect the date and time displayed in the app. This is useful when you are in a different timezone than the server. When disabled, the server timezone will be used.';

  @override
  String get allowDataCollection => 'Allow Bluecherry to collect usage data';

  @override
  String get allowDataCollectionDescription => 'Allow Bluecherry to collect data to improve the app and provide better services. Data is collected anonymously and does not contain any personal information.';

  @override
  String get automaticallyReportErrors => 'Automatically report errors';

  @override
  String get automaticallyReportErrorsDescription => 'Automatically send error reports to Bluecherry to help improve the app. Error reports may contain personal information.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get matrixMagnification => 'Area Magnification';

  @override
  String get matrixedViewMagnification => 'Area Magnification enabled';

  @override
  String get matrixedViewMagnificationDescription => 'Magnify a area of the matrix view when selected. This is useful when you have a lot of cameras and want to see a specific area in more detail, or when a multicast stream is provided.';

  @override
  String get matrixType => 'Matrix type';

  @override
  String get defaultMatrixSize => 'Default Magnification Proportion';

  @override
  String get softwareMagnification => 'Software Magnification';

  @override
  String get softwareMagnificationDescription => 'When enabled, the magnification will not happen in the GPU. This is useful when the hardware magnification is not working properly.';

  @override
  String get softwareMagnificationDescriptionMacOS => 'When enabled, the magnification will not happen in the GPU. This is useful when the hardware magnification is not working properly. On macOS, this can not be disabled.';

  @override
  String get eventMagnification => 'Event Magnification';

  @override
  String get eventMagnificationDescription => 'Magnify the event video when selected. This is useful when you want to see the event in more detail.';

  @override
  String get developerOptions => 'Developer options';

  @override
  String get openLogFile => 'Open log file';

  @override
  String get openAppDataDirectory => 'Open app data directory';

  @override
  String get importConfigFile => 'Import configuration file';

  @override
  String get importConfigFileDescription => 'Import a .bluecherry configuration file that contains streaming information.';

  @override
  String get debugInfo => 'Debug info';

  @override
  String get debugInfoDescription => 'Display useful information for debugging, such as video metadata and other useful information for debugging purposes.';

  @override
  String get restoreDefaults => 'Restore Defaults';

  @override
  String get restoreDefaultsDescription => 'Restore all settings to their default values. This will not affect the servers you have added.';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get areYouSureDescription => 'This will restore all settings to their default values. This will not affect your servers or any other data.';

  @override
  String get miscellaneous => 'Miscellaneous';

  @override
  String get wakelock => 'Keep screen awake';

  @override
  String get wakelockDescription => 'Keep screen awake while watching live streams or recordings.';

  @override
  String get snooze15 => '15 minutes';

  @override
  String get snooze30 => '30 minutes';

  @override
  String get snooze60 => '1 hour';

  @override
  String get snoozeNotifications => 'Snooze Notifications';

  @override
  String get notSnoozed => 'Not snoozing';

  @override
  String get snoozeNotificationsUntil => 'Snooze notifications until';

  @override
  String snoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get connectToServerAutomaticallyAtStartup => 'Connect automatically at startup';

  @override
  String get connectToServerAutomaticallyAtStartupDescription => 'If enabled, the server will be automatically connected when the app starts. This only applies to the new servers you add.';

  @override
  String get allowUntrustedCertificates => 'Allow untrusted certificates';

  @override
  String get allowUntrustedCertificatesDescription => 'Allow connecting to servers with untrusted certificates. This is useful when you are using self-signed certificates or certificates from unknown authorities.';

  @override
  String get certificateNotPassed => 'Certificate not passed';

  @override
  String get addServerTimeout => 'Add server timeout';

  @override
  String get addServerTimeoutDescription => 'The time to wait for the server to respond when adding a new server.';

  @override
  String get streamingSettings => 'Streaming settings';

  @override
  String get streamingProtocol => 'Streaming Protocol';

  @override
  String get preferredStreamingProtocol => 'Preferred Streaming Protocol';

  @override
  String get preferredStreamingProtocolDescription => 'What video streaming protocol will be used. If the server does not support the selected protocol, the app will try to use the next one. It is possible to select a specific protocol for each device in its settings.';

  @override
  String get rtspProtocol => 'RTSP Protocol';

  @override
  String get camerasSettings => 'Cameras settings';

  @override
  String get renderingQuality => 'Rendering quality';

  @override
  String get renderingQualityDescription => 'The quality of the video rendering. The higher the quality, the more rendering resources it takes. It is recommended to use high quality when a GPU is installed. When set to automatic, the quality is selected based on the camera resolution.';

  @override
  String get cameraViewFit => 'Camera Image Fit';

  @override
  String get cameraViewFitDescription => 'The way the video is displayed in the view.';

  @override
  String get contain => 'Contain';

  @override
  String get fill => 'Fill';

  @override
  String get cover => 'Cover';

  @override
  String get streamRefreshPeriod => 'Stream Refresh Period';

  @override
  String get streamRefreshPeriodDescription => 'The interval between device refreshes. It ensures the camera video is still valid from time to time.';

  @override
  String get lateStreamBehavior => 'Late stream behavior';

  @override
  String get lateStreamBehaviorDescription => 'What to do when a stream is late';

  @override
  String get automaticBehavior => 'Automatic';

  @override
  String get automaticBehaviorDescription => 'The app will try to reposition the stream automatically';

  @override
  String get manualBehavior => 'Manual';

  @override
  String manualBehaviorDescription(String label) {
    return 'Press $label to reposition the stream';
  }

  @override
  String get neverBehaviorDescription => 'The app will not try to reposition the stream';

  @override
  String get devicesSettings => 'Devices Settings';

  @override
  String get listOfflineDevices => 'List Offline Devices';

  @override
  String get listOfflineDevicesDescriptions => 'Whether to show offline devices in the devices list.';

  @override
  String get initialDeviceVolume => 'Initial Camera Volume';

  @override
  String get runVideoTest => 'Run Video Test';

  @override
  String get runVideoTestDescription => 'Run a video test to check the state of video playback.';

  @override
  String get showCameraName => 'Show Camera Name';

  @override
  String get always => 'Always';

  @override
  String get onHover => 'On hover';

  @override
  String get dateLanguage => 'Date and Language';

  @override
  String get language => 'Language';

  @override
  String get overlays => 'Overlays';

  @override
  String get visible => 'Visible';

  @override
  String nOverlay(int n) {
    return 'Overlay $n';
  }

  @override
  String overlayPosition(double x, double y) {
    return 'Position (x: $x, y: $y)';
  }

  @override
  String get externalStream => 'External stream';

  @override
  String get addExternalStream => 'Add external stream';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get serverHostname => 'Server hostname';

  @override
  String get serverHostnameExample => 'https://my-server.bluecherry.app:7001';

  @override
  String get rackName => 'Rack name';

  @override
  String get rackNameExample => 'Lab 1';

  @override
  String get openServer => 'Open server';

  @override
  String get disableSearch => 'Disable search';

  @override
  String get help => 'Help';

  @override
  String get licenses => 'Licenses';
}

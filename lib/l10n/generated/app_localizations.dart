import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('pl'),
    Locale('pt'),
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Bluecherry Surveillance DVR!\nLet\'s connect to your DVR server quickly.'**
  String get welcomeDescription;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure a DVR Server'**
  String get configure;

  /// No description provided for @configureDescription.
  ///
  /// In en, this message translates to:
  /// **'Setup a connection to your remote DVR server. You can connect to any number of servers from anywhere in the world.'**
  String get configureDescription;

  /// No description provided for @hostname.
  ///
  /// In en, this message translates to:
  /// **'Hostname'**
  String get hostname;

  /// No description provided for @hostnameExample.
  ///
  /// In en, this message translates to:
  /// **'demo.bluecherry.app'**
  String get hostnameExample;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @rtspPort.
  ///
  /// In en, this message translates to:
  /// **'RTSP Port'**
  String get rtspPort;

  /// No description provided for @serverName.
  ///
  /// In en, this message translates to:
  /// **'Server Name'**
  String get serverName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get usernameHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @useDefault.
  ///
  /// In en, this message translates to:
  /// **'Use Default'**
  String get useDefault;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectAutomaticallyAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically at startup'**
  String get connectAutomaticallyAtStartup;

  /// No description provided for @connectAutomaticallyAtStartupDescription.
  ///
  /// In en, this message translates to:
  /// **'If enabled, the server will be automatically connected when the app starts.'**
  String get connectAutomaticallyAtStartupDescription;

  /// No description provided for @checkingServerCredentials.
  ///
  /// In en, this message translates to:
  /// **'Checking server credentials'**
  String get checkingServerCredentials;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get letsGo;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @letsGoDescription.
  ///
  /// In en, this message translates to:
  /// **'Here\'s some tips on how to get started:'**
  String get letsGoDescription;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Bluecherry'**
  String get projectName;

  /// No description provided for @projectDescription.
  ///
  /// In en, this message translates to:
  /// **'Powerful Video Surveillance Software'**
  String get projectDescription;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @tip0.
  ///
  /// In en, this message translates to:
  /// **'Cameras are shown on left. You can double-click or drag the camera into the live area to view it.'**
  String get tip0;

  /// No description provided for @tip1.
  ///
  /// In en, this message translates to:
  /// **'Use the buttons above the live view to create, save and switch layouts - even with cameras from multiple servers.'**
  String get tip1;

  /// No description provided for @tip2.
  ///
  /// In en, this message translates to:
  /// **'Double-click on a server to open its configuration page in a new window, where you can configure cameras and recordings.'**
  String get tip2;

  /// No description provided for @tip3.
  ///
  /// In en, this message translates to:
  /// **'Click the events icon to open the history and watch or save recordings.'**
  String get tip3;

  /// No description provided for @errorTextField.
  ///
  /// In en, this message translates to:
  /// **'{field} must not be empty.'**
  String errorTextField(String field);

  /// No description provided for @serverAdded.
  ///
  /// In en, this message translates to:
  /// **'Server has been added'**
  String get serverAdded;

  /// No description provided for @serverNotAddedError.
  ///
  /// In en, this message translates to:
  /// **'{serverName} could not be added.'**
  String serverNotAddedError(String serverName);

  /// No description provided for @serverNotAddedErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Please check the entered details and ensure the server is online.\n\nIf you are connecting remote, make sure the {port} and {rtspPort} ports are open to the Bluecherry server!'**
  String serverNotAddedErrorDescription(String port, String rtspPort);

  /// No description provided for @serverAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'The {serverName} server is already added.'**
  String serverAlreadyAdded(String serverName);

  /// No description provided for @serverVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'Tried to add a server with an unsupported version. Please upgrade your server and try again!'**
  String get serverVersionMismatch;

  /// No description provided for @serverVersionMismatchShort.
  ///
  /// In en, this message translates to:
  /// **'Unsupported server version'**
  String get serverVersionMismatchShort;

  /// No description provided for @serverWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'The credentials for the server are wrong. Please check the username and password and try again.'**
  String get serverWrongCredentials;

  /// No description provided for @serverWrongCredentialsShort.
  ///
  /// In en, this message translates to:
  /// **'Wrong credentials. Please check the username and password.'**
  String get serverWrongCredentialsShort;

  /// No description provided for @noServersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No servers available'**
  String get noServersAvailable;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @videoError.
  ///
  /// In en, this message translates to:
  /// **'An error happened while trying to play the video.'**
  String get videoError;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied {message} to clipboard'**
  String copiedToClipboard(String message);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @serverSettings.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get serverSettings;

  /// No description provided for @serverSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Settings that will only be applied to this server. If they are not provided, the values from General Settings will be used. You can change these values later.'**
  String get serverSettingsDescription;

  /// No description provided for @editServerSettingsInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit server settings'**
  String get editServerSettingsInfo;

  /// No description provided for @editServerSettings.
  ///
  /// In en, this message translates to:
  /// **'Edit server settings {serverName}'**
  String editServerSettings(String serverName);

  /// No description provided for @removeCamera.
  ///
  /// In en, this message translates to:
  /// **'Remove Camera'**
  String get removeCamera;

  /// No description provided for @removePlayer.
  ///
  /// In en, this message translates to:
  /// **'Remove all devices attached to this player'**
  String get removePlayer;

  /// No description provided for @replaceCamera.
  ///
  /// In en, this message translates to:
  /// **'Replace Camera'**
  String get replaceCamera;

  /// No description provided for @reloadCamera.
  ///
  /// In en, this message translates to:
  /// **'Reload Camera'**
  String get reloadCamera;

  /// No description provided for @selectACamera.
  ///
  /// In en, this message translates to:
  /// **'Select a camera'**
  String get selectACamera;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switchCamera;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @timedOut.
  ///
  /// In en, this message translates to:
  /// **'TIMED OUT'**
  String get timedOut;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get loading;

  /// No description provided for @recorded.
  ///
  /// In en, this message translates to:
  /// **'RECORDED'**
  String get recorded;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'LATE'**
  String get late;

  /// No description provided for @removeFromView.
  ///
  /// In en, this message translates to:
  /// **'Remove from view'**
  String get removeFromView;

  /// No description provided for @addToView.
  ///
  /// In en, this message translates to:
  /// **'Add to view'**
  String get addToView;

  /// No description provided for @addAllToView.
  ///
  /// In en, this message translates to:
  /// **'Add all to view'**
  String get addAllToView;

  /// No description provided for @removeAllFromView.
  ///
  /// In en, this message translates to:
  /// **'Remove all from view'**
  String get removeAllFromView;

  /// No description provided for @streamName.
  ///
  /// In en, this message translates to:
  /// **'Stream name'**
  String get streamName;

  /// No description provided for @streamNameRequired.
  ///
  /// In en, this message translates to:
  /// **'The stream name is required'**
  String get streamNameRequired;

  /// No description provided for @streamURL.
  ///
  /// In en, this message translates to:
  /// **'Stream URL'**
  String get streamURL;

  /// No description provided for @streamURLRequired.
  ///
  /// In en, this message translates to:
  /// **'The stream URL is required'**
  String get streamURLRequired;

  /// No description provided for @streamURLNotValid.
  ///
  /// In en, this message translates to:
  /// **'The stream URL is not valid'**
  String get streamURLNotValid;

  /// No description provided for @uri.
  ///
  /// In en, this message translates to:
  /// **'URI'**
  String get uri;

  /// No description provided for @eventBrowser.
  ///
  /// In en, this message translates to:
  /// **'Events History'**
  String get eventBrowser;

  /// No description provided for @eventsTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline of Events'**
  String get eventsTimeline;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @viewDeviceDetails.
  ///
  /// In en, this message translates to:
  /// **'View device details'**
  String get viewDeviceDetails;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @lastImageUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Image Update'**
  String get lastImageUpdate;

  /// No description provided for @fps.
  ///
  /// In en, this message translates to:
  /// **'FPS'**
  String get fps;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @screens.
  ///
  /// In en, this message translates to:
  /// **'Screens • {layout}'**
  String screens(String layout);

  /// No description provided for @directCamera.
  ///
  /// In en, this message translates to:
  /// **'Direct Camera'**
  String get directCamera;

  /// No description provided for @addServer.
  ///
  /// In en, this message translates to:
  /// **'Add Server'**
  String get addServer;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noServersAdded.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any servers yet :/'**
  String get noServersAdded;

  /// No description provided for @howToAddServer.
  ///
  /// In en, this message translates to:
  /// **'Go to the \"Add Server\" tab to add a server.'**
  String get howToAddServer;

  /// No description provided for @editServerInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit server info'**
  String get editServerInfo;

  /// No description provided for @editServer.
  ///
  /// In en, this message translates to:
  /// **'Edit server {serverName}'**
  String editServer(String serverName);

  /// No description provided for @servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// No description provided for @nServers.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No servers} =1{1 server} other{{n} servers}}'**
  String nServers(int n);

  /// No description provided for @nDevices.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No devices} =1{1 device} other{{n} devices}}'**
  String nDevices(int n);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove ?'**
  String get remove;

  /// No description provided for @removeServerDescription.
  ///
  /// In en, this message translates to:
  /// **'{serverName} will be removed from the application. You\'ll not be able to view cameras from this server & will no longer receive notifications.'**
  String removeServerDescription(String serverName);

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionText.
  ///
  /// In en, this message translates to:
  /// **'Copyright © 2022, Bluecherry LLC.\nAll rights reserved.'**
  String get versionText;

  /// No description provided for @gettingDevices.
  ///
  /// In en, this message translates to:
  /// **'Getting devices'**
  String get gettingDevices;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices'**
  String get noDevices;

  /// No description provided for @noEventsLoaded.
  ///
  /// In en, this message translates to:
  /// **'NO EVENTS LOADED'**
  String get noEventsLoaded;

  /// No description provided for @noEventsLoadedTips.
  ///
  /// In en, this message translates to:
  /// **'•  Select the cameras you want to see the events\n•  Use the calendar to select a specific date or a date range \n•  Use the \"Filter\" button to perform the search'**
  String get noEventsLoadedTips;

  /// No description provided for @timelineKeyboardShortcutsTips.
  ///
  /// In en, this message translates to:
  /// **'•  Use the space bar to play/pause the timeline\n•  Use the left and right arrow keys to move the timeline\n•  Use the M key to mute/unmute the timeline\n•  Use the mouse wheel to zoom in/out the timeline'**
  String get timelineKeyboardShortcutsTips;

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid response received from the server'**
  String get invalidResponse;

  /// No description provided for @cameraOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get cameraOptions;

  /// No description provided for @showFullscreenCamera.
  ///
  /// In en, this message translates to:
  /// **'Show in fullscreen'**
  String get showFullscreenCamera;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// No description provided for @openInANewWindow.
  ///
  /// In en, this message translates to:
  /// **'Open in a new window'**
  String get openInANewWindow;

  /// No description provided for @enableAudio.
  ///
  /// In en, this message translates to:
  /// **'Enable audio'**
  String get enableAudio;

  /// No description provided for @disableAudio.
  ///
  /// In en, this message translates to:
  /// **'Disable audio'**
  String get disableAudio;

  /// No description provided for @addNewServer.
  ///
  /// In en, this message translates to:
  /// **'Add new server'**
  String get addNewServer;

  /// No description provided for @disconnectServer.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectServer;

  /// No description provided for @serverOptions.
  ///
  /// In en, this message translates to:
  /// **'Server options'**
  String get serverOptions;

  /// No description provided for @browseEvents.
  ///
  /// In en, this message translates to:
  /// **'Browse events'**
  String get browseEvents;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventType;

  /// No description provided for @configureServer.
  ///
  /// In en, this message translates to:
  /// **'Configure server'**
  String get configureServer;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh devices'**
  String get refreshDevices;

  /// No description provided for @refreshServer.
  ///
  /// In en, this message translates to:
  /// **'Refresh server'**
  String get refreshServer;

  /// No description provided for @viewDevices.
  ///
  /// In en, this message translates to:
  /// **'View devices'**
  String get viewDevices;

  /// No description provided for @serverDevices.
  ///
  /// In en, this message translates to:
  /// **'{server} devices'**
  String serverDevices(String server);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @fallbackLayoutName.
  ///
  /// In en, this message translates to:
  /// **'Layout {layout}'**
  String fallbackLayoutName(int layout);

  /// No description provided for @newLayout.
  ///
  /// In en, this message translates to:
  /// **'New layout'**
  String get newLayout;

  /// No description provided for @editLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get editLayout;

  /// No description provided for @editSpecificLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit {layoutName}'**
  String editSpecificLayout(String layoutName);

  /// No description provided for @exportLayout.
  ///
  /// In en, this message translates to:
  /// **'Export layout'**
  String get exportLayout;

  /// No description provided for @importLayout.
  ///
  /// In en, this message translates to:
  /// **'import layout'**
  String get importLayout;

  /// No description provided for @failedToimportMessage.
  ///
  /// In en, this message translates to:
  /// **'While attempting to import {layoutName}, we found a device that is connected to a server you are not connected to. Please, connect to the server and try again.\nServer: {server_ip}:{server_port}'**
  String failedToimportMessage(
    String layoutName,
    String server_ip,
    int server_port,
  );

  /// No description provided for @layoutimportFileCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The file you attempted to import is corrupted or missing information.'**
  String get layoutimportFileCorrupted;

  /// No description provided for @layoutimportFileCorruptedWithMessage.
  ///
  /// In en, this message translates to:
  /// **'The file you attempted to import is corrupted or missing information: \"{message}\"'**
  String layoutimportFileCorruptedWithMessage(Object message);

  /// No description provided for @singleView.
  ///
  /// In en, this message translates to:
  /// **'Single view'**
  String get singleView;

  /// No description provided for @multipleView.
  ///
  /// In en, this message translates to:
  /// **'Multiple view'**
  String get multipleView;

  /// No description provided for @compactView.
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get compactView;

  /// No description provided for @createNewLayout.
  ///
  /// In en, this message translates to:
  /// **'Create new layout'**
  String get createNewLayout;

  /// No description provided for @layoutName.
  ///
  /// In en, this message translates to:
  /// **'Layout name'**
  String get layoutName;

  /// No description provided for @layoutNameHint.
  ///
  /// In en, this message translates to:
  /// **'First floor'**
  String get layoutNameHint;

  /// No description provided for @layoutTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Layout type'**
  String get layoutTypeLabel;

  /// No description provided for @clearLayout.
  ///
  /// In en, this message translates to:
  /// **'Remove {amount} {amount, plural, =1{device} other{devices}}'**
  String clearLayout(int amount);

  /// No description provided for @switchToNext.
  ///
  /// In en, this message translates to:
  /// **'Switch to next'**
  String get switchToNext;

  /// No description provided for @unlockLayout.
  ///
  /// In en, this message translates to:
  /// **'Unlock layout'**
  String get unlockLayout;

  /// No description provided for @lockLayout.
  ///
  /// In en, this message translates to:
  /// **'Lock layout'**
  String get lockLayout;

  /// No description provided for @layoutVolume.
  ///
  /// In en, this message translates to:
  /// **'Layout Volume • {volume}%'**
  String layoutVolume(int volume);

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadN.
  ///
  /// In en, this message translates to:
  /// **'Download {n, plural, =1{1 event} other{{n} events}}'**
  String downloadN(int n);

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @seeInDownloads.
  ///
  /// In en, this message translates to:
  /// **'See in Downloads'**
  String get seeInDownloads;

  /// No description provided for @downloadPath.
  ///
  /// In en, this message translates to:
  /// **'Download directory'**
  String get downloadPath;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @showInFiles.
  ///
  /// In en, this message translates to:
  /// **'Show in Files'**
  String get showInFiles;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t downloaded anything yet :/'**
  String get noDownloads;

  /// No description provided for @nDownloadsProgress.
  ///
  /// In en, this message translates to:
  /// **'You have {n} downloads in progress!'**
  String nDownloadsProgress(int n);

  /// No description provided for @howToDownload.
  ///
  /// In en, this message translates to:
  /// **'Go to the \"Events History\" tab to download events.'**
  String get howToDownload;

  /// No description provided for @downloadTitle.
  ///
  /// In en, this message translates to:
  /// **'{event} on {device} ({server}) at {date}'**
  String downloadTitle(String event, String device, String server, String date);

  /// No description provided for @playbackOptions.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK OPTIONS'**
  String get playbackOptions;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume • {v}'**
  String volume(String v);

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed • {s}'**
  String speed(String s);

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'This camera has no records in the current period.'**
  String get noRecords;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @loadEvents.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Load} =1{Load from 1 device} other{Load from {n} devices}}'**
  String loadEvents(int n);

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @dateTimeFilter.
  ///
  /// In en, this message translates to:
  /// **'Date and Time Filter'**
  String get dateTimeFilter;

  /// No description provided for @dateFilter.
  ///
  /// In en, this message translates to:
  /// **'Date Filter'**
  String get dateFilter;

  /// No description provided for @timeFilter.
  ///
  /// In en, this message translates to:
  /// **'Time Filter'**
  String get timeFilter;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @fromToDate.
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String fromToDate(String from, String to);

  /// No description provided for @mostRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get mostRecent;

  /// No description provided for @allowAlarms.
  ///
  /// In en, this message translates to:
  /// **'Allow alarms'**
  String get allowAlarms;

  /// No description provided for @nextEvents.
  ///
  /// In en, this message translates to:
  /// **'Next events'**
  String get nextEvents;

  /// No description provided for @nEvents.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No events} =1{1 event} other{{n} events}}'**
  String nEvents(int n);

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @warn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warn;

  /// No description provided for @alarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get alarm;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @motion.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motion;

  /// No description provided for @continuous.
  ///
  /// In en, this message translates to:
  /// **'Continouous'**
  String get continuous;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @cameraVideoLost.
  ///
  /// In en, this message translates to:
  /// **'Video Lost'**
  String get cameraVideoLost;

  /// No description provided for @cameraAudioLost.
  ///
  /// In en, this message translates to:
  /// **'Audio Lost'**
  String get cameraAudioLost;

  /// No description provided for @systemDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Disk Space'**
  String get systemDiskSpace;

  /// No description provided for @systemCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash'**
  String get systemCrash;

  /// No description provided for @systemBoot.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get systemBoot;

  /// No description provided for @systemShutdown.
  ///
  /// In en, this message translates to:
  /// **'Shutdown'**
  String get systemShutdown;

  /// No description provided for @systemReboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot'**
  String get systemReboot;

  /// No description provided for @systemPowerOutage.
  ///
  /// In en, this message translates to:
  /// **'Power Lost'**
  String get systemPowerOutage;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Close anyway'**
  String get closeAnyway;

  /// No description provided for @closeWhenDone.
  ///
  /// In en, this message translates to:
  /// **'Close when done'**
  String get closeWhenDone;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @isPtzSupported.
  ///
  /// In en, this message translates to:
  /// **'Supports PTZ?'**
  String get isPtzSupported;

  /// No description provided for @ptzSupported.
  ///
  /// In en, this message translates to:
  /// **'PTZ is supported'**
  String get ptzSupported;

  /// No description provided for @enabledPTZ.
  ///
  /// In en, this message translates to:
  /// **'PTZ is enabled'**
  String get enabledPTZ;

  /// No description provided for @disabledPTZ.
  ///
  /// In en, this message translates to:
  /// **'PTZ is disabled'**
  String get disabledPTZ;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get move;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @noMovement.
  ///
  /// In en, this message translates to:
  /// **'No movement'**
  String get noMovement;

  /// No description provided for @moveNorth.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveNorth;

  /// No description provided for @moveSouth.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveSouth;

  /// No description provided for @moveWest.
  ///
  /// In en, this message translates to:
  /// **'Move west'**
  String get moveWest;

  /// No description provided for @moveEast.
  ///
  /// In en, this message translates to:
  /// **'Move east'**
  String get moveEast;

  /// No description provided for @moveWide.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get moveWide;

  /// No description provided for @moveTele.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get moveTele;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @noPresets.
  ///
  /// In en, this message translates to:
  /// **'No presets found'**
  String get noPresets;

  /// No description provided for @newPreset.
  ///
  /// In en, this message translates to:
  /// **'New preset'**
  String get newPreset;

  /// No description provided for @goToPreset.
  ///
  /// In en, this message translates to:
  /// **'Go to preset'**
  String get goToPreset;

  /// No description provided for @renamePreset.
  ///
  /// In en, this message translates to:
  /// **'Rename preset'**
  String get renamePreset;

  /// No description provided for @deletePreset.
  ///
  /// In en, this message translates to:
  /// **'Delete preset'**
  String get deletePreset;

  /// No description provided for @refreshPresets.
  ///
  /// In en, this message translates to:
  /// **'Refresh presets'**
  String get refreshPresets;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @selectResolution.
  ///
  /// In en, this message translates to:
  /// **'Select resolution'**
  String get selectResolution;

  /// No description provided for @setResolution.
  ///
  /// In en, this message translates to:
  /// **'Set resolution'**
  String get setResolution;

  /// No description provided for @setResolutionDescription.
  ///
  /// In en, this message translates to:
  /// **'The resolution of the video stream can highly impact the performance of the app. Set the resolution to a lower value to improve performance, or to a higher value to improve quality. You can set the default resolution to every camera in the settings'**
  String get setResolutionDescription;

  /// No description provided for @hd.
  ///
  /// In en, this message translates to:
  /// **'High definition'**
  String get hd;

  /// No description provided for @defaultResolution.
  ///
  /// In en, this message translates to:
  /// **'Default resolution'**
  String get defaultResolution;

  /// No description provided for @automaticResolution.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticResolution;

  /// No description provided for @p4k.
  ///
  /// In en, this message translates to:
  /// **'4K'**
  String get p4k;

  /// No description provided for @p1080.
  ///
  /// In en, this message translates to:
  /// **'1080p'**
  String get p1080;

  /// No description provided for @p720.
  ///
  /// In en, this message translates to:
  /// **'720p'**
  String get p720;

  /// No description provided for @p480.
  ///
  /// In en, this message translates to:
  /// **'480p'**
  String get p480;

  /// No description provided for @p360.
  ///
  /// In en, this message translates to:
  /// **'360p'**
  String get p360;

  /// No description provided for @p240.
  ///
  /// In en, this message translates to:
  /// **'240p'**
  String get p240;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date.'**
  String get upToDate;

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String lastChecked(String date);

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates'**
  String get checkingForUpdates;

  /// No description provided for @automaticDownloadUpdates.
  ///
  /// In en, this message translates to:
  /// **'Automatic download updates'**
  String get automaticDownloadUpdates;

  /// No description provided for @automaticDownloadUpdatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Be among the first to get the latest updates, fixes and improvements as they roll out.'**
  String get automaticDownloadUpdatesDescription;

  /// No description provided for @updateHistory.
  ///
  /// In en, this message translates to:
  /// **'Update history'**
  String get updateHistory;

  /// No description provided for @showReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Show release notes'**
  String get showReleaseNotes;

  /// No description provided for @showReleaseNotesDescription.
  ///
  /// In en, this message translates to:
  /// **'Display release notes when a new version is installed'**
  String get showReleaseNotesDescription;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// No description provided for @installVersion.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installVersion;

  /// No description provided for @downloadVersion.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadVersion;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @executableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Executable not found'**
  String get executableNotFound;

  /// No description provided for @runningOn.
  ///
  /// In en, this message translates to:
  /// **'Running on {platform}'**
  String runningOn(String platform);

  /// No description provided for @windows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get windows;

  /// No description provided for @linux.
  ///
  /// In en, this message translates to:
  /// **'Linux {env}'**
  String linux(String env);

  /// No description provided for @currentTasks.
  ///
  /// In en, this message translates to:
  /// **'Current tasks'**
  String get currentTasks;

  /// No description provided for @noCurrentTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noCurrentTasks;

  /// No description provided for @taskFetchingEvent.
  ///
  /// In en, this message translates to:
  /// **'Fetching events'**
  String get taskFetchingEvent;

  /// No description provided for @taskFetchingEventsPlayback.
  ///
  /// In en, this message translates to:
  /// **'Fetching events playback'**
  String get taskFetchingEventsPlayback;

  /// No description provided for @taskDownloadingEvent.
  ///
  /// In en, this message translates to:
  /// **'Downloading event'**
  String get taskDownloadingEvent;

  /// No description provided for @defaultField.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultField;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generalSettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Notifications, Data Usage, Wakelock, etc'**
  String get generalSettingsSuggestion;

  /// No description provided for @serverAndDevices.
  ///
  /// In en, this message translates to:
  /// **'Servers and Devices'**
  String get serverAndDevices;

  /// No description provided for @serverAndDevicesSettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Connect to servers, manage devices, etc'**
  String get serverAndDevicesSettingsSuggestion;

  /// No description provided for @eventsAndDownloads.
  ///
  /// In en, this message translates to:
  /// **'Events and Downloads'**
  String get eventsAndDownloads;

  /// No description provided for @eventsAndDownloadsSettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Events history, downloads, etc'**
  String get eventsAndDownloadsSettingsSuggestion;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// No description provided for @applicationSettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Appearance, theme, date and time, etc'**
  String get applicationSettingsSuggestion;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Security'**
  String get privacyAndSecurity;

  /// No description provided for @privacyAndSecuritySettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Data collection, error reporting, etc'**
  String get privacyAndSecuritySettingsSuggestion;

  /// No description provided for @updatesHelpAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Updates, Help and Privacy'**
  String get updatesHelpAndPrivacy;

  /// No description provided for @updatesHelpAndPrivacySettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Check for updates, update history, privacy policy, etc'**
  String get updatesHelpAndPrivacySettingsSuggestion;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// No description provided for @advancedOptionsSettingsSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Funcionalidades em Beta, Opções de Desenvolvedor, etc'**
  String get advancedOptionsSettingsSuggestion;

  /// No description provided for @cycleTogglePeriod.
  ///
  /// In en, this message translates to:
  /// **'Layout cycle toggle period'**
  String get cycleTogglePeriod;

  /// No description provided for @cycleTogglePeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'The interval between layout changes when the cycle mode is enabled.'**
  String get cycleTogglePeriodDescription;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationClickBehavior.
  ///
  /// In en, this message translates to:
  /// **'Notification Click Behavior'**
  String get notificationClickBehavior;

  /// No description provided for @notificationClickBehaviorDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what happens when you click on a notification.'**
  String get notificationClickBehaviorDescription;

  /// No description provided for @showEventsScreen.
  ///
  /// In en, this message translates to:
  /// **'Show events history'**
  String get showEventsScreen;

  /// No description provided for @dataUsage.
  ///
  /// In en, this message translates to:
  /// **'Data Usage'**
  String get dataUsage;

  /// No description provided for @streamsOnBackground.
  ///
  /// In en, this message translates to:
  /// **'Keep streams playing on background'**
  String get streamsOnBackground;

  /// No description provided for @streamsOnBackgroundDescription.
  ///
  /// In en, this message translates to:
  /// **'When to keep streams playing when the app is in background'**
  String get streamsOnBackgroundDescription;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wifi Only'**
  String get wifiOnly;

  /// No description provided for @chooseEveryDownloadsLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose the location for every download'**
  String get chooseEveryDownloadsLocation;

  /// No description provided for @chooseEveryDownloadsLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether to choose the location for each download or use the default location. When enabled, you will be prompted to choose the download directory for each download.'**
  String get chooseEveryDownloadsLocationDescription;

  /// No description provided for @allowCloseWhenDownloading.
  ///
  /// In en, this message translates to:
  /// **'Allow closing the app when downloading'**
  String get allowCloseWhenDownloading;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @initialEventSpeed.
  ///
  /// In en, this message translates to:
  /// **'Initial event speed'**
  String get initialEventSpeed;

  /// No description provided for @initialEventVolume.
  ///
  /// In en, this message translates to:
  /// **'Initial event volume'**
  String get initialEventVolume;

  /// No description provided for @differentEventColors.
  ///
  /// In en, this message translates to:
  /// **'Different events by colors'**
  String get differentEventColors;

  /// No description provided for @differentEventColorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether to show different colors for events in the timeline. This assists to easily differentiate the events.'**
  String get differentEventColorsDescription;

  /// No description provided for @initialTimelinePoint.
  ///
  /// In en, this message translates to:
  /// **'Initial point'**
  String get initialTimelinePoint;

  /// No description provided for @initialTimelinePointDescription.
  ///
  /// In en, this message translates to:
  /// **'The initial point of the timeline.'**
  String get initialTimelinePointDescription;

  /// No description provided for @beginningInitialPoint.
  ///
  /// In en, this message translates to:
  /// **'Beginning'**
  String get beginningInitialPoint;

  /// No description provided for @firstEventInitialPoint.
  ///
  /// In en, this message translates to:
  /// **'First event'**
  String get firstEventInitialPoint;

  /// No description provided for @hourAgoInitialPoint.
  ///
  /// In en, this message translates to:
  /// **'1 hour ago'**
  String get hourAgoInitialPoint;

  /// No description provided for @automaticallySkipEmptyPeriods.
  ///
  /// In en, this message translates to:
  /// **'Automatically skip empty periods'**
  String get automaticallySkipEmptyPeriods;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDescription.
  ///
  /// In en, this message translates to:
  /// **'Change the appearance of the app'**
  String get themeDescription;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and Time'**
  String get dateAndTime;

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get dateFormat;

  /// No description provided for @dateFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'What format to use for displaying dates'**
  String get dateFormatDescription;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time Format'**
  String get timeFormat;

  /// No description provided for @timeFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'What format to use for displaying time'**
  String get timeFormatDescription;

  /// No description provided for @convertToLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Convert dates to the local timezone'**
  String get convertToLocalTime;

  /// No description provided for @convertToLocalTimeDescription.
  ///
  /// In en, this message translates to:
  /// **'This will affect the date and time displayed in the app. This is useful when you are in a different timezone than the server. When disabled, the server timezone will be used.'**
  String get convertToLocalTimeDescription;

  /// No description provided for @allowDataCollection.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluecherry to collect usage data'**
  String get allowDataCollection;

  /// No description provided for @allowDataCollectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluecherry to collect data to improve the app and provide better services. Data is collected anonymously and does not contain any personal information.'**
  String get allowDataCollectionDescription;

  /// No description provided for @automaticallyReportErrors.
  ///
  /// In en, this message translates to:
  /// **'Automatically report errors'**
  String get automaticallyReportErrors;

  /// No description provided for @automaticallyReportErrorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically send error reports to Bluecherry to help improve the app. Error reports may contain personal information.'**
  String get automaticallyReportErrorsDescription;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @matrixMagnification.
  ///
  /// In en, this message translates to:
  /// **'Area Magnification'**
  String get matrixMagnification;

  /// No description provided for @matrixedViewMagnification.
  ///
  /// In en, this message translates to:
  /// **'Area Magnification enabled'**
  String get matrixedViewMagnification;

  /// No description provided for @matrixedViewMagnificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Magnify a area of the matrix view when selected. This is useful when you have a lot of cameras and want to see a specific area in more detail, or when a multicast stream is provided.'**
  String get matrixedViewMagnificationDescription;

  /// No description provided for @matrixType.
  ///
  /// In en, this message translates to:
  /// **'Matrix type'**
  String get matrixType;

  /// No description provided for @defaultMatrixSize.
  ///
  /// In en, this message translates to:
  /// **'Default Magnification Proportion'**
  String get defaultMatrixSize;

  /// No description provided for @softwareMagnification.
  ///
  /// In en, this message translates to:
  /// **'Software Magnification'**
  String get softwareMagnification;

  /// No description provided for @softwareMagnificationDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the magnification will not happen in the GPU. This is useful when the hardware magnification is not working properly.'**
  String get softwareMagnificationDescription;

  /// No description provided for @softwareMagnificationDescriptionMacOS.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the magnification will not happen in the GPU. This is useful when the hardware magnification is not working properly. On macOS, this can not be disabled.'**
  String get softwareMagnificationDescriptionMacOS;

  /// No description provided for @eventMagnification.
  ///
  /// In en, this message translates to:
  /// **'Event Magnification'**
  String get eventMagnification;

  /// No description provided for @eventMagnificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Magnify the event video when selected. This is useful when you want to see the event in more detail.'**
  String get eventMagnificationDescription;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get developerOptions;

  /// No description provided for @openLogFile.
  ///
  /// In en, this message translates to:
  /// **'Open log file'**
  String get openLogFile;

  /// No description provided for @openAppDataDirectory.
  ///
  /// In en, this message translates to:
  /// **'Open app data directory'**
  String get openAppDataDirectory;

  /// No description provided for @importConfigFile.
  ///
  /// In en, this message translates to:
  /// **'import configuration file'**
  String get importConfigFile;

  /// No description provided for @importConfigFileDescription.
  ///
  /// In en, this message translates to:
  /// **'import a .bluecherry configuration file that contains streaming information.'**
  String get importConfigFileDescription;

  /// No description provided for @debugInfo.
  ///
  /// In en, this message translates to:
  /// **'Debug info'**
  String get debugInfo;

  /// No description provided for @debugInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Display useful information for debugging, such as video metadata and other useful information for debugging purposes.'**
  String get debugInfoDescription;

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get restoreDefaults;

  /// No description provided for @restoreDefaultsDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore all settings to their default values. This will not affect the servers you have added.'**
  String get restoreDefaultsDescription;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @areYouSureDescription.
  ///
  /// In en, this message translates to:
  /// **'This will restore all settings to their default values. This will not affect your servers or any other data.'**
  String get areYouSureDescription;

  /// No description provided for @miscellaneous.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get miscellaneous;

  /// No description provided for @wakelock.
  ///
  /// In en, this message translates to:
  /// **'Keep screen awake'**
  String get wakelock;

  /// No description provided for @wakelockDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep screen awake while watching live streams or recordings.'**
  String get wakelockDescription;

  /// No description provided for @snooze15.
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get snooze15;

  /// No description provided for @snooze30.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get snooze30;

  /// No description provided for @snooze60.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get snooze60;

  /// No description provided for @snoozeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Snooze Notifications'**
  String get snoozeNotifications;

  /// No description provided for @notSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Not snoozing'**
  String get notSnoozed;

  /// No description provided for @snoozeNotificationsUntil.
  ///
  /// In en, this message translates to:
  /// **'Snooze notifications until'**
  String get snoozeNotificationsUntil;

  /// No description provided for @snoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String snoozedUntil(String time);

  /// No description provided for @connectToServerAutomaticallyAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Connect automatically at startup'**
  String get connectToServerAutomaticallyAtStartup;

  /// No description provided for @connectToServerAutomaticallyAtStartupDescription.
  ///
  /// In en, this message translates to:
  /// **'If enabled, the server will be automatically connected when the app starts. This only applies to the new servers you add.'**
  String get connectToServerAutomaticallyAtStartupDescription;

  /// No description provided for @allowUntrustedCertificates.
  ///
  /// In en, this message translates to:
  /// **'Allow untrusted certificates'**
  String get allowUntrustedCertificates;

  /// No description provided for @allowUntrustedCertificatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow connecting to servers with untrusted certificates. This is useful when you are using self-signed certificates or certificates from unknown authorities.'**
  String get allowUntrustedCertificatesDescription;

  /// No description provided for @certificateNotPassed.
  ///
  /// In en, this message translates to:
  /// **'Certificate not passed'**
  String get certificateNotPassed;

  /// No description provided for @addServerTimeout.
  ///
  /// In en, this message translates to:
  /// **'Add server timeout'**
  String get addServerTimeout;

  /// No description provided for @addServerTimeoutDescription.
  ///
  /// In en, this message translates to:
  /// **'The time to wait for the server to respond when adding a new server.'**
  String get addServerTimeoutDescription;

  /// No description provided for @streamingSettings.
  ///
  /// In en, this message translates to:
  /// **'Streaming settings'**
  String get streamingSettings;

  /// No description provided for @streamingProtocol.
  ///
  /// In en, this message translates to:
  /// **'Streaming Protocol'**
  String get streamingProtocol;

  /// No description provided for @preferredStreamingProtocol.
  ///
  /// In en, this message translates to:
  /// **'Preferred Streaming Protocol'**
  String get preferredStreamingProtocol;

  /// No description provided for @preferredStreamingProtocolDescription.
  ///
  /// In en, this message translates to:
  /// **'What video streaming protocol will be used. If the server does not support the selected protocol, the app will try to use the next one. It is possible to select a specific protocol for each device in its settings.'**
  String get preferredStreamingProtocolDescription;

  /// No description provided for @rtspProtocol.
  ///
  /// In en, this message translates to:
  /// **'RTSP Protocol'**
  String get rtspProtocol;

  /// No description provided for @camerasSettings.
  ///
  /// In en, this message translates to:
  /// **'Cameras settings'**
  String get camerasSettings;

  /// No description provided for @renderingQuality.
  ///
  /// In en, this message translates to:
  /// **'Rendering quality'**
  String get renderingQuality;

  /// No description provided for @renderingQualityDescription.
  ///
  /// In en, this message translates to:
  /// **'The quality of the video rendering. The higher the quality, the more rendering resources it takes. It is recommended to use high quality when a GPU is installed. When set to automatic, the quality is selected based on the camera resolution.'**
  String get renderingQualityDescription;

  /// No description provided for @cameraViewFit.
  ///
  /// In en, this message translates to:
  /// **'Camera Image Fit'**
  String get cameraViewFit;

  /// No description provided for @cameraViewFitDescription.
  ///
  /// In en, this message translates to:
  /// **'The way the video is displayed in the view.'**
  String get cameraViewFitDescription;

  /// No description provided for @contain.
  ///
  /// In en, this message translates to:
  /// **'Contain'**
  String get contain;

  /// No description provided for @fill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fill;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @streamRefreshPeriod.
  ///
  /// In en, this message translates to:
  /// **'Stream Refresh Period'**
  String get streamRefreshPeriod;

  /// No description provided for @streamRefreshPeriodDescription.
  ///
  /// In en, this message translates to:
  /// **'The interval between device refreshes. It ensures the camera video is still valid from time to time.'**
  String get streamRefreshPeriodDescription;

  /// No description provided for @lateStreamBehavior.
  ///
  /// In en, this message translates to:
  /// **'Late stream behavior'**
  String get lateStreamBehavior;

  /// No description provided for @lateStreamBehaviorDescription.
  ///
  /// In en, this message translates to:
  /// **'What to do when a stream is late'**
  String get lateStreamBehaviorDescription;

  /// No description provided for @automaticBehavior.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticBehavior;

  /// No description provided for @automaticBehaviorDescription.
  ///
  /// In en, this message translates to:
  /// **'The app will try to reposition the stream automatically'**
  String get automaticBehaviorDescription;

  /// No description provided for @manualBehavior.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualBehavior;

  /// No description provided for @manualBehaviorDescription.
  ///
  /// In en, this message translates to:
  /// **'Press {label} to reposition the stream'**
  String manualBehaviorDescription(String label);

  /// No description provided for @neverBehaviorDescription.
  ///
  /// In en, this message translates to:
  /// **'The app will not try to reposition the stream'**
  String get neverBehaviorDescription;

  /// No description provided for @devicesSettings.
  ///
  /// In en, this message translates to:
  /// **'Devices Settings'**
  String get devicesSettings;

  /// No description provided for @listOfflineDevices.
  ///
  /// In en, this message translates to:
  /// **'List Offline Devices'**
  String get listOfflineDevices;

  /// No description provided for @listOfflineDevicesDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Whether to show offline devices in the devices list.'**
  String get listOfflineDevicesDescriptions;

  /// No description provided for @initialDeviceVolume.
  ///
  /// In en, this message translates to:
  /// **'Initial Camera Volume'**
  String get initialDeviceVolume;

  /// No description provided for @runVideoTest.
  ///
  /// In en, this message translates to:
  /// **'Run Video Test'**
  String get runVideoTest;

  /// No description provided for @runVideoTestDescription.
  ///
  /// In en, this message translates to:
  /// **'Run a video test to check the state of video playback.'**
  String get runVideoTestDescription;

  /// No description provided for @showCameraName.
  ///
  /// In en, this message translates to:
  /// **'Show Camera Name'**
  String get showCameraName;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @onHover.
  ///
  /// In en, this message translates to:
  /// **'On hover'**
  String get onHover;

  /// No description provided for @dateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Date and Language'**
  String get dateLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @overlays.
  ///
  /// In en, this message translates to:
  /// **'Overlays'**
  String get overlays;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @nOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay {n}'**
  String nOverlay(int n);

  /// No description provided for @overlayPosition.
  ///
  /// In en, this message translates to:
  /// **'Position (x: {x}, y: {y})'**
  String overlayPosition(double x, double y);

  /// No description provided for @externalStream.
  ///
  /// In en, this message translates to:
  /// **'External stream'**
  String get externalStream;

  /// No description provided for @addExternalStream.
  ///
  /// In en, this message translates to:
  /// **'Add external stream'**
  String get addExternalStream;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @serverHostname.
  ///
  /// In en, this message translates to:
  /// **'Server hostname'**
  String get serverHostname;

  /// No description provided for @serverHostnameExample.
  ///
  /// In en, this message translates to:
  /// **'https://my-server.bluecherry.app:7001'**
  String get serverHostnameExample;

  /// No description provided for @rackName.
  ///
  /// In en, this message translates to:
  /// **'Rack name'**
  String get rackName;

  /// No description provided for @rackNameExample.
  ///
  /// In en, this message translates to:
  /// **'Lab 1'**
  String get rackNameExample;

  /// No description provided for @openServer.
  ///
  /// In en, this message translates to:
  /// **'Open server'**
  String get openServer;

  /// No description provided for @disableSearch.
  ///
  /// In en, this message translates to:
  /// **'Disable search'**
  String get disableSearch;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'pl', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

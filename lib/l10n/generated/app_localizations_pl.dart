// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get welcome => 'Witamy';

  @override
  String get welcomeDescription => 'Witamy w systemie monitoringu Blueberry!\nPodłącz się do serwera DVR.';

  @override
  String get configure => 'Konfiguracja serwera DVR';

  @override
  String get configureDescription => 'Ustawienia połączenia ze zdalnym serwerem DVR. You can connect to any number of servers from anywhere in the world.';

  @override
  String get hostname => 'Nazwa hosta';

  @override
  String get hostnameExample => 'demo.bluecherry.app';

  @override
  String get port => 'Port';

  @override
  String get rtspPort => 'RTSP Port';

  @override
  String get serverName => 'Server Name';

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get usernameHint => 'Admin';

  @override
  String get password => 'Hasło';

  @override
  String get savePassword => 'Zapisz hasło';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get useDefault => 'Użyj wartości domyślnych';

  @override
  String get connect => 'Połącz';

  @override
  String get connectAutomaticallyAtStartup => 'Połącz automatycznie przy uruchomieniu';

  @override
  String get connectAutomaticallyAtStartupDescription => 'If enabled, the app will automatically connect to the server when it starts.';

  @override
  String get checkingServerCredentials => 'Checking server credentials';

  @override
  String get skip => 'Pomiń';

  @override
  String get cancel => 'Anuluj';

  @override
  String get disabled => 'Disabled';

  @override
  String get letsGo => 'Do dzieła!';

  @override
  String get finish => 'Zakończ';

  @override
  String get letsGoDescription => 'Kilka porad jak zacząć:';

  @override
  String get projectName => 'Bluecherry';

  @override
  String get projectDescription => 'Oprogramowanie do monitoringu wizyjnego';

  @override
  String get website => 'Strona domowa';

  @override
  String get purchase => 'Zakup licencji';

  @override
  String get tip0 => 'Kamery pokazane są po lewej. You can double-click or drag the camera into the live area to view it.';

  @override
  String get tip1 => 'Użyj przycisków powyżej podlgądu na żywo aby utworzyć, zapisać lub przełączyć układy - nawet z kamerami z różnych serwerów.';

  @override
  String get tip2 => 'Kliknij podwójnie na serwer aby otworzyć jego konfigurację w nowym oknie, gdzie można skonfigurować kamery i nagrania.';

  @override
  String get tip3 => 'Kliknij na ikonę zdarzeń aby przeglądać historię lub zapisać nagrania.';

  @override
  String errorTextField(String field) {
    return '$field nie jest wypełnione.';
  }

  @override
  String get serverAdded => 'Dodano serwer';

  @override
  String serverNotAddedError(String serverName) {
    return '$serverName nie został dodany.';
  }

  @override
  String serverNotAddedErrorDescription(String port, String rtspPort) {
    return 'Please check the entered details and ensure the server is online.\n\nIf you are connecting remote, make sure the $port and $rtspPort ports are open to the Bluecherry server!';
  }

  @override
  String serverAlreadyAdded(String serverName) {
    return 'The $serverName server is already added';
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
  String get noServersAvailable => 'Brak dostępnych serwerów';

  @override
  String get error => 'Błąd';

  @override
  String get videoError => 'An error happened while trying to play the video.';

  @override
  String copiedToClipboard(String message) {
    return 'Copied $message to clipboard';
  }

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Spróbuj ponownie';

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
    return 'Edit server settings';
  }

  @override
  String get removeCamera => 'Usuń kamerę';

  @override
  String get removePlayer => 'Remove all devices from this player';

  @override
  String get replaceCamera => 'Zastąp kamerę';

  @override
  String get reloadCamera => 'Odśwież kamerę';

  @override
  String get selectACamera => 'Wybierz kamerę';

  @override
  String get switchCamera => 'Przełącz kamerę';

  @override
  String get status => 'Status';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get live => 'NA ŻYWO';

  @override
  String get timedOut => 'PRZEKROCZONY CZAS';

  @override
  String get loading => 'ŁADOWANIE';

  @override
  String get recorded => 'NAGRANE';

  @override
  String get late => 'LATE';

  @override
  String get removeFromView => 'Usuń z widoku';

  @override
  String get addToView => 'Dodaj do widoku';

  @override
  String get addAllToView => 'Dodaj wszystkie do widoku';

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
  String get eventBrowser => 'Historia zdarzeń';

  @override
  String get eventsTimeline => 'Oś czasu zdarzeń';

  @override
  String get server => 'Serwer';

  @override
  String get device => 'Urządzenie';

  @override
  String get viewDeviceDetails => 'Device info';

  @override
  String get event => 'Zdarzenie';

  @override
  String get duration => 'Czas trwania';

  @override
  String get priority => 'Priorytet';

  @override
  String get next => 'Następny';

  @override
  String get previous => 'Poprzedni';

  @override
  String get lastImageUpdate => 'Ostatnia aktualizacja obrazu';

  @override
  String get fps => 'FPS';

  @override
  String get date => 'Data';

  @override
  String get time => 'Time';

  @override
  String get lastUpdate => 'Ostatnia aktualizacja';

  @override
  String screens(String layout) {
    return 'Ekrany';
  }

  @override
  String get directCamera => 'Kamera bezpośrednia';

  @override
  String get addServer => 'Dodaj serwer';

  @override
  String get settings => 'Ustawienia';

  @override
  String get noServersAdded => 'Nie dodano serwerów';

  @override
  String get howToAddServer => 'Go to the \"Add Server\" screen to add a server.';

  @override
  String get editServerInfo => 'Modyfikuj informację serwera';

  @override
  String editServer(String serverName) {
    return 'Modyfikuj serwer $serverName';
  }

  @override
  String get servers => 'Serwery';

  @override
  String nServers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n serwerów',
      one: '1 serwer',
      zero: 'Brak serwerów',
    );
    return '$_temp0';
  }

  @override
  String nDevices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n urządzeń',
      one: '1 urządzenie',
      zero: 'Brak urządzeń',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Usunąć ?';

  @override
  String removeServerDescription(String serverName) {
    return '$serverName zostanie usunięty z aplikacji. Nie będzie możliwości podglądu kamer z tego serwera oraz nie będą odbierane z niego powiadomienia.';
  }

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get about => 'O programie';

  @override
  String get versionText => 'Copyright © 2022, Bluecherry LLC.\nAll rights reserved.';

  @override
  String get gettingDevices => 'Pobieranie urządzeń...';

  @override
  String get noDevices => 'Brak urządzeń';

  @override
  String get noEventsLoaded => 'NIE ZAŁADOWANO ZDARZEŃ';

  @override
  String get noEventsLoadedTips => '•  Wybież kamery do podglądu zdarzeń\n•  Użyj kalnedarza żeby wybrać konkretną datę lub zakres \n•  Użyj przycisku \"Filtr\" aby wyszukiwać';

  @override
  String get timelineKeyboardShortcutsTips => '•  Use the space bar to play/pause the timeline\n•  Use the left and right arrow keys to move the timeline\n•  Use the M key to mute/unmute the timeline\n •  Use the mouse wheel to zoom in/out the timeline';

  @override
  String get invalidResponse => 'Odebrano nieprawidłową odpowiedź z serwera';

  @override
  String get cameraOptions => 'Opcje';

  @override
  String get showFullscreenCamera => 'Pokaż na pełnym ekranie';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get openInANewWindow => 'Otwórz w nowym oknie';

  @override
  String get enableAudio => 'Włącz dźwięk';

  @override
  String get disableAudio => 'Wyłącz dźwięk';

  @override
  String get addNewServer => 'Dodaj nowy serwer';

  @override
  String get disconnectServer => 'Rozłącz';

  @override
  String get serverOptions => 'Opcje serwera';

  @override
  String get browseEvents => 'Przegląd zdarzeń';

  @override
  String get eventType => 'Typ zdarzenia';

  @override
  String get configureServer => 'Konfiguracja serwera';

  @override
  String get refreshDevices => 'Odśwież urządzenia';

  @override
  String get refreshServer => 'Odśwież serwer';

  @override
  String get viewDevices => 'View devices';

  @override
  String serverDevices(String server) {
    return '$server devices';
  }

  @override
  String get refresh => 'Odśwież';

  @override
  String get view => 'Widok';

  @override
  String get cycle => 'Cykl';

  @override
  String fallbackLayoutName(int layout) {
    return 'Układ $layout';
  }

  @override
  String get newLayout => 'Nowy układ';

  @override
  String get editLayout => 'Zmień układ';

  @override
  String editSpecificLayout(String layoutName) {
    return 'Edit $layoutName';
  }

  @override
  String get exportLayout => 'Eksportuj układ';

  @override
  String get importLayout => 'Importuj układ';

  @override
  String failedToImportMessage(String layoutName, String server_ip, int server_port) {
    return 'Podczas próby importu $layoutName, zostało odnalezione urządzenie podłączone do serwera, z którym nie ma połączenia. Podłącz się do tego serwera i spróbuj ponownie.\nSerwer: $server_ip:$server_port';
  }

  @override
  String get layoutImportFileCorrupted => 'Plik, który próbujesz zaimportować jest uszkodzony lub brakuje informacji.';

  @override
  String layoutImportFileCorruptedWithMessage(Object message) {
    return 'Plik, który próbujesz zaimportować jest uszkodzony lub brakuje informacji: \"$message\"';
  }

  @override
  String get singleView => 'Widok pojedynczy';

  @override
  String get multipleView => 'Widok wielokrotny';

  @override
  String get compactView => 'Widok kompaktowy';

  @override
  String get createNewLayout => 'Utwórz nowy układ';

  @override
  String get layoutName => 'Nazwa układu';

  @override
  String get layoutNameHint => 'First floor';

  @override
  String get layoutTypeLabel => 'Typ układu';

  @override
  String clearLayout(int amount) {
    return 'Clear $amount devices';
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
  String get downloads => 'Pobrania';

  @override
  String get download => 'Pobierz';

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
  String get downloaded => 'Pobrane';

  @override
  String get downloading => 'Pobieranie';

  @override
  String get seeInDownloads => 'Zobacz w Pobranych';

  @override
  String get downloadPath => 'Katalog pobranych';

  @override
  String get delete => 'Usuń';

  @override
  String get showInFiles => 'Pokaż w Plikach';

  @override
  String get noDownloads => 'Jeszcze niczego nie pobrano :/';

  @override
  String nDownloadsProgress(int n) {
    return 'You have $n downloads in progress!';
  }

  @override
  String get howToDownload => 'Przejdź do ekranu \"Historii zdarzeń\" by pobrać zdarzenia.';

  @override
  String downloadTitle(String event, String device, String server, String date) {
    return '$event na $device serwer $server o $date';
  }

  @override
  String get playbackOptions => 'OPCJE ODTWARZANIA';

  @override
  String get play => 'Odtwarzaj';

  @override
  String get playing => 'Playing';

  @override
  String get pause => 'Pauza';

  @override
  String get paused => 'Paused';

  @override
  String volume(String v) {
    return 'Głośność • $v';
  }

  @override
  String speed(String s) {
    return 'Speed • $s';
  }

  @override
  String get noRecords => 'Ta kamera nie ma nagrań w tym zakresie.';

  @override
  String get filter => 'Filtr';

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
  String get dateTimeFilter => 'Date Time Filter';

  @override
  String get dateFilter => 'Date Filter';

  @override
  String get timeFilter => 'Filtr czasu';

  @override
  String get fromDate => 'Od';

  @override
  String get toDate => 'Do';

  @override
  String get today => 'Dziś';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get never => 'nigdy';

  @override
  String fromToDate(String from, String to) {
    return '$from do $to';
  }

  @override
  String get mostRecent => 'Most recent';

  @override
  String get allowAlarms => 'Zezwól na alarmy';

  @override
  String get nextEvents => 'Następne zdarzenia';

  @override
  String nEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n zdarzeń',
      one: '1 zdarzenie',
      zero: 'Brak zdarzeń',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Info';

  @override
  String get warn => 'Ostrzeżenie';

  @override
  String get alarm => 'Alarm';

  @override
  String get critical => 'Krytyczne';

  @override
  String get motion => 'Ruch';

  @override
  String get continuous => 'Ciągły';

  @override
  String get notFound => 'Nie znaleziono';

  @override
  String get cameraVideoLost => 'Utracone wideo';

  @override
  String get cameraAudioLost => 'Utracone audio';

  @override
  String get systemDiskSpace => 'Przestrzeń dyskowa';

  @override
  String get systemCrash => 'Błąd krytyczny';

  @override
  String get systemBoot => 'Uruchomienie';

  @override
  String get systemShutdown => 'Wyłączenie';

  @override
  String get systemReboot => 'Ponowne uruchomienie';

  @override
  String get systemPowerOutage => 'Utrata zasilania';

  @override
  String get unknown => 'Nieznany';

  @override
  String get close => 'Zamknij';

  @override
  String get closeAnyway => 'Close anyway';

  @override
  String get closeWhenDone => 'Close when done';

  @override
  String get open => 'Otwórz';

  @override
  String get collapse => 'Zwiń';

  @override
  String get expand => 'Rozwiń';

  @override
  String get more => 'More';

  @override
  String get isPtzSupported => 'Supports PTZ?';

  @override
  String get ptzSupported => 'PTZ jest wspierane';

  @override
  String get enabledPTZ => 'PTZ jest włączone';

  @override
  String get disabledPTZ => 'PTZ jest wyłączone';

  @override
  String get move => 'Ruch';

  @override
  String get stop => 'Stop';

  @override
  String get noMovement => 'Brak ruchu';

  @override
  String get moveNorth => 'Przesuń w górę';

  @override
  String get moveSouth => 'Przesuń w dół';

  @override
  String get moveWest => 'Przesuń na zachód';

  @override
  String get moveEast => 'Przesuń na wschód';

  @override
  String get moveWide => 'Oddal';

  @override
  String get moveTele => 'Przybliż';

  @override
  String get presets => 'Ustawienia wstępne';

  @override
  String get noPresets => 'Nie znaleziono ustawień wstępnych';

  @override
  String get newPreset => 'Nowe ustawienie wstępne';

  @override
  String get goToPreset => 'Idź do ustawienia wstępnego';

  @override
  String get renamePreset => 'Zmień nazwę ustawienia';

  @override
  String get deletePreset => 'Usuń ustawienie';

  @override
  String get refreshPresets => 'Odśwież ustawienia';

  @override
  String get resolution => 'Rozdzielczość';

  @override
  String get selectResolution => 'Wybierz rozdzielczość';

  @override
  String get setResolution => 'Ustaw rozdzielczość';

  @override
  String get setResolutionDescription => 'Rozdzielczość strumienia wideo może mieć duży wpływ na wydajność aplikacji. Ustaw niższą rozdzielczość aby przyspieszyć działanie lub wyższą żeby zwiększyć jakość obrazu. Można ustawić rozdzielczość domyślną dla każdej kamery w ustawieniach.';

  @override
  String get hd => 'Wysoka jakość';

  @override
  String get defaultResolution => 'Rozdzielczość domyślna';

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
  String get updates => 'Aktualizacje';

  @override
  String get upToDate => 'Aplikacja jest aktualna.';

  @override
  String lastChecked(String date) {
    return 'Sprawdzono: $date';
  }

  @override
  String get checkForUpdates => 'Sprawdź aktualizację';

  @override
  String get checkingForUpdates => 'Sprawdzanie aktualizacji';

  @override
  String get automaticDownloadUpdates => 'Pobieraj aktualizacje automatycznie';

  @override
  String get automaticDownloadUpdatesDescription => 'Bądź jedną z pierwszych osób, które otrzymają najnowsze aktualizacje, poprawki i ulepszenia w miarę ich wdrażania.';

  @override
  String get updateHistory => 'Historia aktualizacji';

  @override
  String get showReleaseNotes => 'Show release notes';

  @override
  String get showReleaseNotesDescription => 'Display release notes when a new version is installed';

  @override
  String get newVersionAvailable => 'Dostępna nowa wersja';

  @override
  String get installVersion => 'Instaluj';

  @override
  String get downloadVersion => 'Pobierz';

  @override
  String get learnMore => 'Dowiedz się więcej';

  @override
  String get failedToUpdate => 'Aktualizacja nieudana';

  @override
  String get executableNotFound => 'Nie odnaleziono programu';

  @override
  String runningOn(String platform) {
    return 'Uruchomiono na $platform';
  }

  @override
  String get windows => 'Windows';

  @override
  String linux(String env) {
    return 'Linux $env';
  }

  @override
  String get currentTasks => 'Bieżące zadania';

  @override
  String get noCurrentTasks => 'Brak zadań';

  @override
  String get taskFetchingEvent => 'Pobieranie zdarzeń';

  @override
  String get taskFetchingEventsPlayback => 'Pobieranie zdarzeń odtwarania';

  @override
  String get taskDownloadingEvent => 'Pobieranie zdarzenia';

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
  String get cycleTogglePeriod => 'Okres cyklicznego przełączania układu';

  @override
  String get cycleTogglePeriodDescription => 'The interval between layout changes when the cycle mode is enabled.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationClickBehavior => 'Zachowanie po kliknięciu na powiadomienie';

  @override
  String get notificationClickBehaviorDescription => 'Choose what happens when you click on a notification.';

  @override
  String get showEventsScreen => 'Pokaż historię zdarzeń';

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
  String get allowCloseWhenDownloading => 'Block the app from closing when there are ongoing downloads';

  @override
  String get events => 'Events';

  @override
  String get initialEventSpeed => 'Initial speed';

  @override
  String get initialEventVolume => 'Initial volume';

  @override
  String get differentEventColors => 'Different event colors';

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
  String get theme => 'Motyw';

  @override
  String get themeDescription => 'Zmień wygląd aplikacji';

  @override
  String get system => 'Systemowy';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

  @override
  String get dateAndTime => 'Date and Time';

  @override
  String get dateFormat => 'Format daty';

  @override
  String get dateFormatDescription => 'What format to use for displaying dates';

  @override
  String get timeFormat => 'Format czasu';

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
  String get defaultMatrixSize => 'Default Matrix Size';

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
  String get miscellaneous => 'Różne';

  @override
  String get wakelock => 'Keep screen on';

  @override
  String get wakelockDescription => 'Keep screen on while watching live streams or recordings.';

  @override
  String get snooze15 => '15 minut';

  @override
  String get snooze30 => '30 minut';

  @override
  String get snooze60 => '1 godzina';

  @override
  String get snoozeNotifications => 'Uśpij powiadomienia';

  @override
  String get notSnoozed => 'Nie usypiaj';

  @override
  String get snoozeNotificationsUntil => 'Uśpij powiadomienia do';

  @override
  String snoozedUntil(String time) {
    return 'Uśpiono do $time';
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
  String get renderingQualityDescription => 'The quality of the video rendering. The higher the quality, the more resources it takes.\nWhen automatic, the quality is selected based on the camera resolution.';

  @override
  String get cameraViewFit => 'Dopasowanie obrazu kamery';

  @override
  String get cameraViewFitDescription => 'The way the video is displayed in the view.';

  @override
  String get contain => 'Zawartość';

  @override
  String get fill => 'Wypełnienie';

  @override
  String get cover => 'Pokrycie';

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
  String get showMore => 'More options';

  @override
  String get showLess => 'Less options';

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
  String get licenses => 'Licenças';
}

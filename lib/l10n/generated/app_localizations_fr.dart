// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcome => 'Bienvenue';

  @override
  String get welcomeDescription => 'Bienvenue sur le DVR de surveillance Bluecherry !\nConnectons-nous rapidement à votre serveur DVR.';

  @override
  String get configure => 'Configurer un serveur DVR';

  @override
  String get configureDescription => 'Configurons une connexion à votre serveur DVR distant. Vous pouvez vous connecter à un nombre illimité de serveurs depuis n\'importe où dans le monde.';

  @override
  String get hostname => 'Nom d\'hôte';

  @override
  String get hostnameExample => 'demo.bluecherry.app';

  @override
  String get port => 'Port';

  @override
  String get rtspPort => 'Port RTSP';

  @override
  String get serverName => 'Nom du serveur';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameHint => 'Admin';

  @override
  String get password => 'Mot de passe';

  @override
  String get savePassword => 'Sauvegarder mot de passe';

  @override
  String get showPassword => 'Afficher mot de passe';

  @override
  String get hidePassword => 'Masquer mot de passe';

  @override
  String get hide => 'Montrer';

  @override
  String get show => 'Cacher';

  @override
  String get useDefault => 'Par défaut';

  @override
  String get connect => 'Connecter';

  @override
  String get connectAutomaticallyAtStartup => 'Connecter automatiquement au démarrage';

  @override
  String get connectAutomaticallyAtStartupDescription => 'Lorsque activé, l\'application se connectra automatiquement au serveur à l\'ouverture.';

  @override
  String get checkingServerCredentials => 'Vérification des informations d\'identification.';

  @override
  String get skip => 'Sauter';

  @override
  String get cancel => 'Annuler';

  @override
  String get disabled => 'Désactivé';

  @override
  String get letsGo => 'C\'EST PARTI!';

  @override
  String get finish => 'Terminé';

  @override
  String get letsGoDescription => 'Voici quelques astuces pour bien commencer:';

  @override
  String get projectName => 'Bluecherry';

  @override
  String get projectDescription => 'Puissant logiciel de surveillance vidéo';

  @override
  String get website => 'Site internet';

  @override
  String get purchase => 'Acheter';

  @override
  String get tip0 => 'Les caméras sont listés à gauche. Double-cliquez ou glissez une caméra sur la vue en direct pour la voir.';

  @override
  String get tip1 => 'Utilisez les boutons au dessus de la vue en direct pour créer, sauvegarder et charger une disposition - même avec des caméras provenant de plusieurs serveurs.';

  @override
  String get tip2 => 'Double-cliquez sur un serveur pour ouvrir sa page de configuration dans une nouvelle fenêtre où vous pourrez configurer les caméras et les enregistrements.';

  @override
  String get tip3 => 'Cliquez sur l\'icône navigateur d\'événements pour ouvrir l\'historique et regarder ou sauvegarder les enregistrements.';

  @override
  String errorTextField(String field) {
    return '$field n\'est pas entré.';
  }

  @override
  String get serverAdded => 'Le serveur à été ajouté';

  @override
  String serverNotAddedError(String serverName) {
    return '$serverName n\'a pas pu être ajouté. S.V.P. vérifiez les informations entrées.';
  }

  @override
  String serverNotAddedErrorDescription(String port, String rtspPort) {
    return 'S.V.P. vérifiez les informations entrées et assurez-vous que le serveur est en ligne.\n\nSi vous-vous connectez à distance, vérifiez que les ports $port et $rtspPort sont ouverts sur le serveur Bluecherry!';
  }

  @override
  String serverAlreadyAdded(String serverName) {
    return 'Le serveur $serverName a déjà été ajouté';
  }

  @override
  String get serverVersionMismatch => 'Vous avez essayé d\'ajouter un serveur d\'une version non supportée. S.V.P. Mettez à jour le serveur et ré-essayez!';

  @override
  String get serverVersionMismatchShort => 'Version du serveur non suportée';

  @override
  String get serverWrongCredentials => 'Les identifiants pour le serveur sont incorrects. Veuillez vérifier le nom d\'utilisateur et le mot de passe, puis réessayer.';

  @override
  String get serverWrongCredentialsShort => 'Identifiants incorrects. Veuillez vérifier le nom d\'utilisateur et le mot de passe.';

  @override
  String get noServersAvailable => 'Aucun serveur disponible';

  @override
  String get error => 'Erreur';

  @override
  String get videoError => 'Une erreur est survenue lors de la lecture de la vidé.';

  @override
  String copiedToClipboard(String message) {
    return 'Copié $message au presse-papier';
  }

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Réessayer';

  @override
  String get clear => 'Vider';

  @override
  String get serverSettings => 'Paramètres du serveur';

  @override
  String get serverSettingsDescription => 'Les paramètres seront appliqués seulement sur ce serveur. Si elles ne sont pas fournies, les valeurs des paramètres généraux seront utilisées. Vous pouvez modifier ces valeurs ultérieurement.';

  @override
  String get editServerSettingsInfo => 'Modifier les informations du serveur';

  @override
  String editServerSettings(String serverName) {
    return 'Modifier les paramètres du serveur';
  }

  @override
  String get removeCamera => 'Enlever caméra';

  @override
  String get removePlayer => 'Supprimer tous les appareils de ce lecteur';

  @override
  String get replaceCamera => 'Remplacer caméra';

  @override
  String get reloadCamera => 'Recharger caméra';

  @override
  String get selectACamera => 'Sélectionner une caméra';

  @override
  String get switchCamera => 'Échanger la caméra';

  @override
  String get status => 'Status';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get live => 'EN DIRECT';

  @override
  String get timedOut => 'EXPIRÉ';

  @override
  String get loading => 'CHARGEMENT';

  @override
  String get recorded => 'ENREGISTREMENT';

  @override
  String get late => 'RETARD';

  @override
  String get removeFromView => 'Retirer de la vue';

  @override
  String get addToView => 'Ajouter à la vue';

  @override
  String get addAllToView => 'Tout ajouter à la vue';

  @override
  String get removeAllFromView => 'Tout retirer de la vue';

  @override
  String get streamName => 'Nom du flux';

  @override
  String get streamNameRequired => 'Un nom de flux est requis';

  @override
  String get streamURL => 'URL du Flux';

  @override
  String get streamURLRequired => 'L\'URL du Flux est requis';

  @override
  String get streamURLNotValid => 'L\'URL du Flux est invalide';

  @override
  String get uri => 'URI';

  @override
  String get oldestRecording => 'Oldest recording';

  @override
  String get eventBrowser => 'Navigateur d\'événements';

  @override
  String get eventsTimeline => 'Ligne du temps';

  @override
  String get server => 'Serveur';

  @override
  String get device => 'Appareil';

  @override
  String get viewDeviceDetails => 'Info d\'appareil';

  @override
  String get event => 'Évènement';

  @override
  String get duration => 'Durée';

  @override
  String get priority => 'Priorité';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get lastImageUpdate => 'Dernier rafraîchissement';

  @override
  String get fps => 'FPS';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get lastUpdate => 'Dernière mise à jour';

  @override
  String screens(String layout) {
    return 'Écrans';
  }

  @override
  String get directCamera => 'Caméra direct';

  @override
  String get addServer => 'Ajouter serveur';

  @override
  String get settings => 'Paramètres';

  @override
  String get noServersAdded => 'Aucun serveur ajouté';

  @override
  String get howToAddServer => 'Aller à la section \"Ajouter serveur\" pout ajouter un serveur.';

  @override
  String get editServerInfo => 'Modifier les info serveur';

  @override
  String editServer(String serverName) {
    return 'Modifier le serveur $serverName';
  }

  @override
  String get servers => 'Serveurs';

  @override
  String nServers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n serveurs',
      one: '1 serveur',
      zero: 'Aucun serveur',
    );
    return '$_temp0';
  }

  @override
  String nDevices(int n) {
    return '$n appareils';
  }

  @override
  String get remove => 'Retirer ?';

  @override
  String removeServerDescription(String serverName) {
    return '$serverName sera retiré de l\'application. Vous ne pourrez plus voir les caméras de ce serveur et ne pourrez plus recevoir des notifications.';
  }

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get about => 'À propos';

  @override
  String get versionText => 'Copyright © 2022, Bluecherry LLC.\nTout droit réservé.';

  @override
  String get gettingDevices => 'Obtention des appareils...';

  @override
  String get noDevices => 'Aucun appareil';

  @override
  String get noEventsLoaded => 'AUCUN ÉVÈNEMENT CHARGÉ';

  @override
  String get noEventsLoadedTips => '•  Sélectionnez la caméra dont vous voulez voir les evènements\n•  Utilisez le calendrier pour sélectionner une date précise ou une période entre deux dates \n•  Utilisez le bouton \"Filtre\" pour effectuer une recherche';

  @override
  String get timelineKeyboardShortcutsTips => '•  Utilisez la barre d\'espace pour lire/mettre en pause la ligne du temps\n•  Utilisez les flèches gauche et droite pour déplacer la ligne du temps\n•  Utilisez la touche M pour activer/désactiver le son de la ligne du temps\n •  Utilisez la molette de la souris pour zoomer/dézoomer sur la ligne du temps';

  @override
  String get invalidResponse => 'Réponse invalide reçu du serveur';

  @override
  String get cameraOptions => 'Options';

  @override
  String get showFullscreenCamera => 'Montrer en plein écran';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get openInANewWindow => 'Ouvrir dans une nouvelle fenêtre';

  @override
  String get enableAudio => 'Activer l\'audio';

  @override
  String get disableAudio => 'Désactiver l\'audio';

  @override
  String get addNewServer => 'Ajouter un nouveau serveur';

  @override
  String get disconnectServer => 'Déconnecter';

  @override
  String get serverOptions => 'Options serveur';

  @override
  String get browseEvents => 'Naviguer les événements';

  @override
  String get eventType => 'Type d\'événement';

  @override
  String get configureServer => 'Configurer le serveur';

  @override
  String get refreshDevices => 'Actualiser les appareils';

  @override
  String get refreshServer => 'Actualiser le serveur';

  @override
  String get viewDevices => 'Voir les appareils';

  @override
  String serverDevices(String server) {
    return 'Appareil $server';
  }

  @override
  String get refresh => 'Actualiser';

  @override
  String get view => 'Vue';

  @override
  String get cycle => 'Cycle';

  @override
  String fallbackLayoutName(int layout) {
    return 'Disposition $layout';
  }

  @override
  String get newLayout => 'Nouvelle disposition';

  @override
  String get editLayout => 'Modifier disposition';

  @override
  String editSpecificLayout(String layoutName) {
    return 'Modifier $layoutName';
  }

  @override
  String get exportLayout => 'Exporter la disposition';

  @override
  String get importLayout => 'Importer la disposition';

  @override
  String failedToImportMessage(String layoutName, String server_ip, int server_port) {
    return 'En essayant d\'importer $layoutName, nous avons trouvé un appareil qui est connecté à un serveur auquel vous n\'êtes pas connecté. S.V.P. connectez-vous au serveur et réessayez.\nServeur: $server_ip:$server_port';
  }

  @override
  String get layoutImportFileCorrupted => 'Le fichier que vous essayez d\'importer est corrompu ou a une information manquante.';

  @override
  String layoutImportFileCorruptedWithMessage(Object message) {
    return 'Le fichier que vous essayez d\'importer est corrompu ou a une information manquante: \"$message\"';
  }

  @override
  String get singleView => 'Vue unique';

  @override
  String get multipleView => 'Vue multiple';

  @override
  String get compactView => 'Vue compacte';

  @override
  String get createNewLayout => 'Créer une nouvelle disposition';

  @override
  String get layoutName => 'Nom de la disposition';

  @override
  String get layoutNameHint => 'Premier étage';

  @override
  String get layoutTypeLabel => 'Type de disposition';

  @override
  String clearLayout(int amount) {
    return 'Enlever $amount appareils';
  }

  @override
  String get switchToNext => 'Passer au suivant';

  @override
  String get unlockLayout => 'Unlock layout';

  @override
  String get lockLayout => 'Lock layout';

  @override
  String layoutVolume(int volume) {
    return 'Layout Volume • $volume%';
  }

  @override
  String get downloads => 'Téléchargements';

  @override
  String get download => 'Télécharger';

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
  String get downloaded => 'Téléchargé';

  @override
  String get downloading => 'En téléchargement';

  @override
  String get seeInDownloads => 'Voir dans téléchargements';

  @override
  String get downloadPath => 'Emplacement de téléchargement';

  @override
  String get delete => 'Supprimer';

  @override
  String get showInFiles => 'Afficher dans le dossier';

  @override
  String get noDownloads => 'Vous n\'avez aucun téléchargements';

  @override
  String nDownloadsProgress(int n) {
    return 'Vous avez $n téléchargements en cours!';
  }

  @override
  String get howToDownload => 'Allez à la vue \"Navigateur d\'évènements\" pour télécharger des évènements.';

  @override
  String downloadTitle(String event, String device, String server, String date) {
    return '$event sur $device du serveur $server à $date';
  }

  @override
  String get playbackOptions => 'OPTION DE LECTURE';

  @override
  String get play => 'Jouer';

  @override
  String get playing => 'En lecture';

  @override
  String get pause => 'Pause';

  @override
  String get paused => 'En pause';

  @override
  String volume(String v) {
    return 'Volume • $v';
  }

  @override
  String speed(String s) {
    return 'Vitesse • $s';
  }

  @override
  String get noRecords => 'Cette caméra n\'a aucun enregistrement pour la période actuelle';

  @override
  String get filter => 'Filtre';

  @override
  String loadEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Charger depuis $n appareils',
      one: 'Charger depuis un appareil',
      zero: 'Charger',
    );
    return '$_temp0';
  }

  @override
  String get period => 'Période';

  @override
  String get dateTimeFilter => 'Filtre de temps et date';

  @override
  String get dateFilter => 'Filtre de Date';

  @override
  String get timeFilter => 'Filtre par période';

  @override
  String get fromDate => 'De';

  @override
  String get toDate => 'À';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get never => 'Jamais';

  @override
  String fromToDate(String from, String to) {
    return '$from à $to';
  }

  @override
  String get mostRecent => 'Plus récent';

  @override
  String get allowAlarms => 'Permettre les alarmes';

  @override
  String get nextEvents => 'Prochains évènements';

  @override
  String nEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n évènements',
      one: '1 évènement',
      zero: 'Aucun évènement',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Information';

  @override
  String get warn => 'Avertissement';

  @override
  String get alarm => 'Alarme';

  @override
  String get critical => 'Critique';

  @override
  String get motion => 'Mouvement';

  @override
  String get continuous => 'Continu';

  @override
  String get notFound => 'Non trouvé';

  @override
  String get cameraVideoLost => 'Perte de la vidéo';

  @override
  String get cameraAudioLost => 'Perte de l\'audio';

  @override
  String get systemDiskSpace => 'Espace disque';

  @override
  String get systemCrash => 'Crash';

  @override
  String get systemBoot => 'Démarrage';

  @override
  String get systemShutdown => 'Mise hors tension';

  @override
  String get systemReboot => 'Redémarrage';

  @override
  String get systemPowerOutage => 'Perte de courant';

  @override
  String get unknown => 'Inconnu';

  @override
  String get close => 'Ouvert';

  @override
  String get closeAnyway => 'Fermer quand même';

  @override
  String get closeWhenDone => 'Fermer lorsque terminé';

  @override
  String get open => 'Ouvrir';

  @override
  String get collapse => 'Réduire';

  @override
  String get expand => 'Développer';

  @override
  String get more => 'Plus';

  @override
  String get isPtzSupported => 'Support PTZ?';

  @override
  String get ptzSupported => 'PTZ est supporté';

  @override
  String get enabledPTZ => 'PTZ est activé';

  @override
  String get disabledPTZ => 'PTZ est désactivé';

  @override
  String get move => 'Mouvement';

  @override
  String get stop => 'Arrêt';

  @override
  String get noMovement => 'Pas de mouvement';

  @override
  String get moveNorth => 'Haut';

  @override
  String get moveSouth => 'Bas';

  @override
  String get moveWest => 'Ouest';

  @override
  String get moveEast => 'Est';

  @override
  String get moveWide => 'Zoom arrière';

  @override
  String get moveTele => 'Zoom avant';

  @override
  String get presets => 'Préréglages';

  @override
  String get noPresets => 'Aucun préréglage trouvé';

  @override
  String get newPreset => 'Nouveau préréglage';

  @override
  String get goToPreset => 'Aller au préréglage';

  @override
  String get renamePreset => 'Renommer préréglage';

  @override
  String get deletePreset => 'Supprimer préréglage';

  @override
  String get refreshPresets => 'Rafraîchir préréglage';

  @override
  String get resolution => 'Résolution';

  @override
  String get selectResolution => 'Sélectionner la résolution';

  @override
  String get setResolution => 'Configurer la résolution';

  @override
  String get setResolutionDescription => 'La résolution peut impacter grandement la performance de l\'application. Choisissez une plus petite résolution pour améliorer les performances, ou une plus haute pour améliorer la qualité. Vous pouvez choisir la résolution par défaut pour chaque caméra dans les paramètres.';

  @override
  String get hd => 'Haute définition';

  @override
  String get defaultResolution => 'Résolution par défaut';

  @override
  String get automaticResolution => 'Automatique';

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
  String get updates => 'Mises à jour';

  @override
  String get upToDate => 'Vous êtes à jour.';

  @override
  String lastChecked(String date) {
    return 'Dernière vérification: $date';
  }

  @override
  String get checkForUpdates => 'Vérifier les mises à jour';

  @override
  String get checkingForUpdates => 'Vérification des mises à jour';

  @override
  String get automaticDownloadUpdates => 'Téléchargement automatique des mises à jour';

  @override
  String get automaticDownloadUpdatesDescription => 'Faites parti des premiers à recevoir les dernières mises à jour, correctifs et améliorations quand elles sortent.';

  @override
  String get updateHistory => 'Historique de mises à jour';

  @override
  String get showReleaseNotes => 'Voir les notes de versions';

  @override
  String get showReleaseNotesDescription => 'Afficher les notes de version lors de l\'installation d\'une nouvelle version';

  @override
  String get newVersionAvailable => 'Nouvelle version disponible';

  @override
  String get installVersion => 'Installer';

  @override
  String get downloadVersion => 'Télécharger';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get failedToUpdate => 'Échec de la mise à jour';

  @override
  String get executableNotFound => 'Exécutable non trouvé';

  @override
  String runningOn(String platform) {
    return 'Fonctionnant sur $platform';
  }

  @override
  String get windows => 'Windows';

  @override
  String linux(String env) {
    return 'Linux $env';
  }

  @override
  String get currentTasks => 'Tâche courante';

  @override
  String get noCurrentTasks => 'Aucune tâche';

  @override
  String get taskFetchingEvent => 'Récupération des évènements';

  @override
  String get taskFetchingEventsPlayback => 'Récupération de la lecture des évènements';

  @override
  String get taskDownloadingEvent => 'Téléchargement de l\'évènement';

  @override
  String get defaultField => 'Par défaut';

  @override
  String get general => 'Général';

  @override
  String get generalSettingsSuggestion => 'Notifications, Utilisation des données, Mise en veille, etc';

  @override
  String get serverAndDevices => 'Serveurs et Appareils';

  @override
  String get serverAndDevicesSettingsSuggestion => 'Connexions aux serveurs, Gestiond es appareils, etc';

  @override
  String get eventsAndDownloads => 'Évènements et téléchargements';

  @override
  String get eventsAndDownloadsSettingsSuggestion => 'Historique d\'évènements, téléchargements, etc';

  @override
  String get application => 'Application';

  @override
  String get applicationSettingsSuggestion => 'Apparence, thème, temps et date, etc';

  @override
  String get privacyAndSecurity => 'Sécurité et vie Privée';

  @override
  String get privacyAndSecuritySettingsSuggestion => 'Collecte de données, rapports d\'erreur, etc';

  @override
  String get updatesHelpAndPrivacy => 'Mises à jour, Aide et Confidentialité.';

  @override
  String get updatesHelpAndPrivacySettingsSuggestion => 'Vérifier les mises à jour, historique des mises à jour, politique de confidentialité, etc.';

  @override
  String get advancedOptions => 'Options avancées';

  @override
  String get advancedOptionsSettingsSuggestion => 'Fonctionalitées en Beta, Options de dévelopeur, etc';

  @override
  String get cycleTogglePeriod => 'Durée du cycle de basculement';

  @override
  String get cycleTogglePeriodDescription => 'Intervalle de temps entre les changements de disposition quand le mode cycle est activé.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notifications activées';

  @override
  String get notificationClickBehavior => 'Action de clic sur les notifications';

  @override
  String get notificationClickBehaviorDescription => 'Choisir ce qui se passe lorsque vous cliquez sur une notification.';

  @override
  String get showEventsScreen => 'Montrer le navigateur d\'événements';

  @override
  String get dataUsage => 'Utilisation de données';

  @override
  String get streamsOnBackground => 'Garder les flux actif en arrière-plan';

  @override
  String get streamsOnBackgroundDescription => 'Garder ou non les flux actif lorsque l\'application est en arrière-plan';

  @override
  String get automatic => 'Automatique';

  @override
  String get wifiOnly => 'Sur Wifi seulement';

  @override
  String get chooseEveryDownloadsLocation => 'Choisir l\'emplacement pour chaque téléchargements';

  @override
  String get chooseEveryDownloadsLocationDescription => 'Choisir l\'emplacement de chaque téléchargements ou utiliser l\'emplacement par défaut. Lorsque activé vous devrez choisir l\'emplacement pour chaque téléchargements.';

  @override
  String get allowCloseWhenDownloading => 'Empêcher l\'application de fermer lors d\'un téléchargement';

  @override
  String get events => 'Évènements';

  @override
  String get initialEventSpeed => 'Vitesse initiale';

  @override
  String get initialEventVolume => 'Volume initial';

  @override
  String get differentEventColors => 'Couleur différentes par évènements';

  @override
  String get differentEventColorsDescription => 'Afficher ou non les évènements différents en couleurs différentes. Cette option aide à diférentier les évènements.';

  @override
  String get initialTimelinePoint => 'Point Initial';

  @override
  String get initialTimelinePointDescription => 'Point initial de la ligne du temps.';

  @override
  String get beginningInitialPoint => 'Commencement';

  @override
  String get firstEventInitialPoint => 'Premier évènement';

  @override
  String get hourAgoInitialPoint => 'Il y a 1 heure';

  @override
  String get automaticallySkipEmptyPeriods => 'Automatically skip empty periods';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeDescription => 'Modifier l\'apparence de l\'application';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get dateAndTime => 'Temps et Date';

  @override
  String get dateFormat => 'Format de la date';

  @override
  String get dateFormatDescription => 'Quel format utiliser pour la date';

  @override
  String get timeFormat => 'Format de l\'heure';

  @override
  String get timeFormatDescription => 'Quel format utiliser pour l\'heure';

  @override
  String get convertToLocalTime => 'Convertir le temps à l\'heure locale';

  @override
  String get convertToLocalTimeDescription => 'Convertir les temps affichés à l\'heure locale. Cette option affecte l\'heure et la date affichée dans l\'application. Cette option est utile si le serveur est situé dans un autre fuseau horaire.';

  @override
  String get allowDataCollection => 'Permettre à Bluecherry de collecter des données d\'utilisation';

  @override
  String get allowDataCollectionDescription => 'Permettre à Bluecherry de collecter des données améliore l\'application et fournit un meilleur service. Les données collectées ne contiennent aucune information personnelle.';

  @override
  String get automaticallyReportErrors => 'Signaler automatiquement les erreurs';

  @override
  String get automaticallyReportErrorsDescription => 'Envoyer automatiquement les rapports d\'erreurs à Bluecherry pour aider à améliorer l\'application. Les rapports d\'erreur peuvent contenir des informations personnelles.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions \'utilisations';

  @override
  String get matrixMagnification => 'Zone d\'agrandissement';

  @override
  String get matrixedViewMagnification => 'Activer la zone d\'agrandissement';

  @override
  String get matrixedViewMagnificationDescription => 'Agrandi une zone de la matrice lorsque sélectionné. Cete option est utile lorsque vous avez beaucoup de caméras et souhaitez voir une zone spécifique de façon détaillée, ou quand les flux multiples sont fourni.';

  @override
  String get matrixType => 'Type de matrice';

  @override
  String get defaultMatrixSize => 'Taille de matrice par défaut';

  @override
  String get softwareMagnification => 'Agrandissement logiciel';

  @override
  String get softwareMagnificationDescription => 'Lorsque cette option est activée, l\'agrandissement ne sera pas effectuée sur le GPU. Cela est utile lorsque la magnification matérielle ne fonctionne pas correctement..';

  @override
  String get softwareMagnificationDescriptionMacOS => 'Lorsque cette option est activée, l\'agrandissement ne sera pas effectué sur le GPU. Cela est utile lorsque l\'agrandissement matériel ne fonctionne pas correctement. Sur macOS, cette option ne peut pas être désactivée.';

  @override
  String get eventMagnification => 'Agrandissement des évènements';

  @override
  String get eventMagnificationDescription => 'Agrandir la vidéo de l\'événement lorsqu\'elle est sélectionnée. Cette option est utile lorsque vous souhaitez voir l\'événement en plus de détail.';

  @override
  String get developerOptions => 'Options de développement';

  @override
  String get openLogFile => 'Ovrir les fichiers logs';

  @override
  String get openAppDataDirectory => 'Ouvrir le répertoir de l\'application';

  @override
  String get importConfigFile => 'Importer un fichier de configuration';

  @override
  String get importConfigFileDescription => 'Importer un fichier de configuration .bluecherry contenant des informations de flux.';

  @override
  String get debugInfo => 'Informations de débogage';

  @override
  String get debugInfoDescription => 'Affiche les informations utiles pour le débogage, tel que les métadonnées vidéo et autres informations utiles au débogage.';

  @override
  String get restoreDefaults => 'Paramètres par défaut';

  @override
  String get restoreDefaultsDescription => 'Restaure tous les paramètres à leur valeur par défaut. Cette option n\'affecte pas les serveurs que vous avez ajoutés.';

  @override
  String get areYouSure => 'Êtes-vous certain?';

  @override
  String get areYouSureDescription => 'Ceci restaurera tous les paramètres à leur valeur par défaut. Vos serveurs et autres données ne seront aps affectés.';

  @override
  String get miscellaneous => 'Divers';

  @override
  String get wakelock => 'Garder l\'écran allumé';

  @override
  String get wakelockDescription => 'Empêche l\'écran de séteindre lors du visonnement d\'un flux ou d\'un enregistrement';

  @override
  String get snooze15 => '15 minutes';

  @override
  String get snooze30 => '30 minutes';

  @override
  String get snooze60 => '1 heure';

  @override
  String get snoozeNotifications => 'Mise en pause des notifications';

  @override
  String get notSnoozed => 'Notifications actives';

  @override
  String get snoozeNotificationsUntil => 'Notifications en pause jusqu\'à';

  @override
  String snoozedUntil(String time) {
    return 'Mis en pause jusqu\'à $time';
  }

  @override
  String get connectToServerAutomaticallyAtStartup => 'Connecter automatiquement au démarrage';

  @override
  String get connectToServerAutomaticallyAtStartupDescription => 'Si activée, la connexion au serveur sera automatique au démarrage de l\'application. Cela ne s\'applique qu\'aux nouveaux serveurs que vous ajoutez.';

  @override
  String get allowUntrustedCertificates => 'Permettre les certificats non fiables';

  @override
  String get allowUntrustedCertificatesDescription => 'Autoriser la connexion à des serveurs avec des certificats non fiables. Cela est utile lorsque vous utilisez des certificats auto-signés ou des certificats provenant d\'autorités inconnues.';

  @override
  String get certificateNotPassed => 'Certificat non validé';

  @override
  String get addServerTimeout => 'Add server timeout';

  @override
  String get addServerTimeoutDescription => 'The time to wait for the server to respond when adding a new server.';

  @override
  String get streamingSettings => 'Paramètre de diffusion';

  @override
  String get streamingProtocol => 'Protocol de diffusion';

  @override
  String get preferredStreamingProtocol => 'Protocol de diffusion préféré';

  @override
  String get preferredStreamingProtocolDescription => 'Quel protocole de streaming vidéo sera utilisé. Si le serveur ne prend pas en charge le protocole sélectionné, l\'application essaiera d\'utiliser le suivant. Il est possible de sélectionner un protocole spécifique pour chaque appareil dans ses paramètres.';

  @override
  String get rtspProtocol => 'Protocole RTSP';

  @override
  String get camerasSettings => 'Paramètres des caméras';

  @override
  String get renderingQuality => 'Qualité du rendu';

  @override
  String get renderingQualityDescription => 'Qualité du rendu vidéo. Une qualité plus haute consomme plus de ressources.\nQuand elle est automatique, la qualité est basée sur la résolution de la caméra.';

  @override
  String get cameraViewFit => 'Ajustement de la vue caméra';

  @override
  String get cameraViewFitDescription => 'La façon dont la vidéo est affichée dans la vue.';

  @override
  String get contain => 'Contenir';

  @override
  String get fill => 'Remplir';

  @override
  String get cover => 'Couvrir';

  @override
  String get streamRefreshPeriod => 'Période de rafraîchissement des flux';

  @override
  String get streamRefreshPeriodDescription => 'L\'intervalle entre les actualisations de l\'appareil. Cela garantit que la vidéo de la caméra reste valide de temps en temps.';

  @override
  String get lateStreamBehavior => 'Comportement du retard de flux';

  @override
  String get lateStreamBehaviorDescription => 'Quoi faire lorsque un flux est en retard';

  @override
  String get automaticBehavior => 'Automatique';

  @override
  String get automaticBehaviorDescription => 'L\'application essaiera de repositionner le flux automatiquement';

  @override
  String get manualBehavior => 'Manuel';

  @override
  String manualBehaviorDescription(String label) {
    return 'Appuyez sur $label pour repositionner le flux';
  }

  @override
  String get neverBehaviorDescription => 'L\'application n\'essaiera pas de repositionner le flux';

  @override
  String get devicesSettings => 'Paramètres d\'appareils';

  @override
  String get listOfflineDevices => 'Lister les appareils hors ligne';

  @override
  String get listOfflineDevicesDescriptions => 'Afficher ou non les appareils hors ligne dans la liste des appareils.';

  @override
  String get initialDeviceVolume => 'Volume initial des appareils';

  @override
  String get runVideoTest => 'Lancer un test vidéo';

  @override
  String get runVideoTestDescription => 'Lancer un test vidéo pour vérifier l\'état de fonctionnement de la lecture.';

  @override
  String get showCameraName => 'Montrer le nom de la caméra';

  @override
  String get always => 'Toujours';

  @override
  String get onHover => 'Au survol';

  @override
  String get dateLanguage => 'Date et Langue';

  @override
  String get language => 'Langue';

  @override
  String get overlays => 'Superposition';

  @override
  String get visible => 'Visible';

  @override
  String nOverlay(int n) {
    return 'Superposition $n';
  }

  @override
  String overlayPosition(double x, double y) {
    return 'Position (x: $x, y: $y)';
  }

  @override
  String get externalStream => 'Flux externe';

  @override
  String get addExternalStream => 'Ajouter un flu externe';

  @override
  String get showMore => 'Plus d\'options';

  @override
  String get showLess => 'Moins d\'options';

  @override
  String get serverHostname => 'nom d\'hôte du serveur';

  @override
  String get serverHostnameExample => 'https://mon-serveur.bluecherry.app:7001';

  @override
  String get rackName => 'Nom de l\'emplacement';

  @override
  String get rackNameExample => 'Labo 1';

  @override
  String get openServer => 'Ouvrir le serveur';

  @override
  String get disableSearch => 'Désactiver la recherche';

  @override
  String get help => 'Aide';

  @override
  String get licenses => 'Licenses';
}

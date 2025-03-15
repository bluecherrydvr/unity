// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get welcome => 'Bem vindo!';

  @override
  String get welcomeDescription => 'Seja bem vindo ao Bluecherry Surveillance DVR!\nVamos conectar ao seu servidor DVR em um instante!';

  @override
  String get configure => 'Configure um Servidor DVR';

  @override
  String get configureDescription => 'Configure uma conexão com seu servidor DVR remoto. Você pode se conectar a quantos servidores quiser de qualquer lugar do mundo.';

  @override
  String get hostname => 'Hostname';

  @override
  String get hostnameExample => 'demo.bluecherry.app';

  @override
  String get port => 'Porta';

  @override
  String get rtspPort => 'Porta RTSP';

  @override
  String get serverName => 'Nome do servidor';

  @override
  String get username => 'Nome de usuário';

  @override
  String get usernameHint => 'Admin';

  @override
  String get password => 'Senha';

  @override
  String get savePassword => 'Salvar senha';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get hide => 'Esconder';

  @override
  String get show => 'Mostrar';

  @override
  String get useDefault => 'Usar Padrão';

  @override
  String get connect => 'Conectar';

  @override
  String get connectAutomaticallyAtStartup => 'Conectar automaticamente ao iniciar';

  @override
  String get connectAutomaticallyAtStartupDescription => 'Se ativado, o servidor será conectado automaticamente quando o aplicativo for iniciado.';

  @override
  String get checkingServerCredentials => 'Verificando credenciais';

  @override
  String get skip => 'Pular';

  @override
  String get cancel => 'Cancelar';

  @override
  String get disabled => 'Desativado';

  @override
  String get letsGo => 'Vamos lá!';

  @override
  String get finish => 'Concluir';

  @override
  String get letsGoDescription => 'Aqui algumas dicas de como começar:';

  @override
  String get projectName => 'Bluecherry';

  @override
  String get projectDescription => 'Powerful Video Surveillance Software';

  @override
  String get website => 'Website';

  @override
  String get purchase => 'Compras';

  @override
  String get tip0 => 'Câmeras são mostradas à esquerda. Você pode dar dois cliques ou arrastar a câmera até a visualização para vê-la.';

  @override
  String get tip1 => 'Use os botões acima das câmeras para criar, salvar e alterar layouts - mesmo com câmeras de múltiplos servidores.';

  @override
  String get tip2 => 'Dê dois cliques em um servidor para abrir sua página de configuração em uma nova janela, onde você pode configurar câmeras e gravações.';

  @override
  String get tip3 => 'Aperte o ícone de eventos para abrir o histórico e assistir ou baixar as gravações.';

  @override
  String errorTextField(String field) {
    return '$field não pode estar vazio.';
  }

  @override
  String get serverAdded => 'Servidor adicionado';

  @override
  String serverNotAddedError(String serverName) {
    return '$serverName não pôde ser adicionado.';
  }

  @override
  String serverNotAddedErrorDescription(String port, String rtspPort) {
    return 'Please check the entered details and ensure the server is online.\n\nIf you are connecting remote, make sure the $port and $rtspPort ports are open to the Bluecherry server!';
  }

  @override
  String serverAlreadyAdded(String serverName) {
    return 'O $serverName servidor já foi adicionado.';
  }

  @override
  String get serverVersionMismatch => 'O versão do servidor não é suportada. Por favor, atualize seu servidor e tente novamente!';

  @override
  String get serverVersionMismatchShort => 'Versão do servidor não suportada.';

  @override
  String get serverWrongCredentials => 'As credenciais do servidor estão incorretas. Por favor, verifique o nome de usuário e a senha e tente novamente.';

  @override
  String get serverWrongCredentialsShort => 'Credenciais incorretas. Por favor, verifique o nome de usuário e a senha.';

  @override
  String get noServersAvailable => 'Nenhum servidor disponível.';

  @override
  String get error => 'Erro';

  @override
  String get videoError => 'Ocorreu um erro ao tentar reproduzir o vídeo.';

  @override
  String copiedToClipboard(String message) {
    return '$message foi copiado para a área de transferência.';
  }

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get clear => 'Limpar';

  @override
  String get serverSettings => 'Configurações do servidor';

  @override
  String get serverSettingsDescription => 'Configurações que serão aplicadas apenas a este servidor. Se não forem selectionados, os valores de Configurações serão usados. Você pode alterar esses valores posteriormente.';

  @override
  String get editServerSettingsInfo => 'Editar Configurações do servidor';

  @override
  String editServerSettings(String serverName) {
    return 'Editar configurações do servidor $serverName';
  }

  @override
  String get removeCamera => 'Remover Câmera';

  @override
  String get removePlayer => 'Remover todos as câmeras atribuidas a esse player';

  @override
  String get replaceCamera => 'Substituir Câmera';

  @override
  String get reloadCamera => 'Recarregar Câmera';

  @override
  String get selectACamera => 'Selecione uma câmera';

  @override
  String get switchCamera => 'Trocar câmera';

  @override
  String get status => 'Status';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get live => 'AO VIVO';

  @override
  String get timedOut => 'EXPIRADO';

  @override
  String get loading => 'CARREGANDO';

  @override
  String get recorded => 'GRAVADO';

  @override
  String get late => 'ATRASADO';

  @override
  String get removeFromView => 'Remover do layout';

  @override
  String get addToView => 'Adicionar ao layout';

  @override
  String get addAllToView => 'Adicionar tudo ao layout';

  @override
  String get removeAllFromView => 'Remover tudo do layout';

  @override
  String get streamName => 'Nome da Transmissão';

  @override
  String get streamNameRequired => 'O nome da transmissão é obrigatório';

  @override
  String get streamURL => 'URL da Transmissão';

  @override
  String get streamURLRequired => 'A URL da transmissão é obrigatória';

  @override
  String get streamURLNotValid => 'A url não é válida';

  @override
  String get uri => 'URI';

  @override
  String get eventBrowser => 'Histórico de eventos';

  @override
  String get eventsTimeline => 'Linha do tempo de eventos';

  @override
  String get server => 'Servidor';

  @override
  String get device => 'Dispositivo';

  @override
  String get viewDeviceDetails => 'Ver detalhes do dispositivo';

  @override
  String get event => 'Evento';

  @override
  String get duration => 'Duração';

  @override
  String get priority => 'Prioridade';

  @override
  String get next => 'Próximo';

  @override
  String get previous => 'Anterior';

  @override
  String get lastImageUpdate => 'Última atualização da imagem';

  @override
  String get fps => 'FPS';

  @override
  String get date => 'Data';

  @override
  String get time => 'Hora';

  @override
  String get lastUpdate => 'Última atualização';

  @override
  String screens(String layout) {
    return 'Câmeras';
  }

  @override
  String get directCamera => 'Câmera específica';

  @override
  String get addServer => 'Adicionar servidor';

  @override
  String get settings => 'Configurações';

  @override
  String get noServersAdded => 'Você ainda não adicionou nenhum servidor :/';

  @override
  String get howToAddServer => 'Vá à \"Adicionar Servidor\" para adicionar um servidor.';

  @override
  String get editServerInfo => 'Editar informações do servidor';

  @override
  String editServer(String serverName) {
    return 'Editar servidor $serverName';
  }

  @override
  String get servers => 'Servidores';

  @override
  String nServers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n servidores',
      one: '1 servidor',
      zero: 'Nenhum servidor',
    );
    return '$_temp0';
  }

  @override
  String nDevices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dispositivos',
      one: '1 dispositivo',
      zero: 'Nenhum dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Remover ?';

  @override
  String removeServerDescription(String serverName) {
    return '$serverName será removido. Você não poderá mais ver as câmeras deste servidor e não receberá mais notificações.';
  }

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get about => 'Sobre';

  @override
  String get versionText => 'Copyright © 2022, Bluecherry LLC.\nTodos os direitos reservados.';

  @override
  String get gettingDevices => 'Carregando dispositivos...';

  @override
  String get noDevices => 'Nenhum dispositivo';

  @override
  String get noEventsLoaded => 'NENHUM EVENTO CARREGADO';

  @override
  String get noEventsLoadedTips => '•  Selecione as câmeras cujas você quer ver os eventos\n•  Utilize o calendário para selecionar uma data específica ou intervalo de datas \n•  Use o botão \"Filtrar\" para pesquisar';

  @override
  String get timelineKeyboardShortcutsTips => '•  Use a barra de espaço para reproduzir/pausar a linha do tempo\n•  Use as setas esquerda e direita para mover a linha do tempo\n•  Use a tecla M para silenciar/dessilenciar a linha do tempo\n •  Use o scroll do mouse para dar zoom na linha do tempo';

  @override
  String get invalidResponse => 'Resposta inválida recebida do servidor';

  @override
  String get cameraOptions => 'Opções';

  @override
  String get showFullscreenCamera => 'Ver em tela cheia';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get openInANewWindow => 'Abrir em nova janela';

  @override
  String get enableAudio => 'Ativar audio';

  @override
  String get disableAudio => 'Desativar audio';

  @override
  String get addNewServer => 'Adicionar novo servidor';

  @override
  String get disconnectServer => 'Desconectar';

  @override
  String get serverOptions => 'Opções do servidor';

  @override
  String get browseEvents => 'Ver eventos';

  @override
  String get eventType => 'Tipo do evento';

  @override
  String get configureServer => 'Configurar servidor';

  @override
  String get refreshDevices => 'Recarregar dispositivos';

  @override
  String get refreshServer => 'Recarregar servidor';

  @override
  String get viewDevices => 'Ver dispositivos';

  @override
  String serverDevices(String server) {
    return 'Dispositivos de $server';
  }

  @override
  String get refresh => 'Recarregar';

  @override
  String get view => 'Layouts';

  @override
  String get cycle => 'Ciclo';

  @override
  String fallbackLayoutName(int layout) {
    return 'Layout $layout';
  }

  @override
  String get newLayout => 'Novo layout';

  @override
  String get editLayout => 'Editar layout';

  @override
  String editSpecificLayout(String layoutName) {
    return 'Editar $layoutName';
  }

  @override
  String get exportLayout => 'Exportar layout';

  @override
  String get importLayout => 'Importar layout';

  @override
  String failedToImportMessage(String layoutName, String server_ip, int server_port) {
    return 'Ao tentar importar $layoutName, achamos um dispositívo que está conectando a um servidor que você não está conectado. Por favor, conecte-se ao servidor e tente novamente.\nServer: $server_ip:$server_port';
  }

  @override
  String get layoutImportFileCorrupted => 'O arquivo que você tentou importar está corrompido ou faltando informações.';

  @override
  String layoutImportFileCorruptedWithMessage(Object message) {
    return 'O arquivo que você tentou importar está corrompido ou faltando informações: \"$message\"';
  }

  @override
  String get singleView => 'Câmera única';

  @override
  String get multipleView => 'Múltiplas câmeras';

  @override
  String get compactView => 'Visualização compacta';

  @override
  String get createNewLayout => 'Criar novo layout';

  @override
  String get layoutName => 'Nome do layout';

  @override
  String get layoutNameHint => 'Primeiro andar';

  @override
  String get layoutTypeLabel => 'Tipo do layout';

  @override
  String clearLayout(int amount) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: 'câmeras',
      one: 'câmera',
    );
    return 'Remover $amount $_temp0';
  }

  @override
  String get switchToNext => 'Ir para o próximo';

  @override
  String get unlockLayout => 'Desbloquear layout';

  @override
  String get lockLayout => 'Bloquear layout';

  @override
  String layoutVolume(int volume) {
    return 'Volume • $volume%';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get download => 'Baixar';

  @override
  String downloadN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n eventos',
      one: '1 evento',
    );
    return 'Baixar $_temp0';
  }

  @override
  String get downloaded => 'Baixado';

  @override
  String get downloading => 'Baixando';

  @override
  String get seeInDownloads => 'Ver nos Downloads';

  @override
  String get downloadPath => 'Local de Download';

  @override
  String get delete => 'Deletar';

  @override
  String get showInFiles => 'Ver no Explorador de Arquivos';

  @override
  String get noDownloads => 'Você ainda não baixou nenhum evento :/';

  @override
  String nDownloadsProgress(int n) {
    return 'Você tem $n downloads em progresso!';
  }

  @override
  String get howToDownload => 'Vá ao \"Histórico de Eventos\" para baixar eventos.';

  @override
  String downloadTitle(String event, String device, String server, String date) {
    return '$event de $device do servidor $server em $date';
  }

  @override
  String get playbackOptions => 'OPÇÕES DE REPRODUÇÃO';

  @override
  String get play => 'Reproduzir';

  @override
  String get playing => 'Reproduzindo';

  @override
  String get pause => 'Pausar';

  @override
  String get paused => 'Pausado';

  @override
  String volume(String v) {
    return 'Volume • $v';
  }

  @override
  String speed(String s) {
    return 'Velocidade • $s';
  }

  @override
  String get noRecords => 'Essa câmera não tem gravações neste período.';

  @override
  String get filter => 'Filtrar';

  @override
  String loadEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Buscar de $n dispositivos',
      one: 'Buscar de 1 dispositivo',
      zero: 'Buscar',
    );
    return '$_temp0';
  }

  @override
  String get period => 'Período';

  @override
  String get dateTimeFilter => 'Filtro de Data e Hora';

  @override
  String get dateFilter => 'Periodo';

  @override
  String get timeFilter => 'Filtro de Tempo';

  @override
  String get fromDate => 'De';

  @override
  String get toDate => 'à';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get never => 'Nunca';

  @override
  String fromToDate(String from, String to) {
    return 'De $from à $to';
  }

  @override
  String get mostRecent => 'Mais recentes';

  @override
  String get allowAlarms => 'Permitir alarmes';

  @override
  String get nextEvents => 'Próximos eventos';

  @override
  String nEvents(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n eventos',
      one: '1 evento',
      zero: 'Nenhum evento',
    );
    return '$_temp0';
  }

  @override
  String get info => 'Info';

  @override
  String get warn => 'Aviso';

  @override
  String get alarm => 'Alarme';

  @override
  String get critical => 'Crítico';

  @override
  String get motion => 'Movimento';

  @override
  String get continuous => 'Contínuo';

  @override
  String get notFound => 'Não encontrado';

  @override
  String get cameraVideoLost => 'Video Perdido';

  @override
  String get cameraAudioLost => 'Audio Perdido';

  @override
  String get systemDiskSpace => 'Disk Space';

  @override
  String get systemCrash => 'Crash';

  @override
  String get systemBoot => 'Startup';

  @override
  String get systemShutdown => 'Desligamento';

  @override
  String get systemReboot => 'Reincialização';

  @override
  String get systemPowerOutage => 'Perda de energia';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get close => 'Fechar';

  @override
  String get closeAnyway => 'Fechar mesmo assim';

  @override
  String get closeWhenDone => 'Fechar quando terminar';

  @override
  String get open => 'Abrir';

  @override
  String get collapse => 'Fechar';

  @override
  String get expand => 'Expandir';

  @override
  String get more => 'Mais';

  @override
  String get isPtzSupported => 'Possui PTZ?';

  @override
  String get ptzSupported => 'Possui PTZ';

  @override
  String get enabledPTZ => 'PTZ está ativado';

  @override
  String get disabledPTZ => 'PTZ está desativado';

  @override
  String get move => 'Movimento';

  @override
  String get stop => 'Parar';

  @override
  String get noMovement => 'Nenhum movimento';

  @override
  String get moveNorth => 'Move up';

  @override
  String get moveSouth => 'Move down';

  @override
  String get moveWest => 'Move west';

  @override
  String get moveEast => 'Move east';

  @override
  String get moveWide => 'Afastar';

  @override
  String get moveTele => 'Aproximar';

  @override
  String get presets => 'Presets';

  @override
  String get noPresets => 'Nenhum preset encontado';

  @override
  String get newPreset => 'Novo preset';

  @override
  String get goToPreset => 'Ir ao preset';

  @override
  String get renamePreset => 'Renomear preset';

  @override
  String get deletePreset => 'Deletar preset';

  @override
  String get refreshPresets => 'Atualizar presets';

  @override
  String get resolution => 'Resolução';

  @override
  String get selectResolution => 'Selecionar resolução';

  @override
  String get setResolution => 'Definir resolução';

  @override
  String get setResolutionDescription => 'A resolução da renderização do vídeo pode impactar fortemente o desempenho do aplicativo. Defina a resolução para um valor mais baixo para melhorar o desempenho ou para um valor mais alto para melhorar a qualidade. Você pode definir a resolução padrão nas configurações';

  @override
  String get hd => 'Alta definição';

  @override
  String get defaultResolution => 'Resolução padrão';

  @override
  String get automaticResolution => 'Automático';

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
  String get updates => 'Atualizações';

  @override
  String get upToDate => 'Você está atualizado.';

  @override
  String lastChecked(String date) {
    return 'Última verificação: $date';
  }

  @override
  String get checkForUpdates => 'Procurar atualizações';

  @override
  String get checkingForUpdates => 'Procurando atualizações';

  @override
  String get automaticDownloadUpdates => 'Baixar atualizações automaticamente';

  @override
  String get automaticDownloadUpdatesDescription => 'Seja um dos primeiros a receber as atualizações, correções e melhorias mais recentes assim que lançadas.';

  @override
  String get updateHistory => 'Histórico de atualizações';

  @override
  String get showReleaseNotes => 'Mostrar notas de atualização';

  @override
  String get showReleaseNotesDescription => 'Mostrar as notas de atualização quando uma versão for instalada.';

  @override
  String get newVersionAvailable => 'Nova versão disponível!';

  @override
  String get installVersion => 'Instalar';

  @override
  String get downloadVersion => 'Baixar';

  @override
  String get learnMore => 'Saiba mais';

  @override
  String get failedToUpdate => 'Falha ao atualizar';

  @override
  String get executableNotFound => 'Executável não encontrado';

  @override
  String runningOn(String platform) {
    return 'Rodando no $platform';
  }

  @override
  String get windows => 'Windows';

  @override
  String linux(String env) {
    return 'Linux $env';
  }

  @override
  String get currentTasks => 'Tarefas';

  @override
  String get noCurrentTasks => 'Nenhuma tarefa';

  @override
  String get taskFetchingEvent => 'Buscando eventos';

  @override
  String get taskFetchingEventsPlayback => 'Fetching events playback';

  @override
  String get taskDownloadingEvent => 'Baixando evento';

  @override
  String get defaultField => 'Padrão';

  @override
  String get general => 'Geral';

  @override
  String get generalSettingsSuggestion => 'Notificações, Layouts, Wakelock, etc';

  @override
  String get serverAndDevices => 'Servidores e Dispositivos';

  @override
  String get serverAndDevicesSettingsSuggestion => 'Servidores, Dispositivos, Streaming, etc';

  @override
  String get eventsAndDownloads => 'Eventos e Downloads';

  @override
  String get eventsAndDownloadsSettingsSuggestion => 'Eventos, Histórico de Eventos, Downloads, etc';

  @override
  String get application => 'Aplicação';

  @override
  String get applicationSettingsSuggestion => 'Aparência, idioma, etc';

  @override
  String get privacyAndSecurity => 'Privacidade e Segurança';

  @override
  String get privacyAndSecuritySettingsSuggestion => 'Coleta de dados, relatórios de erros, etc';

  @override
  String get updatesHelpAndPrivacy => 'Atualizações, Ajuda e Privacidade';

  @override
  String get updatesHelpAndPrivacySettingsSuggestion => 'Procure por atualizações, histórico de mudanças, política de privacidade, etc';

  @override
  String get advancedOptions => 'Opções Avançadas';

  @override
  String get advancedOptionsSettingsSuggestion => 'Funcionalidades em Beta, Opções de Desenvolvedor, etc';

  @override
  String get cycleTogglePeriod => 'Duração da alternância de layouts';

  @override
  String get cycleTogglePeriodDescription => 'O intervalo entre alterações de layout quando a alternância está ativada.';

  @override
  String get notifications => 'Notificações';

  @override
  String get notificationsEnabled => 'Notificações ativadas';

  @override
  String get notificationClickBehavior => 'Ação ao clicar na notificação';

  @override
  String get notificationClickBehaviorDescription => 'Escolha o que acontece quando você clica em uma notificação.';

  @override
  String get showEventsScreen => 'Mostar histórico de eventos';

  @override
  String get dataUsage => 'Uso de Dados';

  @override
  String get streamsOnBackground => 'Manter transmissões em segundo plano';

  @override
  String get streamsOnBackgroundDescription => 'Quando manter as transmissões em segundo plano quando o aplicativo estiver em segundo plano';

  @override
  String get automatic => 'Automatico';

  @override
  String get wifiOnly => 'Somente Wi-Fi';

  @override
  String get chooseEveryDownloadsLocation => 'Escolher a localização de cada download';

  @override
  String get chooseEveryDownloadsLocationDescription => 'Se você deseja escolher a localização de cada download ou usar a localização padrão. Quando ativado, você será solicitado a escolher a localização de cada download.';

  @override
  String get allowCloseWhenDownloading => 'Permitir fechar o aplicativo quando houver downloads em andamento';

  @override
  String get events => 'Eventos';

  @override
  String get initialEventSpeed => 'Velocidade inicial';

  @override
  String get initialEventVolume => 'Volume inicial';

  @override
  String get differentEventColors => 'Diferenciar eventos por cor';

  @override
  String get differentEventColorsDescription => 'Se deve mostrar cores diferentes para eventos na linha do tempo. Isso ajuda a diferenciar facilmente os eventos.';

  @override
  String get initialTimelinePoint => 'Ponto inicial';

  @override
  String get initialTimelinePointDescription => 'O ponto em que a linha do tempo inicia.';

  @override
  String get beginningInitialPoint => 'Início';

  @override
  String get firstEventInitialPoint => 'Primeiro evento';

  @override
  String get hourAgoInitialPoint => '1 hora atrás';

  @override
  String get automaticallySkipEmptyPeriods => 'Pular períodos vazios automaticamente';

  @override
  String get appearance => 'Visualização';

  @override
  String get theme => 'Aparência';

  @override
  String get themeDescription => 'Mude a aparência do aplicativo';

  @override
  String get system => 'Padrão do Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get dateAndTime => 'Date and Time';

  @override
  String get dateFormat => 'Formato da Data';

  @override
  String get dateFormatDescription => 'Qual formato usar para exibir datas';

  @override
  String get timeFormat => 'Formato de Hora';

  @override
  String get timeFormatDescription => 'Qual formato usar para exibir horas';

  @override
  String get convertToLocalTime => 'Converter datas para o fuso-horário local';

  @override
  String get convertToLocalTimeDescription => 'Isso afetará a data e a hora exibidas no aplicativo. É útil quando você está em um fuso horário diferente do servidor. Quando desativado, o fuso horário do servidor será usado.';

  @override
  String get allowDataCollection => 'Permitir que Bluecherry colete dados de uso';

  @override
  String get allowDataCollectionDescription => 'Permitir que Bluecherry colete dados para melhorar o aplicativo e fornecer serviços melhores. Os dados são coletados anonimamente e não contêm informações pessoais.';

  @override
  String get automaticallyReportErrors => 'Relatar erros automaticamente';

  @override
  String get automaticallyReportErrorsDescription => 'Enviar automaticamente relatórios de erros para Bluecherry para ajudar a melhorar o aplicativo. Os relatórios de erros podem conter informações pessoais.';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get matrixMagnification => 'Ampliar';

  @override
  String get matrixedViewMagnification => 'Ampliação de Área ativada';

  @override
  String get matrixedViewMagnificationDescription => 'Ampliar a área da visualização da matriz quando selecionado. Isso é útil quando você tem muitas câmeras e deseja ver uma área específica com mais detalhes, ou quando uma stream multicast é usada.';

  @override
  String get matrixType => 'Tipo de Matrix';

  @override
  String get defaultMatrixSize => 'Tamanho Padrão da Matriz';

  @override
  String get softwareMagnification => 'Ampliação de Software';

  @override
  String get softwareMagnificationDescription => 'Quando ativado, a ampliação não ocorrerá na GPU. Isso é útil quando a ampliação no hardware não está funcionando corretamente.';

  @override
  String get softwareMagnificationDescriptionMacOS => 'Quando ativado, a ampliação não ocorrerá na GPU. Isso é útil quando a ampliação no hardware não está funcionando corretamente. No macOS, isso não pode ser desativado.';

  @override
  String get eventMagnification => 'Ampliar Evento';

  @override
  String get eventMagnificationDescription => 'Ampliar o vídeo do evento quando selecionado. Isso é útil quando você deseja ver o evento em mais detalhes.';

  @override
  String get developerOptions => 'Opções de Desenvolvedor';

  @override
  String get openLogFile => 'Abrir Arquivo de Log';

  @override
  String get openAppDataDirectory => 'Abrir Diretório de Dados do Aplicativo';

  @override
  String get importConfigFile => 'Importar arquivo de configuração';

  @override
  String get importConfigFileDescription => 'Importar um arquivo .bluecherry que contém informações de streaming.';

  @override
  String get debugInfo => 'Informações de Depuração';

  @override
  String get debugInfoDescription => 'Exibir informações úteis para depuração, como metadados de vídeo e outras informações úteis para fins de depuração.';

  @override
  String get restoreDefaults => 'Restaurar Padrões';

  @override
  String get restoreDefaultsDescription => 'Restaurar todas as configurações para seus valores padrão. Isso não afetará os servidores que você adicionou.';

  @override
  String get areYouSure => 'Você tem certeza?';

  @override
  String get areYouSureDescription => 'Isso restaurará todas as configurações para seus valores padrão. Isso não afetará seus servidores ou quaisquer outros dados.';

  @override
  String get miscellaneous => 'Outros';

  @override
  String get wakelock => 'Manter tela ativa';

  @override
  String get wakelockDescription => 'Mantenha a tela ativa enquanto estiver assistindo a transmissões ao vivo ou gravações';

  @override
  String get snooze15 => '15 minutos';

  @override
  String get snooze30 => '30 minutos';

  @override
  String get snooze60 => '1 hora';

  @override
  String get snoozeNotifications => 'Silenciar notificações';

  @override
  String get notSnoozed => 'Não silenciado';

  @override
  String get snoozeNotificationsUntil => 'Silenciar notificações até';

  @override
  String snoozedUntil(String time) {
    return 'Silenciado até $time';
  }

  @override
  String get connectToServerAutomaticallyAtStartup => 'Conectar automaticamente ao iniciar';

  @override
  String get connectToServerAutomaticallyAtStartupDescription => 'Se ativado, o servidor será conectado automaticamente quando o aplicativo for iniciado. Isso só se aplica aos novos servidores que você adicionar.';

  @override
  String get allowUntrustedCertificates => 'Permitir certificados não confiáveis';

  @override
  String get allowUntrustedCertificatesDescription => 'Permitir a conexão a servidores com certificados não confiáveis. Isso é útil quando você está usando certificados autoassinados ou certificados de autoridades desconhecidas.';

  @override
  String get certificateNotPassed => 'Certificado não autorizado';

  @override
  String get addServerTimeout => 'Tempo limite para adicionar servidor';

  @override
  String get addServerTimeoutDescription => 'O tempo para esperar a resposta do servidor ao adicionar um novo servidor.';

  @override
  String get streamingSettings => 'Configurações de streaming';

  @override
  String get streamingProtocol => 'Protocolo de Streaming';

  @override
  String get preferredStreamingProtocol => 'Protocolo de Streaming Padrão';

  @override
  String get preferredStreamingProtocolDescription => 'Qual protocolo de streaming de vídeo será usado. Se o servidor não suportar o protocolo selecionado, o próximo será usado. É possível selecionar um protocolo específico para cada dispositivo em suas configurações.';

  @override
  String get rtspProtocol => 'Protocolo RTSP';

  @override
  String get camerasSettings => 'Configurações das câmeras';

  @override
  String get renderingQuality => 'Qualidade de renderização';

  @override
  String get renderingQualityDescription => 'A qualidade de renderização. Quanto maior a qualidade, mais recursos são usados.\nQuando automatico, a resolução é selecionada baseada na resolução da câmera.';

  @override
  String get cameraViewFit => 'Ajuste de imagem da câmera';

  @override
  String get cameraViewFitDescription => 'Como o vídeo é renderizado na visualização.';

  @override
  String get contain => 'Limitar';

  @override
  String get fill => 'Preencher';

  @override
  String get cover => 'Cobrir';

  @override
  String get streamRefreshPeriod => 'Intervalo de Atualização do Vídeo';

  @override
  String get streamRefreshPeriodDescription => 'O intervalo entre as atualizações das câmeras. Isso garante que o vídeo da câmera ainda seja válido de tempos em tempos.';

  @override
  String get lateStreamBehavior => 'Transmissão atrasada';

  @override
  String get lateStreamBehaviorDescription => 'O que fazer quando a transmissão está atrasada.';

  @override
  String get automaticBehavior => 'Automático';

  @override
  String get automaticBehaviorDescription => 'A transmissão será reajustada automaticamente';

  @override
  String get manualBehavior => 'Manual';

  @override
  String manualBehaviorDescription(String label) {
    return 'Pressione $label para reposicionar a transmissão';
  }

  @override
  String get neverBehaviorDescription => 'A transmissão não será reajustada';

  @override
  String get devicesSettings => 'Configurações de Dispositivos';

  @override
  String get listOfflineDevices => 'Listar Dispositivos Offline';

  @override
  String get listOfflineDevicesDescriptions => 'Se deve mostrar dispositivos offline na lista de dispositivos.';

  @override
  String get initialDeviceVolume => 'Volume Inicial da Câmera';

  @override
  String get runVideoTest => 'Testar Vídeo';

  @override
  String get runVideoTestDescription => 'Teste o vídeo para verificar o estado da reprodução de vídeo.';

  @override
  String get showCameraName => 'Show Camera Name';

  @override
  String get always => 'Always';

  @override
  String get onHover => 'On hover';

  @override
  String get dateLanguage => 'Data e Idioma';

  @override
  String get language => 'Idioma';

  @override
  String get overlays => 'Sobreposições';

  @override
  String get visible => 'Visível';

  @override
  String nOverlay(int n) {
    return 'Sobreposição $n';
  }

  @override
  String overlayPosition(double x, double y) {
    return 'Posição (x: $x, y: $y)';
  }

  @override
  String get externalStream => 'Transmissão externa';

  @override
  String get addExternalStream => 'Adicionar transmissão externa';

  @override
  String get showMore => 'Mostrar mais';

  @override
  String get showLess => 'Mostrar menos';

  @override
  String get serverHostname => 'Hostname do servidor';

  @override
  String get serverHostnameExample => 'https://servidor.bluecherry.app:7001';

  @override
  String get rackName => 'Nome do rack';

  @override
  String get rackNameExample => 'Lab 1';

  @override
  String get openServer => 'Abrir servidor';

  @override
  String get disableSearch => 'Desativar pesquisa';

  @override
  String get help => 'Ajuda';

  @override
  String get licenses => 'Licenças';
}

import 'package:flutter/material.dart';
import '../../domain/models/dollar_type.dart';

/// Traducciones de la app (español, inglés, italiano, alemán).
/// Para usar: AppLocalizations.of(context).appTitle
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.maybeLocaleOf(context) ?? const Locale('es');
    return AppLocalizations(loc);
  }

  String get _lang => locale.languageCode;
  bool get isEnglish => _lang == 'en';

  // General
  String get appTitle {
    switch (_lang) {
      case 'en':
        return 'Dollar Argentina';
      case 'it':
        return 'Dollaro Argentina';
      case 'de':
        return 'Dollar Argentinien';
      default:
        return 'Dólar Argentina';
    }
  }

  String get settings {
    switch (_lang) {
      case 'en':
        return 'Settings';
      case 'it':
        return 'Impostazioni';
      case 'de':
        return 'Einstellungen';
      default:
        return 'Ajustes';
    }
  }

  String get calculator {
    switch (_lang) {
      case 'en':
        return 'Calculator';
      case 'it':
        return 'Calcolatrice';
      case 'de':
        return 'Rechner';
      default:
        return 'Calculadora';
    }
  }

  String get language {
    switch (_lang) {
      case 'en':
        return 'Language';
      case 'it':
        return 'Lingua';
      case 'de':
        return 'Sprache';
      default:
        return 'Idioma';
    }
  }

  String get languageSubtitle {
    switch (_lang) {
      case 'en':
        return 'App language (Spanish, English, Italian or German)';
      case 'it':
        return 'Lingua dell\'app (spagnolo, inglese, italiano o tedesco)';
      case 'de':
        return 'App-Sprache (Spanisch, Englisch, Italienisch oder Deutsch)';
      default:
        return 'Idioma de la app (español, inglés, italiano o alemán)';
    }
  }

  String get languageEs => 'Español';
  String get languageEn => 'English';
  String get languageSystem {
    switch (_lang) {
      case 'en':
        return 'Device language';
      case 'it':
        return 'Lingua del dispositivo';
      case 'de':
        return 'Gerätesprache';
      default:
        return 'Idioma del dispositivo';
    }
  }

  // Home
  String get buy {
    switch (_lang) {
      case 'en':
        return 'Buy';
      case 'it':
        return 'Acquisto';
      case 'de':
        return 'Kauf';
      default:
        return 'Compra';
    }
  }

  String get sell {
    switch (_lang) {
      case 'en':
        return 'Sell';
      case 'it':
        return 'Vendita';
      case 'de':
        return 'Verkauf';
      default:
        return 'Venta';
    }
  }

  String get refreshedPrefix {
    switch (_lang) {
      case 'en':
        return 'Refreshed';
      case 'it':
        return 'Aggiornato';
      case 'de':
        return 'Aktualisiert';
      default:
        return 'Refrescado';
    }
  }

  String get lastUpdate {
    switch (_lang) {
      case 'en':
        return 'Last update';
      case 'it':
        return 'Ultimo aggiornamento';
      case 'de':
        return 'Letzte Aktualisierung';
      default:
        return 'Última actualización';
    }
  }

  String get timeAgoJustNow {
    switch (_lang) {
      case 'en':
        return 'just now';
      case 'it':
        return 'proprio ora';
      case 'de':
        return 'gerade eben';
      default:
        return 'hace un momento';
    }
  }

  String timeAgoMinutes(int n) {
    switch (_lang) {
      case 'en':
        return n == 1 ? '1 min ago' : '$n min ago';
      case 'it':
        return n == 1 ? '1 min fa' : '$n min fa';
      case 'de':
        return n == 1 ? 'vor 1 Min' : 'vor $n Min';
      default:
        return n == 1 ? 'hace 1 min' : 'hace $n min';
    }
  }

  String timeAgoHours(int n) {
    switch (_lang) {
      case 'en':
        return n == 1 ? '1 hour ago' : '$n hours ago';
      case 'it':
        return n == 1 ? '1 ora fa' : '$n ore fa';
      case 'de':
        return n == 1 ? 'vor 1 Std' : 'vor $n Std';
      default:
        return n == 1 ? 'hace 1 hora' : 'hace $n horas';
    }
  }

  String get pullToRefresh {
    switch (_lang) {
      case 'en':
        return 'Pull to refresh';
      case 'it':
        return 'Tira per aggiornare';
      case 'de':
        return 'Ziehen zum Aktualisieren';
      default:
        return 'Deslizá para actualizar';
    }
  }

  String get noConnection {
    switch (_lang) {
      case 'en':
        return 'No connection';
      case 'it':
        return 'Nessuna connessione';
      case 'de':
        return 'Keine Verbindung';
      default:
        return 'Sin conexión';
    }
  }

  String get errorLoadingData {
    switch (_lang) {
      case 'en':
        return 'Error loading data';
      case 'it':
        return 'Errore nel caricamento dei dati';
      case 'de':
        return 'Fehler beim Laden der Daten';
      default:
        return 'Error al cargar datos';
    }
  }

  String get retry {
    switch (_lang) {
      case 'en':
        return 'Retry';
      case 'it':
        return 'Riprova';
      case 'de':
        return 'Erneut versuchen';
      default:
        return 'Reintentar';
    }
  }

  String get errorSubtitle {
    switch (_lang) {
      case 'en':
        return 'Make sure WiFi or mobile data is on and tap Retry.';
      case 'it':
        return 'Assicurati che WiFi o dati mobili siano attivi e tocca Riprova.';
      case 'de':
        return 'Stelle sicher, dass WLAN oder mobile Daten aktiv sind und tippe auf Erneut versuchen.';
      default:
        return 'Revisá que tengas WiFi o datos móviles activos y tocá Reintentar.';
    }
  }

  String get errorSubtitleGeneric {
    switch (_lang) {
      case 'en':
        return 'Could not load rates.';
      case 'it':
        return 'Impossibile caricare le quotazioni.';
      case 'de':
        return 'Kurse konnten nicht geladen werden.';
      default:
        return 'No se pudieron cargar las cotizaciones.';
    }
  }

  String get dataSourceFooter {
    switch (_lang) {
      case 'en':
        return 'Data obtained directly from official sources.';
      case 'it':
        return 'Dati ottenuti direttamente da fonti ufficiali.';
      case 'de':
        return 'Daten stammen direkt von offiziellen Quellen.';
      default:
        return 'Datos obtenidos directamente de las entidades oficiales.';
    }
  }

  String dollarTypeName(DollarType type) {
    switch (_lang) {
      case 'en':
        switch (type) {
          case DollarType.blue:
            return 'Blue Dollar';
          case DollarType.official:
            return 'Official Dollar';
          case DollarType.crypto:
            return 'Crypto Dollar';
          case DollarType.tarjeta:
            return 'Card Dollar';
          case DollarType.mep:
            return 'MEP Dollar';
          case DollarType.ccl:
            return 'CCL Dollar';
        }
      case 'it':
        switch (type) {
          case DollarType.blue:
            return 'Dollaro Blue';
          case DollarType.official:
            return 'Dollaro Ufficiale';
          case DollarType.crypto:
            return 'Dollaro Cripto';
          case DollarType.tarjeta:
            return 'Dollaro Carta';
          case DollarType.mep:
            return 'Dollaro MEP';
          case DollarType.ccl:
            return 'Dollaro CCL';
        }
      case 'de':
        switch (type) {
          case DollarType.blue:
            return 'Blauer Dollar';
          case DollarType.official:
            return 'Offizieller Dollar';
          case DollarType.crypto:
            return 'Krypto-Dollar';
          case DollarType.tarjeta:
            return 'Karten-Dollar';
          case DollarType.mep:
            return 'MEP-Dollar';
          case DollarType.ccl:
            return 'CCL-Dollar';
        }
      default:
        return type.displayName;
    }
  }

  // Settings
  String get darkMode {
    switch (_lang) {
      case 'en':
        return 'Dark mode';
      case 'it':
        return 'Modalità scura';
      case 'de':
        return 'Dunkler Modus';
      default:
        return 'Modo oscuro';
    }
  }

  String get darkModeSubtitle {
    switch (_lang) {
      case 'en':
        return 'Better experience in low light';
      case 'it':
        return 'Migliore esperienza in condizioni di scarsa illuminazione';
      case 'de':
        return 'Bessere Erfahrung bei wenig Licht';
      default:
        return 'Mejor experiencia en ambientes con poca luz';
    }
  }

  String get pushNotifications {
    switch (_lang) {
      case 'en':
        return 'Push notifications';
      case 'it':
        return 'Notifiche push';
      case 'de':
        return 'Push-Benachrichtigungen';
      default:
        return 'Notificaciones Push';
    }
  }

  String get pushNotificationsSubtitle {
    switch (_lang) {
      case 'en':
        return 'Market open and close alerts';
      case 'it':
        return 'Avvisi di apertura e chiusura del mercato';
      case 'de':
        return 'Benachrichtigungen zu Marktöffnung und -schließung';
      default:
        return 'Alertas de apertura y cierre del mercado';
    }
  }

  String get openSettings {
    switch (_lang) {
      case 'en':
        return 'Open Settings';
      case 'it':
        return 'Apri impostazioni';
      case 'de':
        return 'Einstellungen öffnen';
      default:
        return 'Abrir Ajustes';
    }
  }

  String get openSettingsIos {
    switch (_lang) {
      case 'en':
        return 'Open iPhone Settings';
      case 'it':
        return 'Apri Impostazioni iPhone';
      case 'de':
        return 'iPhone-Einstellungen öffnen';
      default:
        return 'Abrir Ajustes del iPhone';
    }
  }

  String get notificationsDisabledSubtitle {
    switch (_lang) {
      case 'en':
        return 'Notifications are off. Turn them on in Settings to get alerts.';
      case 'it':
        return 'Le notifiche sono disattivate. Attivale in Impostazioni per ricevere avvisi.';
      case 'de':
        return 'Benachrichtigungen sind deaktiviert. Aktiviere sie in den Einstellungen.';
      default:
        return 'Las notificaciones están desactivadas. Actívalas en Ajustes para recibir alertas.';
    }
  }

  String get visibleDollarTypes {
    switch (_lang) {
      case 'en':
        return 'Visible Dollar Types';
      case 'it':
        return 'Tipi di Dollaro Visibili';
      case 'de':
        return 'Sichtbare Dollartypen';
      default:
        return 'Tipos de Dólar Visibles';
    }
  }

  String get visibleDollarTypesSubtitle {
    switch (_lang) {
      case 'en':
        return 'Choose which types to show on the main screen';
      case 'it':
        return 'Scegli quali tipi mostrare nella schermata principale';
      case 'de':
        return 'Wähle, welche Typen auf dem Hauptbildschirm angezeigt werden';
      default:
        return 'Selecciona qué tipos de dólar ver en la pantalla principal';
    }
  }

  String get dataSource {
    switch (_lang) {
      case 'en':
        return 'Data source';
      case 'it':
        return 'Fonte dati';
      case 'de':
        return 'Datenquelle';
      default:
        return 'Fuente de datos';
    }
  }

  String get version {
    switch (_lang) {
      case 'en':
        return 'Version';
      case 'it':
        return 'Versione';
      case 'de':
        return 'Version';
      default:
        return 'Versión';
    }
  }

  String get about {
    switch (_lang) {
      case 'en':
        return 'About';
      case 'it':
        return 'Informazioni';
      case 'de':
        return 'Über';
      default:
        return 'Acerca de';
    }
  }

  // Calculator
  String get exchangeRateType {
    switch (_lang) {
      case 'en':
        return 'Exchange rate type';
      case 'it':
        return 'Tipo di cambio';
      case 'de':
        return 'Wechselkursart';
      default:
        return 'Tipo de cambio';
    }
  }

  String get amountInPesos {
    switch (_lang) {
      case 'en':
        return 'Amount in pesos';
      case 'it':
        return 'Importo in pesos';
      case 'de':
        return 'Betrag in Pesos';
      default:
        return 'Monto en pesos';
    }
  }

  String get amountInDollars {
    switch (_lang) {
      case 'en':
        return 'Amount in dollars';
      case 'it':
        return 'Importo in dollari';
      case 'de':
        return 'Betrag in Dollar';
      default:
        return 'Monto en dólares';
    }
  }

  String get resultInUSD {
    switch (_lang) {
      case 'en':
        return 'Result in USD';
      case 'it':
        return 'Risultato in USD';
      case 'de':
        return 'Ergebnis in USD';
      default:
        return 'Resultado en USD';
    }
  }

  String get resultInARS {
    switch (_lang) {
      case 'en':
        return 'Result in ARS';
      case 'it':
        return 'Risultato in ARS';
      case 'de':
        return 'Ergebnis in ARS';
      default:
        return 'Resultado en ARS';
    }
  }

  String get enterValidAmount {
    switch (_lang) {
      case 'en':
        return 'Enter a valid amount';
      case 'it':
        return 'Inserisci un importo valido';
      case 'de':
        return 'Gib einen gültigen Betrag ein';
      default:
        return 'Ingresá un monto válido';
    }
  }

  String get conversionDirectionPesosToDollars {
    switch (_lang) {
      case 'en':
        return 'Pesos → Dollars';
      case 'it':
        return 'Pesos → Dollari';
      case 'de':
        return 'Pesos → Dollar';
      default:
        return 'Pesos → Dólares';
    }
  }

  String get conversionDirectionDollarsToPesos {
    switch (_lang) {
      case 'en':
        return 'Dollars → Pesos';
      case 'it':
        return 'Dollari → Pesos';
      case 'de':
        return 'Dollar → Pesos';
      default:
        return 'Dólares → Pesos';
    }
  }

  String get calculatorSourceOfficial {
    switch (_lang) {
      case 'en':
        return 'Uses Banco Nación rate for Official Dollar';
      case 'it':
        return 'Usa il tasso Banco Nación per il Dollaro Ufficiale';
      case 'de':
        return 'Verwendet Banco-Nación-Kurs für offiziellen Dollar';
      default:
        return 'Se usa la cotización del Banco Nación para el dólar oficial';
    }
  }

  String get calculatorSourceCrypto {
    switch (_lang) {
      case 'en':
        return 'Uses Binance rate for Crypto Dollar';
      case 'it':
        return 'Usa il tasso Binance per il Dollaro Cripto';
      case 'de':
        return 'Verwendet Binance-Kurs für Krypto-Dollar';
      default:
        return 'Se usa la cotización de Binance para el dólar cripto';
    }
  }

  String get bankNation => '(Nación)';
  String get binanceP2P => '(Binance)';

  // Share (para _shareRate en dollar_row)
  String get shareToday {
    switch (_lang) {
      case 'en':
        return 'Today';
      case 'it':
        return 'Oggi';
      case 'de':
        return 'Heute';
      default:
        return 'Hoy';
    }
  }

  String get shareBuyLabel {
    switch (_lang) {
      case 'en':
        return 'Buy';
      case 'it':
        return 'Acquisto';
      case 'de':
        return 'Kauf';
      default:
        return 'Compra';
    }
  }

  String get shareSellLabel {
    switch (_lang) {
      case 'en':
        return 'Sell';
      case 'it':
        return 'Vendita';
      case 'de':
        return 'Verkauf';
      default:
        return 'Venta';
    }
  }

  String get shareSource {
    switch (_lang) {
      case 'en':
        return 'Source';
      case 'it':
        return 'Fonte';
      case 'de':
        return 'Quelle';
      default:
        return 'Fuente';
    }
  }

  String get shareFooter {
    switch (_lang) {
      case 'en':
        return 'Download the app for live rates.';
      case 'it':
        return 'Scarica l\'app per le quotazioni in tempo reale.';
      case 'de':
        return 'Lade die App für Echtzeitkurse herunter.';
      default:
        return 'Descargá la app y mirá todas las cotizaciones al instante.';
    }
  }

  /// true si el idioma usa coma para miles (EN: 1,234); false para punto (ES/IT/DE: 1.234)
  bool get useCommaForThousands => _lang == 'en';

  // Settings - secciones adicionales
  String get contactAndAds {
    switch (_lang) {
      case 'en':
        return 'Contact and Advertising';
      case 'it':
        return 'Contatto e Pubblicità';
      case 'de':
        return 'Kontakt und Werbung';
      default:
        return 'Contacto y Publicidad';
    }
  }

  String get contactAndAdsSubtitle {
    switch (_lang) {
      case 'en':
        return 'For any query or advertising topic you can write to us by email';
      case 'it':
        return 'Per qualsiasi domanda o argomento pubblicitario puoi scriverci via email';
      case 'de':
        return 'Bei Fragen oder Werbeanfragen kannst du uns per E-Mail kontaktieren';
      default:
        return 'Por cualquier consulta o tema de publicidad podés escribirnos por correo';
    }
  }

  String get appInfo {
    switch (_lang) {
      case 'en':
        return 'App Information';
      case 'it':
        return 'Informazioni sull\'App';
      case 'de':
        return 'App-Informationen';
      default:
        return 'Información de la App';
    }
  }

  String get functionalityTitle {
    switch (_lang) {
      case 'en':
        return 'Functionality';
      case 'it':
        return 'Funzionalità';
      case 'de':
        return 'Funktionalität';
      default:
        return 'Funcionalidad';
    }
  }

  String get functionalityContent {
    switch (_lang) {
      case 'en':
        return 'Check dollar exchange rates in Argentina in real time: blue, official, crypto, card, MEP and CCL. Values are updated automatically so you always have up-to-date information.';
      case 'it':
        return 'Consulta in tempo reale i tassi di cambio del dollaro in Argentina: blue, ufficiale, cripto, carta, MEP e CCL. I valori si aggiornano automaticamente per avere sempre informazioni aggiornate.';
      case 'de':
        return 'Prüfe die Dollar-Wechselkurse in Argentinien in Echtzeit: Blau, offiziell, Krypto, Karte, MEP und CCL. Die Werte werden automatisch aktualisiert.';
      default:
        return 'Consultá en tiempo real las cotizaciones del dólar en Argentina: blue, oficial, cripto, tarjeta, MEP y CCL. Los valores se actualizan automáticamente para que siempre tengas la información al día.';
    }
  }

  String get variationMarkersTitle {
    switch (_lang) {
      case 'en':
        return 'Variation markers';
      case 'it':
        return 'Marcatori di variazione';
      case 'de':
        return 'Variationsmarker';
      default:
        return 'Marcadores de variación';
    }
  }

  String get variationMarkersContent {
    switch (_lang) {
      case 'en':
        return 'Each dollar type shows how the price changed in the last 24 hours:\n\n• Green ↗️: went up\n• Red ↘️: went down\n• Gray ➖: no significant change';
      case 'it':
        return 'Ogni tipo di dollaro mostra come è cambiato il prezzo nelle ultime 24 ore:\n\n• Verde ↗️: salito\n• Rosso ↘️: sceso\n• Grigio ➖: nessun cambiamento significativo';
      case 'de':
        return 'Jeder Dollartyp zeigt die Preisänderung der letzten 24 Stunden:\n\n• Grün ↗️: gestiegen\n• Rot ↘️: gefallen\n• Grau ➖: keine signifikante Änderung';
      default:
        return 'Cada tipo de dólar muestra cómo varió el precio respecto a las últimas 24 horas:\n\n• Verde ↗️: subió\n• Rojo ↘️: bajó\n• Gris ➖: sin cambio significativo';
    }
  }

  String get availableOptionsTitle {
    switch (_lang) {
      case 'en':
        return 'Available options';
      case 'it':
        return 'Opzioni disponibili';
      case 'de':
        return 'Verfügbare Optionen';
      default:
        return 'Opciones disponibles';
    }
  }

  String get availableOptionsContent {
    switch (_lang) {
      case 'en':
        return '• Official Dollar: choose the bank to see its rate (Nación, BBVA, Provincia, etc.)\n• Crypto Dollar: choose the P2P platform (Binance, KuCoin, Bybit, OKX, Bitget)\n• Customization: reorder and hide dollar types in Settings\n• Refresh: pull down on the main screen to refresh';
      case 'it':
        return '• Dollaro Ufficiale: scegli la banca per vedere il tasso (Nación, BBVA, Provincia, ecc.)\n• Dollaro Cripto: scegli la piattaforma P2P (Binance, KuCoin, Bybit, OKX, Bitget)\n• Personalizzazione: riordina e nascondi i tipi in Impostazioni\n• Aggiornamento: tira verso il basso per aggiornare';
      case 'de':
        return '• Offizieller Dollar: Bank wählen (Nación, BBVA, Provincia, etc.)\n• Krypto-Dollar: P2P-Plattform wählen (Binance, KuCoin, Bybit, OKX, Bitget)\n• Anpassung: Typen in Einstellungen sortieren und ausblenden\n• Aktualisierung: Nach unten ziehen zum Aktualisieren';
      default:
        return '• Dólar Oficial: elegí el banco para ver su cotización (Nación, BBVA, Provincia, etc.)\n• Dólar Cripto: elegí la plataforma P2P (Binance, KuCoin, Bybit, OKX, Bitget)\n• Personalización: reordená y ocultá tipos de dólar en Ajustes\n• Actualización: deslizá hacia abajo en la pantalla principal para refrescar';
    }
  }

  String get dataSourcesTitle {
    switch (_lang) {
      case 'en':
        return 'Data sources';
      case 'it':
        return 'Fonti dati';
      case 'de':
        return 'Datenquellen';
      default:
        return 'Fuentes de datos';
    }
  }

  String get dataSourcesContent {
    switch (_lang) {
      case 'en':
        return 'Rates come directly from official sources (banks, entities and verified platforms). Information is updated regularly so the values shown reflect the real market.';
      case 'it':
        return 'Le quotazioni provengono direttamente da fonti ufficiali (banche, enti e piattaforme verificate). Le informazioni si aggiornano regolarmente per riflettere il mercato reale.';
      case 'de':
        return 'Kurse stammen direkt von offiziellen Quellen (Banken, Einrichtungen und verifizierten Plattformen). Die Informationen werden regelmäßig aktualisiert.';
      default:
        return 'Las cotizaciones provienen directamente de las fuentes oficiales (bancos, entidades y plataformas verificadas). La información se actualiza de forma recurrente para que los valores mostrados reflejen el mercado real.';
    }
  }

  String get informationSources {
    switch (_lang) {
      case 'en':
        return 'Information Sources';
      case 'it':
        return 'Fonti di Informazione';
      case 'de':
        return 'Informationsquellen';
      default:
        return 'Fuentes de Información';
    }
  }

  String get informationSourcesSubtitle {
    switch (_lang) {
      case 'en':
        return 'Links to official data sources';
      case 'it':
        return 'Link alle fonti ufficiali dei dati';
      case 'de':
        return 'Links zu offiziellen Datenquellen';
      default:
        return 'Enlaces a las fuentes oficiales de los datos';
    }
  }

  String get officialDollar {
    switch (_lang) {
      case 'en':
        return 'Official Dollar';
      case 'it':
        return 'Dollaro Ufficiale';
      case 'de':
        return 'Offizieller Dollar';
      default:
        return 'Dólar Oficial';
    }
  }

  String get cryptoDollar {
    switch (_lang) {
      case 'en':
        return 'Crypto Dollar';
      case 'it':
        return 'Dollaro Cripto';
      case 'de':
        return 'Krypto-Dollar';
      default:
        return 'Dólar Cripto';
    }
  }

  String get contactEmailSubject {
    switch (_lang) {
      case 'en':
        return 'Contact from Dollar Argentina';
      case 'it':
        return 'Contatto da Dollaro Argentina';
      case 'de':
        return 'Kontakt von Dollar Argentinien';
      default:
        return 'Contacto desde Dólar Argentina';
    }
  }

  String get contactEmailBody {
    switch (_lang) {
      case 'en':
        return 'Hello,\n\nI am writing from the Dollar Argentina app.\n\n[Write your query or topic of interest here]\n\nBest regards,';
      case 'it':
        return 'Salve,\n\nScrivo dall\'app Dollaro Argentina.\n\n[Scrivi qui la tua richiesta o argomento di interesse]\n\nCordiali saluti,';
      case 'de':
        return 'Hallo,\n\nich schreibe aus der Dollar Argentinien App.\n\n[Hier Anfrage oder Thema eingeben]\n\nMit freundlichen Grüßen,';
      default:
        return 'Hola,\n\nLes escribo desde la app Dólar Argentina.\n\n[Escriba aquí su consulta o tema de interés]\n\nSaludos cordiales,';
    }
  }

  String contactEmailError(String email) {
    switch (_lang) {
      case 'en':
        return 'Could not open email. Make sure you have an email app installed (Gmail, Outlook, etc.). You can write to $email';
      case 'it':
        return 'Impossibile aprire l\'email. Assicurati di avere un\'app email installata (Gmail, Outlook, ecc.). Puoi scrivere a $email';
      case 'de':
        return 'E-Mail konnte nicht geöffnet werden. Stelle sicher, dass eine E-Mail-App installiert ist (Gmail, Outlook, etc.). Du kannst an $email schreiben';
      default:
        return 'No se pudo abrir el correo. Asegurate de tener una app de correo instalada (Gmail, Outlook, etc.). Podés escribir a $email';
    }
  }

  String couldNotOpenLink(String url) {
    switch (_lang) {
      case 'en':
        return 'Could not open link: $url';
      case 'it':
        return 'Impossibile aprire il link: $url';
      case 'de':
        return 'Link konnte nicht geöffnet werden: $url';
      default:
        return 'No se pudo abrir el enlace: $url';
    }
  }

  // Reseña in-app
  String get reviewDialogTitle {
    switch (_lang) {
      case 'en':
        return 'Enjoying Dolar ARG?';
      case 'it':
        return 'Ti piace Dolar ARG?';
      case 'de':
        return 'Gefällt dir Dolar ARG?';
      default:
        return '¿Te gusta Dolar ARG?';
    }
  }

  String get reviewDialogMessage {
    switch (_lang) {
      case 'en':
        return 'Dolar ARG is FREE. Your rating helps us a lot to keep improving.';
      case 'it':
        return 'Dolar ARG è GRATIS. La tua valutazione ci aiuta tantissimo a continuare a migliorare.';
      case 'de':
        return 'Dolar ARG ist KOSTENLOS. Deine Bewertung hilft uns sehr, besser zu werden.';
      default:
        return 'Dolar ARG es GRATIS. Tu puntuación nos ayuda muchísimo a seguir mejorando.';
    }
  }

  String get reviewDialogRate {
    switch (_lang) {
      case 'en':
        return 'Rate';
      case 'it':
        return 'Valuta';
      case 'de':
        return 'Bewerten';
      default:
        return 'Calificar';
    }
  }

  String get reviewDialogLater {
    switch (_lang) {
      case 'en':
        return 'Not now';
      case 'it':
        return 'Non ora';
      case 'de':
        return 'Später';
      default:
        return 'Ahora no';
    }
  }

  String get rateUs {
    switch (_lang) {
      case 'en':
        return 'Rate us';
      case 'it':
        return 'Valutaci';
      case 'de':
        return 'Bewerte uns';
      default:
        return 'Calificanos';
    }
  }

  String get rateUsSubtitle {
    switch (_lang) {
      case 'en':
        return 'Your opinion helps us a lot';
      case 'it':
        return 'La tua opinione ci aiuta molto';
      case 'de':
        return 'Deine Meinung hilft uns sehr';
      default:
        return 'Tu opinión nos ayuda mucho';
    }
  }

  String get sectionAppearance {
    switch (_lang) {
      case 'en':
        return 'Appearance';
      case 'it':
        return 'Aspetto';
      case 'de':
        return 'Darstellung';
      default:
        return 'Apariencia';
    }
  }

  String get sectionNotifications {
    switch (_lang) {
      case 'en':
        return 'Notifications';
      case 'it':
        return 'Notifiche';
      case 'de':
        return 'Benachrichtigungen';
      default:
        return 'Notificaciones';
    }
  }

  String get sectionCustomization {
    switch (_lang) {
      case 'en':
        return 'Customization';
      case 'it':
        return 'Personalizzazione';
      case 'de':
        return 'Anpassung';
      default:
        return 'Personalización';
    }
  }

  String get sectionSupport {
    switch (_lang) {
      case 'en':
        return 'Support';
      case 'it':
        return 'Supporto';
      case 'de':
        return 'Support';
      default:
        return 'Soporte';
    }
  }

  String get sectionInformation {
    switch (_lang) {
      case 'en':
        return 'Information';
      case 'it':
        return 'Informazioni';
      case 'de':
        return 'Informationen';
      default:
        return 'Información';
    }
  }
}

import 'package:flutter/material.dart';
import '../../domain/models/dollar_type.dart';

/// Traducciones de la app (español / inglés).
/// Para usar: AppLocalizations.of(context).appTitle
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.maybeLocaleOf(context) ?? const Locale('es');
    return AppLocalizations(loc);
  }

  bool get isEnglish => locale.languageCode == 'en';

  // General
  String get appTitle => isEnglish ? 'Dollar Argentina' : 'Dólar Argentina';
  String get settings => isEnglish ? 'Settings' : 'Ajustes';
  String get calculator => isEnglish ? 'Calculator' : 'Calculadora';
  String get language => isEnglish ? 'Language' : 'Idioma';
  String get languageSubtitle =>
      isEnglish
          ? 'App language (Spanish or English)'
          : 'Idioma de la app (español o inglés)';
  String get languageEs => 'Español';
  String get languageEn => 'English';
  String get languageSystem =>
      isEnglish ? 'Device language' : 'Idioma del dispositivo';

  // Home
  String get buy => isEnglish ? 'Buy' : 'Compra';
  String get sell => isEnglish ? 'Sell' : 'Venta';
  String get refreshedPrefix => isEnglish ? 'Refreshed' : 'Refrescado';
  String get lastUpdate => isEnglish ? 'Last update' : 'Última actualización';
  String get timeAgoJustNow => isEnglish ? 'just now' : 'hace un momento';
  String timeAgoMinutes(int n) =>
      isEnglish ? (n == 1 ? '1 min ago' : '$n min ago') : (n == 1 ? 'hace 1 min' : 'hace $n min');
  String timeAgoHours(int n) =>
      isEnglish ? (n == 1 ? '1 hour ago' : '$n hours ago') : (n == 1 ? 'hace 1 hora' : 'hace $n horas');
  String get pullToRefresh =>
      isEnglish ? 'Pull to refresh' : 'Deslizá para actualizar';
  String get noConnection => isEnglish ? 'No connection' : 'Sin conexión';
  String get errorLoadingData =>
      isEnglish ? 'Error loading data' : 'Error al cargar datos';
  String get retry => isEnglish ? 'Retry' : 'Reintentar';
  String get errorSubtitle =>
      isEnglish
          ? 'Make sure WiFi or mobile data is on and tap Retry.'
          : 'Revisá que tengas WiFi o datos móviles activos y tocá Reintentar.';
  String get errorSubtitleGeneric =>
      isEnglish ? 'Could not load rates.' : 'No se pudieron cargar las cotizaciones.';
  String get dataSourceFooter =>
      isEnglish
          ? 'Data obtained directly from official sources.'
          : 'Datos obtenidos directamente de las entidades oficiales.';

  String dollarTypeName(DollarType type) {
    if (isEnglish) {
      switch (type) {
        case DollarType.blue:
          return 'Blue dollar';
        case DollarType.official:
          return 'Official dollar';
        case DollarType.crypto:
          return 'Crypto dollar';
        case DollarType.tarjeta:
          return 'Card dollar';
        case DollarType.mep:
          return 'MEP dollar';
        case DollarType.ccl:
          return 'CCL dollar';
      }
    }
    return type.displayName;
  }

  // Settings
  String get darkMode => isEnglish ? 'Dark mode' : 'Modo oscuro';
  String get darkModeSubtitle =>
      isEnglish
          ? 'Better experience in low light'
          : 'Mejor experiencia en ambientes con poca luz';
  String get pushNotifications =>
      isEnglish ? 'Push notifications' : 'Notificaciones Push';
  String get pushNotificationsSubtitle =>
      isEnglish
          ? 'Market open and close alerts'
          : 'Alertas de apertura y cierre del mercado';
  String get openSettings =>
      isEnglish ? 'Open Settings' : 'Abrir Ajustes';
  String get openSettingsIos =>
      isEnglish ? 'Open iPhone Settings' : 'Abrir Ajustes del iPhone';
  String get notificationsDisabledSubtitle =>
      isEnglish
          ? 'Notifications are off. Turn them on in Settings to get alerts.'
          : 'Las notificaciones están desactivadas. Actívalas en Ajustes para recibir alertas.';
  String get visibleDollarTypes =>
      isEnglish ? 'Visible dollar types' : 'Tipos de Dólar Visibles';
  String get visibleDollarTypesSubtitle =>
      isEnglish
          ? 'Choose which types to show on the main screen'
          : 'Selecciona qué tipos de dólar ver en la pantalla principal';
  String get dataSource => isEnglish ? 'Data source' : 'Fuente de datos';
  String get version => isEnglish ? 'Version' : 'Versión';
  String get about => isEnglish ? 'About' : 'Acerca de';

  // Calculator
  String get exchangeRateType =>
      isEnglish ? 'Exchange rate type' : 'Tipo de cambio';
  String get amountInPesos => isEnglish ? 'Amount in pesos' : 'Monto en pesos';
  String get amountInDollars =>
      isEnglish ? 'Amount in dollars' : 'Monto en dólares';
  String get resultInUSD => isEnglish ? 'Result in USD' : 'Resultado en USD';
  String get resultInARS => isEnglish ? 'Result in ARS' : 'Resultado en ARS';
  String get enterValidAmount =>
      isEnglish ? 'Enter a valid amount' : 'Ingresá un monto válido';
  String get calculatorSourceOfficial =>
      isEnglish
          ? 'Uses Banco Nación rate for official dollar'
          : 'Se usa la cotización del Banco Nación para el dólar oficial';
  String get calculatorSourceCrypto =>
      isEnglish
          ? 'Uses Binance rate for crypto dollar'
          : 'Se usa la cotización de Binance para el dólar cripto';
  String get bankNation => isEnglish ? '(Nación)' : '(Nación)';
  String get binanceP2P => isEnglish ? '(Binance)' : '(Binance)';
}

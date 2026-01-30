import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Sistema de logging personalizado para filtrar y organizar logs
/// 
/// Uso:
/// ```dart
/// Logger.debug('Mensaje de debug');
/// Logger.info('Mensaje informativo');
/// Logger.warning('Advertencia');
/// Logger.error('Error');
/// ```
class Logger {
  // Niveles de logging
  static const bool _showDebug = true;
  static const bool _showInfo = true;
  static const bool _showWarning = true;
  static const bool _showError = true;

  // Prefijos para cada nivel
  static const String _debugPrefix = '🔍';
  static const String _infoPrefix = '✅';
  static const String _warningPrefix = '⚠️';
  static const String _errorPrefix = '❌';

  /// Log de debug (información detallada para desarrollo)
  static void debug(String message, {String? tag}) {
    if (_showDebug) {
      _log(_debugPrefix, message, tag: tag);
    }
  }

  /// Log informativo (operaciones exitosas)
  static void info(String message, {String? tag}) {
    if (_showInfo) {
      _log(_infoPrefix, message, tag: tag);
    }
  }

  /// Log de advertencia (situaciones que requieren atención)
  static void warning(String message, {String? tag}) {
    if (_showWarning) {
      _log(_warningPrefix, message, tag: tag);
    }
  }

  /// Log de error (errores que requieren acción)
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    if (_showError) {
      _log(_errorPrefix, message, tag: tag);
      if (error != null) {
        _log(_errorPrefix, 'Error: $error', tag: tag);
      }
      if (stackTrace != null && kDebugMode) {
        _log(_errorPrefix, 'Stack: $stackTrace', tag: tag);
      }
    }
  }

  /// Método interno para logging
  static void _log(String prefix, String message, {String? tag}) {
    final tagStr = tag != null ? '[$tag] ' : '';
    final logMessage = '$prefix $tagStr$message';
    
    // Usar developer.log para mejor control en Flutter
    developer.log(
      logMessage,
      name: 'DolarApp',
      level: _getLogLevel(prefix),
    );
  }

  /// Convierte el prefijo a nivel de log
  static int _getLogLevel(String prefix) {
    switch (prefix) {
      case _debugPrefix:
        return 0; // Finest
      case _infoPrefix:
        return 800; // Info
      case _warningPrefix:
        return 900; // Warning
      case _errorPrefix:
        return 1000; // Severe
      default:
        return 800;
    }
  }

  /// Log específico para FCM
  static void fcm(String message) => debug(message, tag: 'FCM');

  /// Log específico para HTTP requests
  static void http(String message) => debug(message, tag: 'HTTP');

  /// Log específico para providers
  static void provider(String message) => debug(message, tag: 'Provider');

  /// Log específico para navegación
  static void navigation(String message) => debug(message, tag: 'Nav');

  /// Log específico para actualizaciones
  static void update(String message) => info(message, tag: 'Update');
}


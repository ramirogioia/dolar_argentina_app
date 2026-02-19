import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para solicitar reseñas in-app siguiendo buenas prácticas de UX.
///
/// Basado en guías de Apple/Google:
/// - Pedir después de engagement significativo (varias sesiones, varios días)
/// - No interrumpir tareas
/// - Respetar cuotas (iOS máx 3/año, Android tiene límites)
/// - Momento positivo: cuando el usuario ve contenido útil
class ReviewService {
  static const String _keyLaunchCount = 'review_launch_count';
  static const String _keyFirstLaunchDate = 'review_first_launch_date';
  static const String _keyLastReviewRequestDate = 'review_last_request_date';

  /// Mínimo de aperturas antes de considerar pedir reseña
  static const int minLaunchCount = 4;

  /// Días desde primera apertura antes de pedir (evita molestar a usuarios nuevos)
  static const int minDaysSinceFirstLaunch = 3;

  /// Días mínimos entre solicitudes (Apple recomienda ~4 meses; usamos ~120 días)
  static const int minDaysBetweenRequests = 120;

  /// Apple App Store ID (App Store Connect → App Information → Apple ID)
  static const String _appStoreId = '6758462259';

  static final InAppReview _inAppReview = InAppReview.instance;

  /// Registra una apertura de la app. Llamar al iniciar (main.dart).
  static Future<void> recordLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyLaunchCount) ?? 0;
    await prefs.setInt(_keyLaunchCount, count + 1);

    if (prefs.getString(_keyFirstLaunchDate) == null) {
      await prefs.setString(
        _keyFirstLaunchDate,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// Verifica si conviene pedir reseña y, si corresponde, muestra el diálogo nativo.
  ///
  /// Llamar en un momento positivo (ej. home con datos cargados, tras pull-to-refresh).
  /// No bloquea ni interrumpe; solo muestra si las condiciones se cumplen.
  static Future<void> maybeRequestReview() async {
    if (!await _shouldAsk()) return;
    if (!await _inAppReview.isAvailable()) return;

    try {
      await _inAppReview.requestReview();
      await _markRequested();
    } catch (_) {
      // Silenciar: el API tiene cuotas, puede fallar sin problema
    }
  }

  /// Abre la ficha de la app en la store (para botón "Calificar" en ajustes).
  /// No tiene cuota; usar cuando el usuario lo pide explícitamente.
  static Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(appStoreId: _appStoreId);
  }

  static Future<bool> _shouldAsk() async {
    final prefs = await SharedPreferences.getInstance();

    final launchCount = prefs.getInt(_keyLaunchCount) ?? 0;
    if (launchCount < minLaunchCount) return false;

    final firstLaunchStr = prefs.getString(_keyFirstLaunchDate);
    if (firstLaunchStr == null) return false;
    final firstLaunch = DateTime.tryParse(firstLaunchStr);
    if (firstLaunch == null) return false;
    final daysSinceFirst = DateTime.now().difference(firstLaunch).inDays;
    if (daysSinceFirst < minDaysSinceFirstLaunch) return false;

    final lastRequestStr = prefs.getString(_keyLastReviewRequestDate);
    if (lastRequestStr != null) {
      final lastRequest = DateTime.tryParse(lastRequestStr);
      if (lastRequest != null) {
        final daysSinceLast = DateTime.now().difference(lastRequest).inDays;
        if (daysSinceLast < minDaysBetweenRequests) return false;
      }
    }

    return true;
  }

  static Future<void> _markRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastReviewRequestDate,
      DateTime.now().toIso8601String(),
    );
  }
}

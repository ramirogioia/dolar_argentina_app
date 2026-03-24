import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/router/app_router.dart';
import '../l10n/app_localizations.dart';

/// Reseñas: diálogo propio (mensaje cercano) + intento de flujo nativo o tienda.
///
/// Muestra si: 4.ª apertura **o** ≥4 días desde la primera apertura.
/// Cooldown de 30 días tras cualquier cierre del diálogo (calificar, ahora no o fuera).
class ReviewService {
  static const String _keyLaunchCount = 'review_launch_count';
  static const String _keyFirstLaunchDate = 'review_first_launch_date';
  /// Última vez que se mostró / cerró el diálogo de reseña (cooldown)
  static const String _keyLastReviewPromptDate = 'review_last_prompt_date_v2';

  static const int minLaunchCount = 4;
  static const int minDaysInstalled = 4;
  static const int cooldownDays = 30;

  static const String _appStoreId = '6758462259';

  static final InAppReview _inAppReview = InAppReview.instance;
  static bool _dialogInFlight = false;

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

  /// Muestra el diálogo si corresponde. Usar [navigatorKey.currentContext] vía router.
  static Future<void> showReviewDialogIfNeeded(BuildContext? context) async {
    if (_dialogInFlight) return;
    if (!await _shouldShowPrompt()) return;

    final ctx = navigatorKey.currentContext ?? context;
    if (ctx == null || !ctx.mounted) return;

    _dialogInFlight = true;
    try {
      final l10n = AppLocalizations.of(ctx);
      final wantRate = await showDialog<bool>(
        context: ctx,
        useRootNavigator: true,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.reviewDialogTitle),
          content: Text(l10n.reviewDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.reviewDialogLater),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.reviewDialogRate),
            ),
          ],
        ),
      );

      await _markPromptCooldown();

      if (wantRate == true) {
        await _openReviewFlow();
      }
    } finally {
      _dialogInFlight = false;
    }
  }

  static Future<void> _openReviewFlow() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await _inAppReview.openStoreListing(appStoreId: _appStoreId);
      }
    } catch (_) {
      try {
        await _inAppReview.openStoreListing(appStoreId: _appStoreId);
      } catch (_) {}
    }
  }

  static Future<bool> _shouldShowPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    final lastStr = prefs.getString(_keyLastReviewPromptDate);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null) {
        final days = DateTime.now().difference(last).inDays;
        if (days < cooldownDays) return false;
      }
    }

    final launchCount = prefs.getInt(_keyLaunchCount) ?? 0;
    final firstStr = prefs.getString(_keyFirstLaunchDate);
    if (firstStr == null) return false;
    final first = DateTime.tryParse(firstStr);
    if (first == null) return false;
    final daysInstalled = DateTime.now().difference(first).inDays;

    final fourthOpenOrMore = launchCount >= minLaunchCount;
    final enoughDays = daysInstalled >= minDaysInstalled;

    return fourthOpenOrMore || enoughDays;
  }

  static Future<void> _markPromptCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastReviewPromptDate,
      DateTime.now().toIso8601String(),
    );
  }

  /// Ajustes: primero intenta el popup nativo de estrellas; si no está disponible, abre la tienda.
  static Future<void> requestReview() async {
    await _openReviewFlow();
  }

  /// Abre la tienda directamente (fallback cuando requestReview no está disponible).
  static Future<void> openStoreListing() async {
    await _inAppReview.openStoreListing(appStoreId: _appStoreId);
  }
}

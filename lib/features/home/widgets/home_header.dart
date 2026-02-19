import 'dart:async';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class HomeHeader extends StatefulWidget {
  /// Cuándo se refrescaron los datos (para "Refrescado hace X").
  final DateTime updatedAt;
  /// Timestamp de la última medición del backend (para "Última actualización: ...").
  final DateTime? lastMeasurementAt;

  const HomeHeader({
    super.key,
    required this.updatedAt,
    this.lastMeasurementAt,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _timeAgoText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final difference = DateTime.now().difference(widget.updatedAt);
    if (difference.inSeconds < 60) return l10n.timeAgoJustNow;
    if (difference.inMinutes < 60) return l10n.timeAgoMinutes(difference.inMinutes);
    return l10n.timeAgoHours(difference.inHours);
  }

  /// Formatea la fecha/hora en zona Argentina (UTC-3), como la envía el backend.
  static String _formatLastMeasurement(DateTime d) {
    final arg = d.toUtc().subtract(const Duration(hours: 3));
    final y = arg.year;
    final m = arg.month.toString().padLeft(2, '0');
    final day = arg.day.toString().padLeft(2, '0');
    final h = arg.hour.toString().padLeft(2, '0');
    final min = arg.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.25; // Logo más pequeño (25% del ancho)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: MediaQuery.of(context).padding.top +
            8, // Alineado con la tuerca (SafeArea + 8)
        bottom: 8, // Padding inferior para la línea divisoria
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo centrado - más compacto
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Image.asset(
              'assets/icon/app_icon_final.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${AppLocalizations.of(context).refreshedPrefix} ${_timeAgoText(context)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
            textAlign: TextAlign.center,
          ),
          if (widget.lastMeasurementAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context).lastUpdate}: ${_formatLastMeasurement(widget.lastMeasurementAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.85),
                    letterSpacing: 0.1,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          // Línea divisoria
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ]
                    : [
                        Colors.transparent,
                        const Color(0xFF2196F3).withOpacity(0.2),
                        const Color(0xFF2196F3).withOpacity(0.4),
                        const Color(0xFF2196F3).withOpacity(0.2),
                        Colors.transparent,
                      ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

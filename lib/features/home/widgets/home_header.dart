import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/models/app_links_variables.dart';
import '../../../l10n/app_localizations.dart';

class HomeHeader extends StatefulWidget {
  /// Momento en que la app obtuvo los datos (consulta). Misma base para
  /// "Refrescado hace X" y "Última actualización: ..."; solo cambia con refresh manual.
  final DateTime updatedAt;

  /// URLs desde `versions/variables` (se pasan desde el padre con Riverpod).
  final AppLinksVariables? appLinks;

  const HomeHeader({
    super.key,
    required this.updatedAt,
    this.appLinks,
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
    if (difference.inMinutes < 60) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    }
    return l10n.timeAgoHours(difference.inHours);
  }

  /// Fecha/hora local del dispositivo (momento de la consulta en la app).
  static String _formatConsultLocalTime(DateTime d) {
    final l = d.toLocal();
    final y = l.year;
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Botón de link con ícono Material: fondo transparente, sin borde.
  Widget _linkButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55)
        ?? Colors.grey;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  /// Botón de link con ícono Font Awesome: fondo transparente, sin borde.
  Widget _faLinkButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.55)
        ?? Colors.grey;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FaIcon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _dividerLine(bool isDark) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.25;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final links = widget.appLinks;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
            '${l10n.refreshedPrefix} ${_timeAgoText(context)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Stack que se expande al ancho real de pantalla (sin padding negativo)
          SizedBox(
            width: screenWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Texto centrado en todo el ancho
                Text(
                  '${l10n.lastUpdate}: ${_formatConsultLocalTime(widget.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.85),
                        letterSpacing: 0.1,
                      ),
                  textAlign: TextAlign.center,
                ),
                // Botón Twitter/X pegado al borde izquierdo real
                if (links != null && links.hasTwitter)
                  Positioned(
                    left: 0,
                    child: _faLinkButton(
                      context: context,
                      icon: FontAwesomeIcons.twitter,
                      tooltip: l10n.linkTwitterLabel,
                      onTap: () => _openUrl(links.urlTwitter!),
                    ),
                  ),
                // Botón Web pegado al borde derecho real
                if (links != null && links.hasWeb)
                  Positioned(
                    right: 0,
                    child: _linkButton(
                      context: context,
                      icon: Icons.language_rounded,
                      tooltip: l10n.linkWebLabel,
                      onTap: () => _openUrl(links.urlWeb!),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _dividerLine(isDark),
        ],
      ),
    );
  }
}

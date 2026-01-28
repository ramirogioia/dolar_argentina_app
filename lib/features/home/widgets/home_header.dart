import 'dart:async';
import 'package:flutter/material.dart';

class HomeHeader extends StatefulWidget {
  final DateTime updatedAt;

  const HomeHeader({super.key, required this.updatedAt});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  Timer? _timer;
  String _timeAgoText = '';

  @override
  void initState() {
    super.initState();
    _updateTimeAgo();
    // Actualizar cada minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimeAgo();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.updatedAt);

    if (difference.inSeconds < 60) {
      _timeAgoText = 'hace un momento';
    } else if (difference.inMinutes == 1) {
      _timeAgoText = 'hace 1 min';
    } else if (difference.inMinutes < 60) {
      _timeAgoText = 'hace ${difference.inMinutes} min';
    } else if (difference.inHours == 1) {
      _timeAgoText = 'hace 1 hora';
    } else {
      _timeAgoText = 'hace ${difference.inHours} horas';
    }
  }

  @override
  void didUpdateWidget(HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió la fecha de actualización, actualizar el texto inmediatamente
    if (oldWidget.updatedAt != widget.updatedAt) {
      _updateTimeAgo();
    }
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
          const SizedBox(height: 1), // Espacio mínimo entre logo y texto
          // Texto de actualización centrado - más grande y en cursiva
          Text(
            'Actualizado $_timeAgoText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12, // Más grande
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic, // Cursiva
                  letterSpacing: 0.2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Línea divisoria mejorada con gradiente y sombra
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

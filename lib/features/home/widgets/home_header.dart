import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final DateTime updatedAt;

  const HomeHeader({super.key, required this.updatedAt});

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'hace menos de 1 min';
    } else if (difference.inMinutes == 1) {
      return 'hace 1 min';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours == 1) {
      return 'hace 1 hora';
    } else {
      return 'hace ${difference.inHours} horas';
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
        top: 2, // Padding superior mínimo
        bottom: 8, // Padding inferior para la línea divisoria
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo centrado - más compacto
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Image.asset(
              'assets/icon/app_icon3.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 1), // Espacio mínimo entre logo y texto
          // Texto de actualización centrado - más compacto
          Text(
            'Actualizado ${_getTimeAgo(updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 9, // Fuente aún más pequeña
              fontWeight: FontWeight.w400,
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

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
    final logoSize =
        screenWidth * 0.30; // Logo más pequeño (30% del ancho)

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 4, // Padding superior mínimo
        bottom: 4, // Padding inferior reducido
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Celeste suave
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo centrado - más compacto
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Fondo celeste que se fusiona con la app
            ),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 2), // Espacio reducido
          // Texto de actualización centrado - más compacto
          Text(
            'Actualizado ${_getTimeAgo(updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9E9E9E),
              fontSize: 10, // Fuente más pequeña
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

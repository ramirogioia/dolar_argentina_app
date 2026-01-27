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
        screenWidth * 0.55; // Logo grande pero optimizado (55% del ancho)

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 0, // Sin padding superior para que quede pegado arriba
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Celeste suave
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo centrado - más arriba
          Image.asset(
            'assets/icon/app_icon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 4),
          // Texto de actualización centrado - más arriba
          Text(
            'Actualizado ${_getTimeAgo(updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF9E9E9E),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

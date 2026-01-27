import 'package:flutter/material.dart';
import '../../../app/utils/currency_formatter.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_type.dart';

class DollarRow extends StatelessWidget {
  final DollarRate rate;

  const DollarRow({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con nombre y cambio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rate.type.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Referencia a Binance solo para Dólar Cripto
                      if (rate.type == DollarType.crypto) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 10,
                              color: const Color(0xFF9E9E9E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Binance P2P',
                              style: TextStyle(
                                fontSize: 9,
                                color: const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (rate.changePercent != null)
                  _buildChangeIndicator(rate.changePercent!),
              ],
            ),
            const SizedBox(height: 16),
            // Compra y Venta
            Row(
              children: [
                Expanded(
                  child: _buildPriceSection(
                    context,
                    'Compra',
                    CurrencyFormatter.format(rate.buy),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceSection(
                    context,
                    'Venta',
                    CurrencyFormatter.format(rate.sell),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF9E9E9E),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                fontSize: 24,
                letterSpacing: -0.8,
                height: 1.1,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeIndicator(double changePercent) {
    final isPositive = changePercent >= 0;
    final color = isPositive
        ? const Color(0xFF4CAF50) // Verde suave
        : const Color(0xFFF44336); // Rojo suave

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

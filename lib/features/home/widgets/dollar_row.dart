import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/utils/currency_formatter.dart';
import '../../../domain/models/bank.dart';
import '../../../domain/models/crypto_platform.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_type.dart';
import '../providers/dollar_providers.dart';

class DollarRow extends ConsumerWidget {
  final DollarRate rate;

  const DollarRow({super.key, required this.rate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si es crypto, usar los valores de la plataforma seleccionada
    // Si es official, usar los valores del banco seleccionado
    final displayRate = rate.type == DollarType.crypto
        ? ref.watch(cryptoPlatformRatesProvider)[
            ref.watch(selectedCryptoPlatformProvider)] ?? rate
        : rate.type == DollarType.official
            ? ref.watch(bankRatesProvider)[
                ref.watch(selectedBankProvider)] ?? rate
            : rate;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                      // Dropdown de plataforma P2P solo para Dólar Cripto
                      if (rate.type == DollarType.crypto) ...[
                        const SizedBox(height: 4),
                        _buildPlatformDropdown(context, ref),
                      ],
                      // Dropdown de banco solo para Dólar Oficial
                      if (rate.type == DollarType.official) ...[
                        const SizedBox(height: 4),
                        _buildBankDropdown(context, ref),
                      ],
                    ],
                  ),
                ),
                if (displayRate.changePercent != null)
                  _buildChangeIndicator(displayRate.changePercent!),
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
                    CurrencyFormatter.format(displayRate.buy),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceSection(
                    context,
                    'Venta',
                    CurrencyFormatter.format(displayRate.sell),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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

  Widget _buildPlatformDropdown(BuildContext context, WidgetRef ref) {
    final selectedPlatform = ref.watch(selectedCryptoPlatformProvider);
    
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CryptoPlatform>(
          value: selectedPlatform,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF9E9E9E)),
          iconSize: 16,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          selectedItemBuilder: (BuildContext context) {
            return CryptoPlatform.values.map((platform) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      platform.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    platform.logoPath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ],
              );
            }).toList();
          },
          items: CryptoPlatform.values.map((platform) {
            return DropdownMenuItem<CryptoPlatform>(
              value: platform,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      platform.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    platform.logoPath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (CryptoPlatform? newPlatform) {
            if (newPlatform != null) {
              ref.read(selectedCryptoPlatformProvider.notifier).state = newPlatform;
            }
          },
        ),
      ),
    );
  }

  Widget _buildBankDropdown(BuildContext context, WidgetRef ref) {
    final selectedBank = ref.watch(selectedBankProvider);
    
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Bank>(
          value: selectedBank,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF9E9E9E)),
          iconSize: 16,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          selectedItemBuilder: (BuildContext context) {
            return Bank.values.map((bank) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      bank.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    bank.logoPath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Si no existe el logo, mostrar un placeholder
                      return const SizedBox(width: 16, height: 16);
                    },
                  ),
                ],
              );
            }).toList();
          },
          items: Bank.values.map((bank) {
            return DropdownMenuItem<Bank>(
              value: bank,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      bank.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    bank.logoPath,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Si no existe el logo, mostrar un placeholder
                      return const SizedBox(width: 16, height: 16);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (Bank? newBank) {
            if (newBank != null) {
              ref.read(selectedBankProvider.notifier).state = newBank;
            }
          },
        ),
      ),
    );
  }
}

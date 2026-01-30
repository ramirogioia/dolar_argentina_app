import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    DollarRate displayRate;
    if (rate.type == DollarType.crypto) {
      final platformRatesAsync = ref.watch(cryptoPlatformRatesProvider);
      final selectedPlatform = ref.watch(selectedCryptoPlatformProvider);
      final platformRates = platformRatesAsync.value ?? {};
      displayRate = platformRates[selectedPlatform] ?? rate;
      // Si el rate del provider no tiene changePercent pero el rate original sí,
      // y son de la misma plataforma, mantener el changePercent del original
      if (displayRate.changePercent == null && rate.changePercent != null) {
        displayRate = DollarRate(
          type: displayRate.type,
          buy: displayRate.buy,
          sell: displayRate.sell,
          changePercent:
              displayRate.buy == rate.buy && displayRate.sell == rate.sell
                  ? rate.changePercent
                  : null,
        );
      }
    } else if (rate.type == DollarType.official) {
      final bankRates = ref.watch(bankRatesProvider);
      final selectedBank = ref.watch(selectedBankProvider);
      final availableBanks = officialBanksFromBackend;
      final effectiveBank = availableBanks.contains(selectedBank)
          ? selectedBank
          : availableBanks.first;
      displayRate = bankRates[effectiveBank] ?? rate;
      // Si el rate del provider no tiene changePercent pero el rate original sí,
      // y son del mismo banco, mantener el changePercent del original
      if (displayRate.changePercent == null && rate.changePercent != null) {
        displayRate = DollarRate(
          type: displayRate.type,
          buy: displayRate.buy,
          sell: displayRate.sell,
          changePercent:
              displayRate.buy == rate.buy && displayRate.sell == rate.sell
                  ? rate.changePercent
                  : null,
        );
      }
    } else {
      displayRate = rate;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD9EDF7),
          width: 1.5,
        ),
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
            // Header: título | dropdown (centrado) | variación
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  rate.type.displayName,
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                // Espacio central: dropdown centrado entre título y variación
                if (rate.type == DollarType.crypto)
                  Expanded(
                    child: Center(child: _buildPlatformDropdown(context, ref)),
                  )
                else if (rate.type == DollarType.official)
                  Expanded(
                    child: Center(child: _buildBankDropdown(context, ref)),
                  )
                else
                  const Spacer(),
                if (displayRate.changePercent != null) ...[
                  const SizedBox(width: 8),
                  _buildChangeIndicator(displayRate.changePercent!),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Compra y Venta
            // Para Dólar Tarjeta sin Compra, mantener Venta en su posición original (derecha)
            Row(
              children: [
                // Mostrar Compra si no es Tarjeta o si tiene valor
                if (displayRate.type != DollarType.tarjeta ||
                    displayRate.buy != null)
                  Expanded(
                    child: _buildPriceSection(
                      context,
                      'Compra',
                      CurrencyFormatter.format(displayRate.buy),
                    ),
                  )
                else
                  // Si es Tarjeta sin Compra, espacio vacío para mantener posición de Venta
                  const Expanded(child: SizedBox()),
                // Solo agregar espacio si se muestra Compra
                if (displayRate.type != DollarType.tarjeta ||
                    displayRate.buy != null)
                  const SizedBox(width: 16),
                // Venta siempre se muestra en su posición original (derecha)
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
    // Determinar el tipo de variación (umbral de 0.01% para considerar "sin variación")
    final absChange = changePercent.abs();
    final isNeutral = absChange < 0.01;
    final isPositive = changePercent > 0.01;

    final color = isNeutral
        ? Colors.grey // Gris para sin variación
        : isPositive
            ? const Color(0xFF4CAF50) // Verde suave para positivo
            : const Color(0xFFF44336); // Rojo suave para negativo

    IconData icon;
    if (isNeutral) {
      icon = Icons.remove; // Línea horizontal para sin variación
    } else {
      icon = isPositive ? Icons.trending_up : Icons.trending_down;
    }

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
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isNeutral
                ? '0.00%'
                : '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 150, // Ancho para mostrar "Binance P2P" / nombres completos en iOS
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.6)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3C3C3C).withOpacity(0.5)
                : const Color(0xFFE3F2FD).withOpacity(0.8),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<CryptoPlatform>(
            value: selectedPlatform,
            isDense: true,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark
                  ? Colors.grey[300]
                  : const Color(0xFF2196F3).withOpacity(0.7),
            ),
            iconSize: 18,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            selectedItemBuilder: (BuildContext context) {
              return CryptoPlatform.values.map((platform) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlatformLogo(platform.logoPath, 14, 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        platform.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
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
                    _buildPlatformLogo(platform.logoPath, 14, 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        platform.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (CryptoPlatform? newPlatform) {
              if (newPlatform != null) {
                ref.read(selectedCryptoPlatformProvider.notifier).state =
                    newPlatform;
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBankDropdown(BuildContext context, WidgetRef ref) {
    final selectedBank = ref.watch(selectedBankProvider);
    final availableBanks = officialBanksFromBackend;
    final effectiveBank = availableBanks.contains(selectedBank)
        ? selectedBank
        : availableBanks.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 150, // Ancho para mostrar "Banco Nación" / nombres completos en iOS
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E).withOpacity(0.6)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3C3C3C).withOpacity(0.5)
                : const Color(0xFFE3F2FD).withOpacity(0.8),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Bank>(
            value: effectiveBank,
            isDense: true,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark
                  ? Colors.grey[300]
                  : const Color(0xFF2196F3).withOpacity(0.7),
            ),
            iconSize: 18,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            selectedItemBuilder: (BuildContext context) {
              return availableBanks.map((bank) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBankLogo(bank.logoPath, 14, 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        bank.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                );
              }).toList();
            },
            items: availableBanks.map((bank) {
              return DropdownMenuItem<Bank>(
                value: bank,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBankLogo(bank.logoPath, 14, 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        bank.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
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
      ),
    );
  }

  Widget _buildBankLogo(String logoPath, double width, double height) {
    if (logoPath.endsWith('.svg')) {
      return SvgPicture.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(width: width, height: height),
      );
    } else {
      return Image.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(width: width, height: height);
        },
      );
    }
  }

  Widget _buildPlatformLogo(String logoPath, double width, double height) {
    if (logoPath.endsWith('.svg')) {
      return SvgPicture.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(width: width, height: height),
      );
    } else {
      return Image.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(width: width, height: height);
        },
      );
    }
  }
}

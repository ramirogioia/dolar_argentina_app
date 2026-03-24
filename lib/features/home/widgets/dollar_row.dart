import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/utils/currency_formatter.dart';
import '../../../domain/models/bank.dart';
import '../../../domain/models/crypto_platform.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_type.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/dollar_providers.dart';

class DollarRow extends ConsumerWidget {
  final DollarRate rate;
  final DateTime? lastMeasurementAt;

  const DollarRow({super.key, required this.rate, this.lastMeasurementAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si es crypto, usar los valores de la plataforma seleccionada
    // Si es official, usar los valores del banco seleccionado
    DollarRate displayRate;
    Bank? selectedBankForIcon;
    CryptoPlatform? selectedPlatformForIcon;

    if (rate.type == DollarType.crypto) {
      final platformRatesAsync = ref.watch(cryptoPlatformRatesProvider);
      final selectedPlatform = ref.watch(selectedCryptoPlatformProvider);
      final platformRates = platformRatesAsync.value ?? {};
      final effectivePlatforms = ref.watch(platformsWithDataProvider);
      final effectivePlatformsList = effectivePlatforms.isNotEmpty
          ? effectivePlatforms
          : [CryptoPlatform.binance];
      final effectivePlatform =
          effectivePlatformsList.contains(selectedPlatform)
              ? selectedPlatform
              : effectivePlatformsList.first;
      selectedPlatformForIcon = effectivePlatform;
      displayRate = platformRates[effectivePlatform] ?? rate;
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
      final availableBanks = ref.watch(banksWithDataProvider);
      final effectiveBanks =
          availableBanks.isNotEmpty ? availableBanks : [Bank.nacion];
      final effectiveBank = effectiveBanks.contains(selectedBank)
          ? selectedBank
          : effectiveBanks.first;
      selectedBankForIcon = effectiveBank;
      displayRate = bankRates[effectiveBank] ?? rate;
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

    // Si los datos son de un día anterior (ej. 8am sin corrida del día), mostrar 0%
    final effectiveChangePercent = _isVariationStale(lastMeasurementAt)
        ? 0.0
        : displayRate.changePercent;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final celesteTopLine =
        isDark ? AppTheme.cardTopAccentBlueDark : AppTheme.cardTopAccentBlue;

    final borderColor = isDark
        ? Colors.grey.shade700
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
          top: BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(isDark ? 0.22 : 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ShimmerTopBar(color: celesteTopLine, height: 4),
            ColoredBox(
              color: Theme.of(context).cardColor,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: título | dropdown (centrado) | variación
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dollarTypeName(rate.type),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 8),
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
                    if (effectiveChangePercent != null) ...[
                      const SizedBox(width: 8),
                      _buildChangeIndicator(effectiveChangePercent),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (displayRate.type != DollarType.tarjeta ||
                        displayRate.buy != null)
                      Expanded(
                        child: _buildPriceSection(
                          context,
                          l10n.buy,
                          CurrencyFormatter.format(displayRate.buy),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    if (displayRate.type != DollarType.tarjeta ||
                        displayRate.buy != null)
                      const SizedBox(width: 16),
                    Expanded(
                      child: _buildPriceSection(
                        context,
                        l10n.sell,
                        CurrencyFormatter.format(displayRate.sell),
                      ),
                    ),
                    if (selectedBankForIcon != null) ...[
                      const SizedBox(width: 12),
                      _buildBankLogo(context, selectedBankForIcon.logoPath, 40, 40),
                      const SizedBox(width: 8),
                    ] else if (selectedPlatformForIcon != null) ...[
                      const SizedBox(width: 12),
                      _buildPlatformLogo(context, selectedPlatformForIcon.logoPath, 40, 40),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 36), // espacio para el botón compartir
                  ],
                ),
              ],
            ),
                  ),
                  // Botón compartir: borde inferior derecho
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _shareRate(context, displayRate, l10n),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// true si los datos son de un día calendario anterior (medianoche pasó, sin corrida nueva).
  static bool _isVariationStale(DateTime? lastMeasurementAt) {
    if (lastMeasurementAt == null) return false;
    final dataLocal = lastMeasurementAt.toLocal();
    final dataDate =
        DateTime(dataLocal.year, dataLocal.month, dataLocal.day);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return dataDate.isBefore(today);
  }

  static String _formatShareNumber(double value, bool useComma) {
    final int v = value.round();
    if (useComma) {
      return v.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  static void _shareRate(
    BuildContext context,
    DollarRate displayRate,
    AppLocalizations l10n,
  ) {
    final typeName = l10n.dollarTypeName(displayRate.type);
    final buy = displayRate.buy;
    final sell = displayRate.sell ?? 0;
    final useComma = l10n.useCommaForThousands;
    final buyStr =
        buy != null && buy > 0 ? _formatShareNumber(buy, useComma) : null;
    final sellStr = _formatShareNumber(sell, useComma);

    final String text;
    if (buyStr != null) {
      text = '💵 $typeName — ${l10n.shareToday}\n'
          '${l10n.shareBuyLabel}: \$$buyStr  ·  ${l10n.shareSellLabel}: \$$sellStr\n\n'
          '${l10n.shareSource}: Dólar Argentina\n'
          '${l10n.shareFooter}';
    } else {
      text = '💵 $typeName — ${l10n.shareToday}\n'
          '${l10n.shareSellLabel}: \$$sellStr\n\n'
          '${l10n.shareSource}: Dólar Argentina\n'
          '${l10n.shareFooter}';
    }
    Share.share(text);
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
    final availablePlatforms = ref.watch(platformsWithDataProvider);
    final effectivePlatforms = availablePlatforms.isNotEmpty
        ? availablePlatforms
        : [CryptoPlatform.binance];
    final effectivePlatform =
        effectivePlatforms.contains(selectedPlatform)
            ? selectedPlatform
            : effectivePlatforms.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Si la selección actual no tiene datos, actualizar al primero disponible
    if (effectivePlatforms.isNotEmpty &&
        !effectivePlatforms.contains(selectedPlatform)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCryptoPlatformProvider.notifier).state =
            effectivePlatforms.first;
      });
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: _SelectorTrigger(
        isDark: isDark,
        icon: _buildPlatformLogo(context, effectivePlatform.logoPath, 14, 14),
        label: effectivePlatform.displayName,
        onTap: () => _showPlatformSelector(
          context,
          ref,
          effectivePlatforms,
          effectivePlatform,
          isDark,
        ),
      ),
    );
  }

  void _showPlatformSelector(
    BuildContext context,
    WidgetRef ref,
    List<CryptoPlatform> platforms,
    CryptoPlatform selected,
    bool isDark,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    const itemHeight = 56.0;
    const separatorHeight = 1.0;
    const headerHeight = 36.0;
    final contentHeight = (platforms.length * itemHeight) + headerHeight + 24;
    final maxHeight = contentHeight.clamp(200.0, screenHeight * 0.5);
    final scrollController = ScrollController();
    final selectedIndex = platforms.indexOf(selected);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients && selectedIndex > 0) {
            final offset = (selectedIndex * (itemHeight + separatorHeight))
                .clamp(0.0, scrollController.position.maxScrollExtent);
            scrollController.jumpTo(offset);
          }
        });
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: platforms.length,
                  separatorBuilder: (_, __) => Divider(
                    height: separatorHeight,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  itemBuilder: (_, i) {
                  final p = platforms[i];
                  final isSelected = p == selected;
                  return ListTile(
                    leading: _buildPlatformLogo(context, p.logoPath, 24, 24),
                    title: Text(
                      p.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, size: 20, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      ref.read(selectedCryptoPlatformProvider.notifier).state = p;
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  Widget _buildBankDropdown(BuildContext context, WidgetRef ref) {
    final selectedBank = ref.watch(selectedBankProvider);
    final availableBanks = ref.watch(banksWithDataProvider);
    final effectiveBanks =
        availableBanks.isNotEmpty ? availableBanks : [Bank.nacion];
    final effectiveBank =
        effectiveBanks.contains(selectedBank) ? selectedBank : effectiveBanks.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Si la selección actual no tiene datos, actualizar al primero disponible
    if (effectiveBanks.isNotEmpty && !effectiveBanks.contains(selectedBank)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedBankProvider.notifier).state = effectiveBanks.first;
      });
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: _SelectorTrigger(
        isDark: isDark,
        icon: _buildBankLogo(context, effectiveBank.logoPath, 14, 14),
        label: effectiveBank.displayName,
        onTap: () => _showBankSelector(
          context,
          ref,
          effectiveBanks,
          effectiveBank,
          isDark,
        ),
      ),
    );
  }

  void _showBankSelector(
    BuildContext context,
    WidgetRef ref,
    List<Bank> banks,
    Bank selected,
    bool isDark,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    const itemHeight = 56.0;
    const separatorHeight = 1.0;
    const headerHeight = 36.0;
    final contentHeight = (banks.length * itemHeight) + headerHeight + 24;
    final maxHeight = contentHeight.clamp(200.0, screenHeight * 0.5);
    final scrollController = ScrollController();
    final selectedIndex = banks.indexOf(selected);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients && selectedIndex > 0) {
            final offset = (selectedIndex * (itemHeight + separatorHeight))
                .clamp(0.0, scrollController.position.maxScrollExtent);
            scrollController.jumpTo(offset);
          }
        });
        return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: banks.length,
                separatorBuilder: (_, __) => Divider(
                  height: separatorHeight,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                itemBuilder: (_, i) {
                  final b = banks[i];
                  final isSelected = b == selected;
                  return ListTile(
                    leading: _buildBankLogo(context, b.logoPath, 24, 24),
                    title: Text(
                      b.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, size: 20, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      ref.read(selectedBankProvider.notifier).state = b;
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  /// En modo oscuro intenta logo_n (ej. banco_nacion_logo_n.png); si no existe, usa el default.
  Widget _buildBankLogo(BuildContext context, String logoPath, double width, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildLogo(context, logoPath, width, height, isDark);
  }

  Widget _buildPlatformLogo(BuildContext context, String logoPath, double width, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildLogo(context, logoPath, width, height, isDark);
  }

  Widget _buildLogo(BuildContext context, String logoPath, double width, double height, bool isDark) {
    if (logoPath.endsWith('.svg')) {
      return SvgPicture.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => SizedBox(width: width, height: height),
      );
    }
    // PNG: en modo oscuro intenta _n; si no existe, errorBuilder carga el default
    final pathToTry = isDark ? logoPath.replaceFirst('.png', '_n.png') : logoPath;
    return Image.asset(
      pathToTry,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        logoPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
      ),
    );
  }
}

/// Botón que abre el selector en modal bottom sheet (misma apariencia que antes).
class _SelectorTrigger extends StatelessWidget {
  final bool isDark;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _SelectorTrigger({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.cardTopAccentBlueDark.withOpacity(0.9)
                      : AppTheme.cardTopAccentBlue.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: isDark
                          ? Colors.grey[300]
                          : const Color(0xFF2196F3).withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra superior con brillo sutil animado que recorre el borde.
class _ShimmerTopBar extends StatefulWidget {
  final Color color;
  final double height;

  const _ShimmerTopBar({required this.color, this.height = 4});

  @override
  State<_ShimmerTopBar> createState() => _ShimmerTopBarState();
}

class _ShimmerTopBarState extends State<_ShimmerTopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(color: widget.color),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return Align(
                alignment: Alignment(_animation.value * 2 - 1, 0),
                child: Container(
                  width: 80,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

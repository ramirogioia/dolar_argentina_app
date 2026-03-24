import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/dollar_type.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/shimmer_top_bar.dart';
import '../../home/providers/dollar_providers.dart';
import '../../home/widgets/ad_banner.dart';

class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DollarType _selectedType = DollarType.blue;
  bool _isPesosToDollar = false;
  double? _result;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = _controller.text.replaceAll(',', '.');
    final amount = double.tryParse(input);

    if (amount == null || amount <= 0) {
      setState(() => _result = null);
      return;
    }

    final snapshotAsync = ref.read(dollarSnapshotProvider);
    final snapshot = snapshotAsync.valueOrNull;
    if (snapshot == null) {
      setState(() => _result = null);
      return;
    }

    double? rate;

    if (_selectedType == DollarType.official) {
      final bankRates = ref.read(bankRatesProvider);
      if (bankRates.isNotEmpty) {
        rate = bankRates.values.first.sell;
      }
    } else {
      final dollarRate = snapshot.rates.firstWhere(
        (r) => r.type == _selectedType,
        orElse: () => const DollarRate(type: DollarType.blue),
      );
      rate = dollarRate.sell;
    }

    if (rate == null || rate <= 0) {
      setState(() => _result = null);
      return;
    }

    setState(() {
      if (_isPesosToDollar) {
        _result = amount / rate!;
      } else {
        _result = amount * rate!;
      }
    });
  }

  void _swapDirection() {
    setState(() {
      _isPesosToDollar = !_isPesosToDollar;
      _controller.clear();
      _result = null;
    });
  }

  void _applyAmount(double amount) {
    _controller.text = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    _calculate();
  }

  double? _getRateForSelectedType(DollarSnapshot? snapshot, WidgetRef ref) {
    if (snapshot == null) return null;
    if (_selectedType == DollarType.official) {
      final bankRates = ref.read(bankRatesProvider);
      if (bankRates.isEmpty) return null;
      return bankRates.values.first.sell;
    }
    for (final r in snapshot.rates) {
      if (r.type == _selectedType) return r.sell;
    }
    return null;
  }

  String _formatCurrency(double value, bool isDollar) {
    if (isDollar) {
      return 'USD ${value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      final parts = value.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '\$$intPart,${parts[1]}';
    }
  }

  void _showTypeSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final types = DollarType.values;
    const itemHeight = 56.0;
    const separatorHeight = 1.0;
    const headerHeight = 36.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final contentHeight = (types.length * itemHeight) + headerHeight + 24;
    final maxHeight = contentHeight.clamp(200.0, screenHeight * 0.5);
    final scrollController = ScrollController();
    final selectedIndex = types.indexOf(_selectedType);

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
            mainAxisSize: MainAxisSize.min,
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
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: types.length,
                  separatorBuilder: (_, __) => Divider(
                    height: separatorHeight,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  itemBuilder: (_, i) {
                    final type = types[i];
                    final isSelected = type == _selectedType;
                    final subtitle = type == DollarType.official
                        ? l10n.bankNation
                        : type == DollarType.crypto
                            ? l10n.binanceP2P
                            : null;
                    return ListTile(
                      leading: Icon(
                        _iconForType(type),
                        size: 24,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      title: Text(
                        l10n.dollarTypeName(type),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: subtitle != null
                          ? Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          _calculate();
                        });
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

  static const List<int> _quickAmounts = [100, 500, 1000, 5000, 10000, 50000];

  Widget _buildAmountQuickGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget cell(int amount) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: AppTheme.primaryBlue.withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.45)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _applyAmount(amount.toDouble()),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatCurrency(amount.toDouble(), !_isPesosToDollar),
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: isDark ? Colors.white : const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            cell(_quickAmounts[0]),
            cell(_quickAmounts[1]),
            cell(_quickAmounts[2]),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            cell(_quickAmounts[3]),
            cell(_quickAmounts[4]),
            cell(_quickAmounts[5]),
          ],
        ),
      ],
    );
  }

  IconData _iconForType(DollarType type) {
    switch (type) {
      case DollarType.blue:
        return Icons.savings_outlined;
      case DollarType.official:
        return Icons.account_balance_outlined;
      case DollarType.tarjeta:
        return Icons.credit_card_outlined;
      case DollarType.mep:
        return Icons.trending_up_outlined;
      case DollarType.ccl:
        return Icons.public_outlined;
      case DollarType.crypto:
        return Icons.currency_bitcoin_outlined;
    }
  }

  Widget _buildCard({
    required BuildContext context,
    required Widget child,
    required String? title,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final celesteTopLine =
        isDark ? AppTheme.cardTopAccentBlueDark : AppTheme.cardTopAccentBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.transparent,
            width: 1,
          ),
          right: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.transparent,
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.transparent,
            width: 1,
          ),
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
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShimmerTopBar(color: celesteTopLine, height: 4),
            ColoredBox(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: title != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 8),
                          child,
                        ],
                      )
                    : child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final snapshotAsync = ref.watch(dollarSnapshotProvider);
    final snapshot = snapshotAsync.valueOrNull;
    final displayRate = _getRateForSelectedType(snapshot, ref);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.calculator),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card: Tipo de cambio
                    _buildCard(
                      context: context,
                      title: l10n.exchangeRateType,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showTypeSelector(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF3C3C3C)
                                        : AppTheme.cardTopAccentBlue.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconForType(_selectedType),
                                      size: 22,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.dollarTypeName(_selectedType),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (displayRate != null &&
                                              displayRate > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              _isPesosToDollar
                                                  ? '${_formatCurrency(displayRate, false)} = 1 USD'
                                                  : '1 USD = ${_formatCurrency(displayRate, false)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                height: 1.2,
                                                color: isDark
                                                    ? Colors.grey.shade500
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: AppTheme.primaryBlue.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card: Dirección USD ↔ ARS
                    _buildCard(
                      context: context,
                      title: _isPesosToDollar
                          ? l10n.conversionDirectionPesosToDollars
                          : l10n.conversionDirectionDollarsToPesos,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CurrencyPill(
                            label: _isPesosToDollar ? 'ARS' : 'USD',
                            isSelected: true,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _swapDirection,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                              foregroundColor: AppTheme.primaryBlue,
                              iconSize: 22,
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(36, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CurrencyPill(
                            label: _isPesosToDollar ? 'USD' : 'ARS',
                            isSelected: false,
                          ),
                        ],
                      ),
                    ),

                    // Card: Monto
                    _buildCard(
                      context: context,
                      title: _isPesosToDollar ? l10n.amountInPesos : l10n.amountInDollars,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF3C3C3C)
                                    : AppTheme.cardTopAccentBlue.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              key: const ValueKey('calculator_input'),
                              controller: _controller,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*')),
                              ],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              decoration: InputDecoration(
                                hintText: _isPesosToDollar ? '0' : '0.00',
                                hintStyle: TextStyle(
                                  color: (isDark ? Colors.grey : Colors.grey.shade500),
                                  fontSize: 20,
                                ),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 12, right: 6),
                                  child: Icon(
                                    Icons.attach_money_rounded,
                                    color: AppTheme.primaryBlue,
                                    size: 26,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (_) => _calculate(),
                              onSubmitted: (_) =>
                                  FocusScope.of(context).unfocus(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildAmountQuickGrid(context),
                        ],
                      ),
                    ),

                    // Resultado
                    if (_result != null) ...[
                      _buildCard(
                        context: context,
                        title: null,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue.withOpacity(0.12),
                                    AppTheme.primaryBlue.withOpacity(0.06),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/calculator/bills_result_icon.png',
                                    height: 52,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _isPesosToDollar
                                              ? l10n.resultInUSD
                                              : l10n.resultInARS,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatCurrency(
                                              _result!, _isPesosToDollar),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppTheme.primaryBlue,
                                                letterSpacing: -0.5,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Image.asset(
                                    'assets/calculator/bills_result_icon.png',
                                    height: 52,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_controller.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.orange.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.enterValidAmount,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Fuente de datos
                    if (_selectedType == DollarType.official ||
                        _selectedType == DollarType.crypto) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2C).withOpacity(0.6)
                              : Colors.blue.shade50.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF3C3C3C)
                                : Colors.blue.shade200.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedType == DollarType.official
                                    ? l10n.calculatorSourceOfficial
                                    : l10n.calculatorSourceCrypto,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Con resizeToAvoidBottomInset el body se acorta con el teclado: el banner
            // queda pegado al borde superior del teclado (no detrás del IME del sistema).
            const AdBanner(
              customAdUnitId: 'ca-app-pub-6119092953994163/7548189933',
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CurrencyPill({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryBlue.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryBlue
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isSelected ? AppTheme.primaryBlue : null,
        ),
      ),
    );
  }
}

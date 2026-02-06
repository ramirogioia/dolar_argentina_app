import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/dollar_type.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../app/theme/app_theme.dart';
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
  bool _isPesosToDollar = false; // Default: USD → ARS (lo más usado)
  double? _result;
  double? _currentRate; // Cotización actual del tipo seleccionado

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
      // Para oficial, usar la cotización del Nación (primera en bankRates)
      final bankRates = ref.read(bankRatesProvider);
      if (bankRates.isNotEmpty) {
        rate = bankRates.values.first.sell;
      }
    } else {
      // Para los demás, buscar en snapshot.rates por tipo
      final dollarRate = snapshot.rates.firstWhere(
        (r) => r.type == _selectedType,
        orElse: () => const DollarRate(type: DollarType.blue),
      );
      rate = dollarRate.sell;
    }

    if (rate == null || rate <= 0) {
      setState(() {
        _result = null;
        _currentRate = null;
      });
      return;
    }

    setState(() {
      _currentRate = rate;
      if (_isPesosToDollar) {
        // Pesos → Dólares
        _result = amount / rate!;
      } else {
        // Dólares → Pesos
        _result = amount * rate!;
      }
    });
  }

  void _swapDirection() {
    setState(() {
      _isPesosToDollar = !_isPesosToDollar;
      // Limpiar el input y resultado al cambiar de dirección
      _controller.clear();
      _result = null;
    });
  }

  String _formatCurrency(double value, bool isDollar) {
    if (isDollar) {
      // Formato para dólares: USD 1,234.56
      return 'USD ${value.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      // Formato para pesos: $1.234,56
      final parts = value.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return '\$${intPart},${parts[1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Detectar si el teclado está abierto y su altura
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Calculadora'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Selector de tipo de dólar
            Text(
              'Tipo de cambio',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? const Color(0xFF3C3C3C)
                      : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DollarType>(
                  value: _selectedType,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: BorderRadius.circular(12),
                  items: DollarType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(
                            type.displayName,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (type == DollarType.official) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '(Nación)',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        if (type == DollarType.crypto) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '(Binance)',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        _calculate();
                      });
                    }
                  },
                ),
              ),
            ),
            
            // Cotización actual (referencia) - debajo del dropdown
            if (_currentRate != null) ...[
              const SizedBox(height: 12),
              Text(
                _isPesosToDollar 
                    ? '${_formatCurrency(_currentRate!, false)} = 1 USD'
                    : '1 USD = ${_formatCurrency(_currentRate!, false)}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Indicador de dirección (los pills cambian de posición al hacer swap)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Origen (izquierda): USD cuando _isPesosToDollar=false, ARS cuando true
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _isPesosToDollar ? 'ARS' : 'USD',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _swapDirection,
                  icon: Icon(
                    Icons.swap_horiz,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 12),
                // Destino (derecha): ARS cuando _isPesosToDollar=false, USD cuando true
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _isPesosToDollar ? 'USD' : 'ARS',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Input de monto
            Text(
              _isPesosToDollar ? 'Monto en pesos' : 'Monto en dólares',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('calculator_input'),
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              autofocus: false,
              enableInteractiveSelection: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: _isPesosToDollar ? 'ARS 0.00' : 'USD 0.00',
                prefixIcon: Icon(
                  _isPesosToDollar ? Icons.attach_money : Icons.attach_money,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark 
                        ? const Color(0xFF3C3C3C)
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            
            const SizedBox(height: 32),
            
            // Resultado
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.1),
                      AppTheme.primaryBlue.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isPesosToDollar ? 'Resultado en USD' : 'Resultado en ARS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatCurrency(_result!, _isPesosToDollar),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (_controller.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ingresá un monto válido',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Información sobre fuentes
            if (_selectedType == DollarType.official || _selectedType == DollarType.crypto) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF2C2C2C).withOpacity(0.5)
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3C3C3C)
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedType == DollarType.official
                            ? 'Se usa la cotización del Banco Nación para el dólar oficial'
                            : 'Se usa la cotización de Binance para el dólar cripto',
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
          // Banner de AdMob en la parte inferior (oculto cuando el teclado está abierto)
          if (!isKeyboardVisible)
            const AdBanner(
              customAdUnitId: 'ca-app-pub-6119092953994163/2715020872',
            ),
        ],
      ),
    );
  }
}

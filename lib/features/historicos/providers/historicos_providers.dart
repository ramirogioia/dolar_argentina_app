import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../app/constants/api_constants.dart';
import '../../../domain/models/historical_rate.dart';

final historicalSnapshotProvider =
    FutureProvider<HistoricalSnapshot>((ref) async {
  final response = await http
      .get(Uri.parse(historicalDataUrl))
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw Exception('Error ${response.statusCode} al cargar histórico');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return HistoricalSnapshot.fromJson(json);
});

final historicalBinanceSnapshotProvider =
    FutureProvider<HistoricalSnapshot>((ref) async {
  final response = await http
      .get(Uri.parse(historicalBinanceDataUrl))
      .timeout(const Duration(seconds: 20));

  if (response.statusCode != 200) {
    throw Exception('Error ${response.statusCode} al cargar histórico cripto');
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return HistoricalSnapshot.fromJson(json);
});

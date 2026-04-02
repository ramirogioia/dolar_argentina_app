import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateType {
  none,
  kind,
  force,
}

class UpdateInfo {
  final UpdateType type;
  final String version;
  final String versionMinima;
  final List<String> notas;
  final String urlAndroid;
  final String urlIos;

  UpdateInfo({
    required this.type,
    required this.version,
    required this.versionMinima,
    required this.notas,
    required this.urlAndroid,
    required this.urlIos,
  });
}

class VersionChecker {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/ramirogioia/dolar_argentina_back/main/versions/cotizaciones.json';

  /// Verifica si hay actualizaciones disponibles comparando la versión
  /// instalada contra el JSON del backend.
  static Future<UpdateInfo?> verificarActualizacion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionActual = packageInfo.version;

      // GitHub raw CDN puede entregar contenido cacheado; usamos un query
      // param con el día actual para invalidar al menos una vez por día.
      final hoy = DateTime.now();
      final cacheBust = '${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$_versionUrl?v=$cacheBust');

      final response = await http.get(uri, headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      }).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;

      final versionServidor = data['version'] as String;
      final versionMinima = data['version_minima'] as String;
      final requiereActualizacion = data['requiere_actualizacion'] as bool? ?? false;
      final notas = (data['notas_actualizacion'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final urlAndroid = data['url_tienda_android'] as String? ?? '';
      final urlIos = data['url_tienda_ios'] as String? ?? '';

      final cmpMinima = _compararVersiones(versionActual, versionMinima);
      final cmpServidor = _compararVersiones(versionActual, versionServidor);

      // FORCE: versión actual por debajo de la mínima, o flag explícito
      if (cmpMinima < 0 || requiereActualizacion) {
        return UpdateInfo(
          type: UpdateType.force,
          version: versionServidor,
          versionMinima: versionMinima,
          notas: notas,
          urlAndroid: urlAndroid,
          urlIos: urlIos,
        );
      }

      // KIND: hay una versión más nueva pero no es obligatoria
      if (cmpServidor < 0) {
        return UpdateInfo(
          type: UpdateType.kind,
          version: versionServidor,
          versionMinima: versionMinima,
          notas: notas,
          urlAndroid: urlAndroid,
          urlIos: urlIos,
        );
      }

      return UpdateInfo(
        type: UpdateType.none,
        version: versionServidor,
        versionMinima: versionMinima,
        notas: notas,
        urlAndroid: urlAndroid,
        urlIos: urlIos,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compara dos versiones semánticas.
  /// Retorna: -1 si v1 < v2, 0 si iguales, 1 si v1 > v2.
  static int _compararVersiones(String v1, String v2) {
    final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    while (p1.length < 3) { p1.add(0); }
    while (p2.length < 3) { p2.add(0); }
    for (int i = 0; i < 3; i++) {
      if (p1[i] < p2[i]) return -1;
      if (p1[i] > p2[i]) return 1;
    }
    return 0;
  }

  /// Abre la tienda de apps según la plataforma.
  static Future<void> abrirTienda(String urlAndroid, String urlIos) async {
    final url = Platform.isAndroid ? urlAndroid : urlIos;
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}


import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateType {
  none, // No hay actualización
  kind, // Actualización opcional
  force, // Actualización forzada
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
  static const String _defaultVersionUrl =
      'https://raw.githubusercontent.com/ramirogioia/dolar_argentina_back/main/versions/cotizaciones.json';

  /// Verifica si hay actualizaciones disponibles
  static Future<UpdateInfo?> verificarActualizacion({String? versionUrl}) async {
    try {
      // 1. Obtener versión actual de la app
      final packageInfo = await PackageInfo.fromPlatform();
      final versionActual = packageInfo.version; // "1.0.0"

      print('🔍 Verificando actualización. Versión actual: $versionActual');

      // 2. Consultar versión en el servidor
      final url = versionUrl ?? _defaultVersionUrl;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DolarArgentinaApp/1.0',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al verificar versión');
        },
      );

      if (response.statusCode == 200) {
        final versionData = json.decode(response.body) as Map<String, dynamic>;

        final versionServidor = versionData['version'] as String;
        final versionMinima = versionData['version_minima'] as String;
        final requiereActualizacion =
            versionData['requiere_actualizacion'] as bool? ?? false;
        final notas = (versionData['notas_actualizacion'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final urlAndroid =
            versionData['url_tienda_android'] as String? ?? '';
        final urlIos = versionData['url_tienda_ios'] as String? ?? '';

        print(
            '📱 Versión servidor: $versionServidor, mínima: $versionMinima, requiere: $requiereActualizacion');

        // 3. Comparar versiones
        final comparacionMinima =
            _compararVersiones(versionActual, versionMinima);
        final comparacionServidor =
            _compararVersiones(versionActual, versionServidor);

        print(
            '🔍 Comparación mínima: $comparacionMinima, servidor: $comparacionServidor');

        // 4. Determinar tipo de actualización

        // FORCE UPDATE: Si está por debajo de version_minima O requiere_actualizacion es true
        if (comparacionMinima < 0 || requiereActualizacion) {
          print('⚠️ FORCE UPDATE requerido');
          return UpdateInfo(
            type: UpdateType.force,
            version: versionServidor,
            versionMinima: versionMinima,
            notas: notas,
            urlAndroid: urlAndroid,
            urlIos: urlIos,
          );
        }

        // KIND UPDATE: Si está por debajo de version pero por encima de version_minima
        if (comparacionServidor < 0) {
          print('ℹ️ KIND UPDATE disponible');
          return UpdateInfo(
            type: UpdateType.kind,
            version: versionServidor,
            versionMinima: versionMinima,
            notas: notas,
            urlAndroid: urlAndroid,
            urlIos: urlIos,
          );
        }

        // NO HAY ACTUALIZACIÓN
        print('✅ App actualizada');
        return UpdateInfo(
          type: UpdateType.none,
          version: versionServidor,
          versionMinima: versionMinima,
          notas: notas,
          urlAndroid: urlAndroid,
          urlIos: urlIos,
        );
      } else {
        print('⚠️ Error al verificar versión: Status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error verificando versión: $e');
      // En caso de error, NO bloquear la app
    }

    return null; // Error o no hay actualización
  }

  /// Compara dos versiones semánticas (ej: "1.0.0" vs "1.1.0")
  /// Retorna: -1 si v1 < v2, 0 si v1 == v2, 1 si v1 > v2
  static int _compararVersiones(String v1, String v2) {
    final version1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final version2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Normalizar a 3 partes (major.minor.patch)
    while (version1.length < 3) version1.add(0);
    while (version2.length < 3) version2.add(0);

    for (int i = 0; i < 3; i++) {
      if (version1[i] < version2[i]) return -1; // v1 < v2
      if (version1[i] > version2[i]) return 1; // v1 > v2
    }
    return 0; // v1 == v2
  }

  /// Abre la tienda de apps según la plataforma
  static Future<void> abrirTienda(String urlAndroid, String urlIos) async {
    final url = Platform.isAndroid ? urlAndroid : urlIos;
    if (url.isEmpty) {
      print('⚠️ URL de tienda vacía');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Abriendo tienda: $url');
      } else {
        print('⚠️ No se pudo abrir la URL: $url');
      }
    } catch (e) {
      print('❌ Error al abrir tienda: $e');
    }
  }
}


import 'package:flutter/material.dart';
import '../services/version_checker.dart';

/// Muestra el diálogo de actualización forzada (no cancelable)
void mostrarDialogoForceUpdate(BuildContext context, UpdateInfo updateInfo) {
  showDialog(
    context: context,
    barrierDismissible: false, // NO se puede cerrar
    builder: (context) => PopScope(
      canPop: false, // Bloquear botón atrás
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Actualización Requerida',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debes actualizar la app para continuar usando Dólar Argentina.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              if (updateInfo.notas.isNotEmpty) ...[
                Text(
                  'Novedades en la versión ${updateInfo.version}:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                ...updateInfo.notas.map((nota) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              nota,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              VersionChecker.abrirTienda(
                updateInfo.urlAndroid,
                updateInfo.urlIos,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Actualizar Ahora',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Muestra el diálogo de actualización opcional (cancelable)
void mostrarDialogoKindUpdate(BuildContext context, UpdateInfo updateInfo) {
  showDialog(
    context: context,
    barrierDismissible: true, // Se puede cerrar
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.system_update_rounded,
              color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Actualización Disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hay una nueva versión disponible (${updateInfo.version}).',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            if (updateInfo.notas.isNotEmpty) ...[
              Text(
                'Novedades:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              ...updateInfo.notas.map((nota) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            nota,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Más Tarde',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            VersionChecker.abrirTienda(
              updateInfo.urlAndroid,
              updateInfo.urlIos,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Actualizar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}


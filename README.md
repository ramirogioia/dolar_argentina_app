# Dólar Argentina

App simple, rápida y clara para ver cotizaciones del dólar en Argentina.

## Características

- **5 tipos de dólar**: Blue, Oficial, Tarjeta, MEP y Cripto (USDT/USDC - Binance P2P)
- **UI limpia**: Diseño minimalista con fondo blanco y texto oscuro
- **Actualización en tiempo real**: Pull-to-refresh para actualizar datos
- **Datos mock**: Incluye datos de prueba para desarrollo
- **Preparado para backend**: Estructura lista para conectar con Google Sheets Web App

## Requisitos

- Flutter SDK 3.10.7 o superior
- Dart SDK 3.10.7 o superior

## Instalación

1. Clona el repositorio:
```bash
git clone <url-del-repositorio>
cd dolar_argentina_app
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Ejecuta la app:
```bash
flutter run
```

## Configuración del Ícono

1. Coloca tu ícono de la app en `assets/icon/app_icon.png`
   - Dimensiones recomendadas: 1024x1024 px
   - El ícono debe tener fondo blanco, esfera dólar azul y bandera argentina

2. Genera los íconos para todas las plataformas:
```bash
flutter pub run flutter_launcher_icons
```

## Estructura del Proyecto

```
lib/
  app/              # Configuración de la app (router, theme, constants)
  domain/           # Modelos de dominio
    models/
  data/             # Capa de datos
    datasources/    # Fuentes de datos (mock y HTTP)
    repositories/   # Repositorios
  features/         # Features de la app
    home/           # Pantalla principal
    settings/       # Pantalla de ajustes
```

## Integración con Backend (Futuro)

La app está preparada para conectarse a un Google Apps Script Web App que obtenga datos de Google Sheets.

### Pasos para integrar:

1. **Crear Google Apps Script Web App**:
   - Crea un script que lea datos de Google Sheets
   - Publica como Web App
   - Obtén la URL del script

2. **Configurar en la app**:
   - Ve a Ajustes
   - Desactiva "Usar datos mock"
   - Ingresa la URL del backend en "URL Backend"

3. **Formato esperado del backend**:
```json
{
  "updatedAt": "2024-01-23T12:00:00Z",
  "rates": [
    {
      "type": "blue",
      "buy": 1485.0,
      "sell": 1495.0,
      "changePercent": 0.5
    },
    {
      "type": "official",
      "buy": 850.0,
      "sell": 870.0,
      "changePercent": -0.2
    },
    {
      "type": "tarjeta",
      "buy": 1450.0,
      "sell": 1460.0,
      "changePercent": 0.3
    },
    {
      "type": "mep",
      "buy": 1420.0,
      "sell": 1430.0,
      "changePercent": 0.1
    },
    {
      "type": "crypto",
      "buy": 1470.0,
      "sell": 1480.0,
      "changePercent": 0.4
    }
  ]
}
```

### Implementar HttpDollarDataSource

El archivo `lib/data/datasources/http_dollar_data_source.dart` tiene la estructura lista. Solo necesitas:

1. Agregar la dependencia `http` al `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

2. Implementar el método `getDollarRates()` usando `http.get()`
3. Parsear la respuesta JSON usando el método `_parseResponse()` que ya está preparado

## Tecnologías Utilizadas

- **Flutter**: Framework multiplataforma
- **Riverpod**: Gestión de estado
- **GoRouter**: Navegación
- **SharedPreferences**: Persistencia de settings
- **Intl**: Formateo de moneda argentina

## Licencia

Este proyecto es privado.

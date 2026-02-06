# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [1.2.0] - 2026-02

### Agregado
- **Calculadora de conversión**: Nueva pantalla para convertir pesos ↔ dólares con todos los tipos de cambio disponibles. Banner de ads oculto cuando el teclado está abierto para mejor UX.
- **Bybit P2P**: Añadida como opción en el selector de Dólar Cripto.
- Contacto y publicidad (mailto) en Ajustes.
- Versión de la app visible en Ajustes.

### Cambiado
- Sección "Contacto y Publicidad" movida arriba de "Información de la App".
- Debug de notificaciones oculto en Ajustes.

### Corregido
- Notificaciones push en iOS (TestFlight/App Store): el token APNs ahora se asigna a Firebase aunque llegue antes de que Flutter inicialice Firebase; se guarda en nativo y se pasa cuando Dart avisa por method channel.
- Zone mismatch en Crashlytics (Android): inicialización y runApp dentro de la misma Zone.
- Navegación al tocar notificación: comprobación de contexto montado para evitar crashes.
- Banner de anuncios: evita ciclo infinito "Cargando anuncio" / "Anuncio no disponible" en iOS.
- Mailto: espacios correctos en asunto y cuerpo (URL encoding).
- Variación fin de semana: uso del último día hábil para el dólar oficial.

---

## [1.0.0] - 2025

### Agregado
- Cotizaciones en tiempo real: blue, oficial, cripto, tarjeta, MEP, CCL
- Selector de banco para Dólar Oficial y de plataforma para Dólar Cripto
- Variación diaria con indicadores visuales (verde/rojo/gris)
- Notificaciones push (cierre del día)
- Modo oscuro
- Personalización: orden y visibilidad de tipos de dólar
- Fuentes de información y enlaces oficiales
- Contacto y publicidad (mailto)
- Versión visible en Ajustes

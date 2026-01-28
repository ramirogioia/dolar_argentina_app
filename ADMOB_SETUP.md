# Configuración de AdMob - Dólar Argentina App

## Estado Actual

### ⚠️ iOS - Usando Test IDs (Desarrollo)
- **App ID**: `ca-app-pub-3940256099942544~1458002511` (Test ID)
- **Ad Unit ID**: `ca-app-pub-3940256099942544/2934735716` (Test ID)
- **Tamaño**: Large Banner (320x100)
- **Estado**: ⚠️ Usando test IDs para desarrollo
- **IDs Reales Guardados**: 
  - App ID: `ca-app-pub-6119092953994163~6222015453`
  - Ad Unit ID: `ca-app-pub-6119092953994163/2879928015`
  - **Nota**: Cambiar a estos cuando publiques la app

### ⚠️ Android - Usando Test IDs (Desarrollo)
- **App ID**: `ca-app-pub-3940256099942544~3347511713` (Test ID)
- **Ad Unit ID**: `ca-app-pub-3940256099942544/6300978111` (Test ID)
- **Tamaño**: Large Banner (320x100)
- **Estado**: ⚠️ Necesita configuración real cuando publiques

---

## Pasos para Configurar Android en AdMob

### 1. Crear App en AdMob (si no existe)

1. Ve a [AdMob Console](https://apps.admob.com/)
2. Si no tienes una app Android creada:
   - Click en **"Apps"** → **"Add app"**
   - Selecciona **"Android"**
   - Ingresa el nombre: **"Dólar Argentina"**
   - Ingresa el **Package Name** de tu app (debería ser algo como `com.tudominio.dolar_argentina_app`)
   - Click en **"Add app"**

### 2. Obtener el App ID de Android

1. En AdMob, ve a **"Apps"**
2. Selecciona tu app Android
3. En la sección **"App settings"**, copia el **App ID** (formato: `ca-app-pub-XXXXXXXXXX~XXXXXXXXXX`)
4. **Reemplaza** en `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="TU_APP_ID_AQUI"/>
   ```

### 3. Crear Ad Unit para Android

1. En AdMob, dentro de tu app Android, ve a **"Ad units"**
2. Click en **"Add ad unit"**
3. Selecciona **"Banner"**
4. Nombre sugerido: **"Home Banner"** o **"Large Banner"**
5. Selecciona el formato: **"Large Banner (320x100)"** (o "Banner" si no está disponible)
6. Click en **"Add ad unit"**
7. Copia el **Ad Unit ID** (formato: `ca-app-pub-XXXXXXXXXX/XXXXXXXXXX`)

### 4. Actualizar el Código con el Ad Unit ID Real

1. Abre `lib/features/home/widgets/ad_banner.dart`
2. En el método `_getAdUnitId()`, reemplaza el test ID de Android:
   ```dart
   if (Platform.isAndroid) {
     return 'TU_AD_UNIT_ID_ANDROID_AQUI'; // Reemplazar con tu Ad Unit ID real
   }
   ```

---

## Verificación Final

### Checklist antes de publicar:

- [ ] App ID de Android configurado en `AndroidManifest.xml`
- [ ] Ad Unit ID de Android configurado en `ad_banner.dart`
- [ ] App ID de iOS ya configurado (✅ ya está)
- [ ] Ad Unit ID de iOS ya configurado (✅ ya está)
- [ ] Probar con test ads primero (usar test IDs)
- [ ] Probar con ads reales antes de publicar

---

## Test IDs (Para Desarrollo)

### Android Test IDs:
- **App ID**: `ca-app-pub-3940256099942544~3347511713`
- **Banner Ad Unit**: `ca-app-pub-3940256099942544/6300978111`
- **Large Banner Ad Unit**: `ca-app-pub-3940256099942544/6300978111` (mismo que banner)

### iOS Test IDs:
- **App ID**: `ca-app-pub-3940256099942544~1458002511`
- **Banner Ad Unit**: `ca-app-pub-3940256099942544/2934735716`

**Nota**: Los test IDs funcionan en ambas plataformas durante desarrollo, pero NO generan ingresos.

---

## Formato del Banner

Actualmente la app usa **Large Banner (320x100)** que es más grande que el banner estándar (320x50) y genera más ingresos.

Si quieres cambiar el tamaño, modifica en `ad_banner.dart`:
- `AdSize.banner` → Banner estándar (320x50)
- `AdSize.largeBanner` → Large Banner (320x100) ← **Actual**
- `AdSize.mediumRectangle` → Medium Rectangle (300x250) - Más grande pero más intrusivo

---

## Troubleshooting

### El banner no aparece:
1. Verifica que el App ID esté correcto en `AndroidManifest.xml` (Android) o `Info.plist` (iOS)
2. Verifica que el Ad Unit ID esté correcto en `ad_banner.dart`
3. Revisa los logs de Flutter para ver errores específicos
4. Asegúrate de tener conexión a internet

### Error "Ad failed to load":
- Verifica que los IDs sean correctos
- Asegúrate de que la app esté publicada en Play Store/App Store (para ads reales)
- Durante desarrollo, usa test IDs

### Los ads no generan ingresos:
- Verifica que estés usando IDs reales, no test IDs
- Los ingresos pueden tardar 24-48 horas en aparecer en el dashboard
- Asegúrate de tener tráfico real (los test ads no generan ingresos)

---

## Próximos Pasos

1. **Para iOS**: Ya está listo ✅ - Solo publica la app
2. **Para Android**: 
   - Crea la app en AdMob
   - Obtén el App ID y Ad Unit ID reales
   - Reemplaza los test IDs en el código
   - Prueba antes de publicar

---

## Contacto y Recursos

- [Documentación oficial de AdMob](https://developers.google.com/admob/flutter/quick-start)
- [Google Mobile Ads SDK para Flutter](https://pub.dev/packages/google_mobile_ads)
- [AdMob Console](https://apps.admob.com/)

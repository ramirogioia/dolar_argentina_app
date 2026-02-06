r# Verificación de AdMob para TestFlight/Producción iOS

## Estado actual de la configuración

### iOS ✅
- **App ID**: `ca-app-pub-6119092953994163~6222015453` (configurado en `Info.plist`)
- **Ad Unit IDs (Banner)**:
  - Home: `ca-app-pub-6119092953994163/2879928015`
  - Calculadora: `ca-app-pub-6119092953994163/2715020872`
- **Modo**: Usa IDs reales en release (`kReleaseMode`), test en debug

### Android ⚠️
- **App ID**: `ca-app-pub-6119092953994163~6222015453` (mismo que iOS - puede estar OK)
- **Ad Unit ID (Banner)**: `ca-app-pub-6119092953994163/2879928015` (¡MISMO que iOS! - debería ser diferente)

---

## Checklist: Por qué los ads pueden no mostrarse en TestFlight

### 1. Verificar en AdMob Console

Ve a: https://apps.admob.com/

**Apps:**
- ¿Aparece "Dólar Argentina" (iOS) como app agregada? ✅
- ¿El App ID coincide con el de `Info.plist`? (`~6222015453`)
- ¿Estado de la app: "Ready" o "Preparada"?

**Ad Units (Unidades de anuncio):**
- ¿Existe un Ad Unit de tipo "Banner" para iOS?
- ¿El Ad Unit ID coincide con el del código? (`/2879928015`)
- ¿Estado del Ad Unit: "Ready" o "Active"?

### 2. Verificar app-ads.txt

Según `docs/ADMOB_APP_ADS_TXT.md`, necesitas:

1. **Subir `app-ads.txt` a tu dominio:**
   - Archivo: `app-ads.txt` (en raíz del proyecto)
   - Contenido: `google.com, pub-6119092953994163, DIRECT, f08c47fec0942fa0`
   - Debe estar en: `https://TU-DOMINIO/app-ads.txt`

2. **Configurar el dominio en AdMob:**
   - AdMob Console → App Settings → App Info → Store URL
   - iOS: `https://apps.apple.com/app/id6739063223`
   - Marketing URL: El dominio donde está `app-ads.txt`

3. **Esperar verificación:**
   - AdMob tarda hasta 24 horas en verificar el `app-ads.txt`
   - Mientras no esté verificado, el fill de anuncios puede ser muy bajo

### 3. Apps nuevas y Fill Rate

**IMPORTANTE**: Apps nuevas en AdMob suelen tener:
- **Fill rate bajo** (0-30%) los primeros días
- **Pocos anunciantes** hasta que AdMob recopila datos de la app
- **Prioridad baja** en subastas de anuncios

Esto es NORMAL y mejora con el tiempo (1-2 semanas) si:
- La app tiene usuarios activos
- Los usuarios interactúan con los anuncios
- No hay violaciones de políticas

### 4. TestFlight específicamente

En TestFlight los anuncios pueden:
- Tener fill rate aún más bajo que en producción
- Tardar más en cargar
- No mostrar ciertos tipos de anuncios

**Esto es esperado** porque TestFlight tiene menos usuarios que producción.

### 5. Configuración regional y targeting

En AdMob Console, verifica:
- **Targeting**: ¿Está habilitado para Argentina/LATAM?
- **Categorías**: ¿La app está categorizada correctamente?
- **Mediation**: ¿Tenés mediation habilitado con otras redes?

---

## Qué esperar en TestFlight

### Escenario normal:
1. Primera instalación desde TestFlight
2. Abrir la app
3. El banner dice "Cargando anuncio..." durante 12s
4. Si no hay fill:
   - Muestra "Anuncio no disponible"
   - **Esto es NORMAL en TestFlight y apps nuevas**
5. Recargar la app varias veces puede eventualmente mostrar un ad

### Si NUNCA muestra anuncios:
1. Revisar logs en Xcode:
   - Conectar el iPhone por cable
   - Xcode → Window → Devices and Simulators
   - Seleccionar el dispositivo → Ver logs
   - Buscar "AdMob" o "GAD" en los logs
   - Errores comunes:
     - "Invalid ad unit ID" → El ID no existe en AdMob o es de otra app
     - "No fill" → Normal, especialmente en apps nuevas
     - "App ID mismatch" → El App ID del código no coincide con AdMob

2. Verificar en la consola de AdMob:
   - AdMob Console → Apps → Tu app → Ad Units
   - Click en el Ad Unit → "View in Reporting"
   - Si ves requests pero 0 impressions → No fill (normal)
   - Si ves 0 requests → El código no está pidiendo ads (problema de configuración)

---

## Fix para Android

**CREAR AD UNIT SEPARADO PARA ANDROID:**

1. Ve a AdMob Console → Apps → (Selecciona tu app Android O crea una si no existe)
2. Ad Units → Add Ad Unit → Banner
3. Nombre: "Banner Android" (o similar)
4. Copiar el nuevo Ad Unit ID (será algo como `ca-app-pub-XXXX/YYYY-diferente`)
5. Reemplazar en `lib/features/home/widgets/ad_banner.dart`:

```dart
const realAndroid = 'ca-app-pub-6119092953994163/[NUEVO-AD-UNIT-ID-ANDROID]';
```

NO uses el mismo Ad Unit ID para Android e iOS - cada plataforma debe tener el suyo.

---

## Resumen para TestFlight iOS

**Si después del build los ads no se muestran en TestFlight:**

1. **NO te preocupes si muestra "Anuncio no disponible"** - es común en:
   - Apps nuevas sin historial
   - TestFlight (pocos usuarios)
   - App-ads.txt aún no verificado

2. **Espera unos días después del release a producción** para que:
   - AdMob verifique el app-ads.txt
   - La app acumule usuarios/impresiones
   - El fill rate mejore naturalmente

3. **Verifica los logs en Xcode** para confirmar que no haya errores de configuración.

**Lo importante es que el código esté bien** (y lo está). El resto es cuestión de tiempo y que AdMob procese la app.

# ✅ CHECKLIST PARA TESTFLIGHT - NOTIFICACIONES iOS

## 📋 ANTES DE HACER ARCHIVE (Verificar en Xcode)

### 1. **Abrir el proyecto**
```bash
cd ios
open Runner.xcworkspace  # ⚠️ IMPORTANTE: .xcworkspace, NO .xcodeproj
```

### 2. **Verificar Signing & Capabilities**
En Xcode → Target Runner → Signing & Capabilities:

- [ ] ✅ **Push Notifications** capability está añadida
- [ ] ✅ **Background Modes** → `☑️ Remote notifications` está marcado
- [ ] ✅ **Team** está seleccionado correctamente
- [ ] ✅ **Provisioning Profile** está configurado (puede ser Automatic)
- [ ] ✅ **No hay errores rojos** en la sección de Signing

### 3. **Verificar Bundle ID**
En Xcode → Target Runner → General:

- [ ] ✅ **Bundle Identifier**: `com.rgioia.dolarargentina`

### 4. **Verificar Info.plist**
Confirmar que existe (ya está configurado):

- [ ] ✅ `ios/Runner/Info.plist` tiene `UIBackgroundModes` con `remote-notification`
- [ ] ✅ `ios/Runner/GoogleService-Info.plist` existe y tiene tu proyecto Firebase

### 5. **Verificar Runner.entitlements**
Confirmar (ya está configurado):

- [ ] ✅ `ios/Runner/Runner.entitlements` tiene `aps-environment` = `production`

### 6. **Verificar en Apple Developer Portal**
1. Ve a: https://developer.apple.com/account/resources/identifiers/list
2. Busca: `com.rgioia.dolarargentina`
3. Click en él
4. Verifica:
   - [ ] ✅ **Push Notifications** está Enabled (checkbox verde)
   - [ ] ✅ Si no está enabled, marcarlo y hacer **Save**

### 7. **Verificar en Firebase Console**
1. Ve a: https://console.firebase.google.com/
2. Proyecto: **dolar-argentina-c7939**
3. ⚙️ **Configuración del proyecto → Cloud Messaging**
4. Scroll a **"Apple app configuration"**
5. Verifica:
   - [ ] ✅ APNs Authentication Key uploaded
   - [ ] ✅ Key ID: `B69DL59F44`
   - [ ] ✅ Team ID: `93QAZPHZ99`

---

## 📦 HACER ARCHIVE

### 1. **Limpiar build anterior**
En Xcode:
- **Product → Clean Build Folder** (⇧⌘K)

O en terminal:
```bash
cd ios
rm -rf Pods Podfile.lock build DerivedData
pod install
cd ..
flutter clean
flutter pub get
```

### 2. **Seleccionar dispositivo**
En Xcode:
- Arriba, junto al botón de Run, selecciona: **Any iOS Device (arm64)**

### 3. **Hacer Archive**
En Xcode:
- **Product → Archive**
- Espera a que compile (puede tardar 5-10 minutos)

### 4. **Distribuir a TestFlight**
1. Cuando termine, se abre la ventana de Organizer
2. Click en **Distribute App**
3. Selecciona **App Store Connect**
4. Click **Upload**
5. Sigue el wizard (deja las opciones por defecto)
6. Espera a que suba (puede tardar 10-20 minutos)

---

## 🧪 DESPUÉS DE INSTALAR DESDE TESTFLIGHT

### 1. **Instalar en un iPhone real**
- Abre **TestFlight** en tu iPhone
- Instala la versión nueva
- ⚠️ **IMPORTANTE**: Acepta los permisos de notificaciones cuando te lo pida

### 2. **Ir a Settings en la app**
1. Abre la app **Dólar Argentina**
2. Ve al menú (icono de hamburguesa o settings)
3. Busca la sección **"🔧 Para Desarrolladores"** (puede estar colapsada)
4. Expándela

### 3. **Verificar el Token FCM**
En la sección de desarrolladores, deberías ver:

✅ **SI FUNCIONA:**
```
✅ Token FCM disponible
[Un texto largo con el token]

[Botón: Copiar Token]
[Botón: Suscribirse al topic]
[Botón: Ejecutar Diagnóstico Completo]
```

❌ **SI NO FUNCIONA:**
```
❌ Token FCM no disponible
[Botón: Reinicializar FCM]
```

### 4. **Ejecutar Diagnóstico Completo**
1. Click en **"Ejecutar Diagnóstico Completo"**
2. Verás un mensaje: "🔍 Revisa los logs de la consola"
3. **Conecta el iPhone a tu Mac**
4. Abre **Console.app** (aplicación de macOS)
5. Selecciona tu iPhone en la barra lateral
6. Busca mensajes de tu app (filtra por "Dolar" o "FCM")

**Logs esperados (todo bien):**
```
✅ Firebase inicializado correctamente desde Flutter
🔥 Inicializando FCM inmediatamente para capturar APNs token...
📱 iOS APNs token registrado y pasado a Firebase Messaging
✅ FCM inicializado correctamente
1️⃣ Estado de inicialización: ✅ Inicializado
2️⃣ Permisos: AuthorizationStatus.authorized
3️⃣ Token FCM: ✅ Disponible (152 caracteres)
4️⃣ Suscripción al topic "all_users": Verificando...
   ✅ Suscripción al topic verificada
```

### 5. **Copiar el Token y probarlo**
1. En la app, click **"Copiar Token"**
2. Pégalo en un lugar seguro (Notes, WhatsApp a ti mismo, etc.)
3. Ve a **Firebase Console → Messaging**
4. Click **"Send test message"**
5. Pega el token
6. Click **"Test"**
7. **Deberías recibir la notificación en tu iPhone** 🎉

### 6. **Probar con tu backend**
```bash
python enviar_cierre.py
```

**Si todo está bien configurado, la notificación debería llegar a tu iPhone.**

---

## 🔍 TROUBLESHOOTING DESDE TESTFLIGHT

### ❌ Problema: "Token FCM no disponible"

**Posibles causas:**
1. **No aceptaste los permisos de notificaciones**
   - Solución: Ve a iOS Settings → Dólar Argentina → Notificaciones → Activar
   - Luego en la app: Settings → Click "Reinicializar FCM"

2. **Firebase no se inicializó correctamente**
   - Verifica que `GoogleService-Info.plist` esté en el bundle
   - Conecta el iPhone a Mac y revisa logs en Console.app

3. **APNs token no llegó a Firebase**
   - Verifica en Console.app si ves: "📱 iOS APNs token registrado..."
   - Si NO aparece, el problema está en los capabilities de Xcode

### ❌ Problema: Token FCM disponible pero notificaciones no llegan

**Posibles causas:**
1. **No estás suscrito al topic "all_users"**
   - Solución: En Settings → Click "Suscribirse al topic"
   - Verifica que salga un mensaje de éxito

2. **APNs Key en Firebase está mal configurado**
   - Verifica Firebase Console → Cloud Messaging → Apple app configuration
   - Debe mostrar el APNs Key correctamente

3. **Provisioning profile no soporta Push Notifications**
   - Ve a Apple Developer Portal
   - Elimina los provisioning profiles viejos de esta app
   - Vuelve a hacer Archive (Xcode regenerará el profile automáticamente)

### ❌ Problema: Notificación llega pero no hace sonido/vibración

**Causa:** El iPhone está en modo silencio o las notificaciones están silenciadas.

**Solución:**
- iOS Settings → Dólar Argentina → Notificaciones
- Verifica que "Sonidos" esté activado

---

## 📱 CÓMO VER LOGS EN TESTFLIGHT (sin Xcode)

### Opción 1: Console.app (Mac)
1. Conecta iPhone a Mac
2. Abre **Console.app**
3. Selecciona tu iPhone
4. Filtra por: `process:Runner` o busca "Dolar"

### Opción 2: Desde el iPhone (iOS Logs)
1. iPhone → **Settings → Privacy & Security → Analytics & Improvements**
2. **Analytics Data**
3. Busca logs de la app (pueden tardar horas en aparecer)
4. **NO es ideal para debug en tiempo real**

### Opción 3: Usar la herramienta de diagnóstico en la app
1. Abre la app
2. Ve a Settings → Sección "Para Desarrolladores"
3. Click **"Ejecutar Diagnóstico Completo"**
4. Anota lo que ves en el token FCM
5. Si ves "✅ Token FCM disponible", copia el token y prueba enviando una notificación de prueba desde Firebase Console

---

## 🎯 CHECKLIST FINAL ANTES DE SUBIR A TESTFLIGHT

- [ ] ✅ Verificado Xcode: Push Notifications capability
- [ ] ✅ Verificado Xcode: Background Modes → Remote notifications
- [ ] ✅ Verificado Apple Developer Portal: Push Notifications enabled
- [ ] ✅ Verificado Firebase Console: APNs Key subido
- [ ] ✅ Runner.entitlements tiene `production` (para TestFlight)
- [ ] ✅ Hecho Clean Build Folder
- [ ] ✅ Hecho Archive con "Any iOS Device (arm64)"
- [ ] ✅ Subido a App Store Connect

---

## ✅ CHECKLIST DESPUÉS DE INSTALAR DESDE TESTFLIGHT

- [ ] ✅ Instalado en iPhone real desde TestFlight
- [ ] ✅ Aceptado permisos de notificaciones
- [ ] ✅ Abierto Settings → Sección "Para Desarrolladores"
- [ ] ✅ Verificado que Token FCM está disponible
- [ ] ✅ Copiado el token FCM
- [ ] ✅ Probado envío desde Firebase Console con el token
- [ ] ✅ Recibida notificación de prueba ✅
- [ ] ✅ Ejecutado diagnóstico completo
- [ ] ✅ Probado script: `python enviar_cierre.py`
- [ ] ✅ Recibida notificación desde el backend ✅

---

## 🆘 SI DESPUÉS DE TODO NO FUNCIONA

1. **Captura screenshots de:**
   - Settings en la app → Sección "Para Desarrolladores" (mostrando token o error)
   - Xcode → Signing & Capabilities
   - Apple Developer Portal → Bundle ID → Push Notifications
   - Firebase Console → Cloud Messaging → Apple app configuration

2. **Comparte los logs:**
   - Conecta iPhone a Mac
   - Abre Console.app
   - Reproduce el problema
   - Guarda los logs (File → Save Selection)

3. **Verifica versión:**
   - ¿Es la versión nueva que acabas de subir?
   - A veces TestFlight tarda en propagar los cambios (10-15 minutos)

---

## 📝 NOTAS IMPORTANTES

- ⚠️ **TestFlight usa el environment `production`** para APNs
- ⚠️ **El simulador iOS NO soporta notificaciones push** (solo device real)
- ⚠️ **Firebase puede tardar 5-10 minutos en propagar cambios** después de hacer cambios en la console
- ✅ **Tu APNs Key ya está configurado correctamente** (Key ID: B69DL59F44)
- ✅ **Los cambios de código ya están aplicados** (FCM se inicializa inmediatamente)


# 📱 Configuración de Push Notifications para iOS

## ⚠️ PROBLEMA COMÚN: Notificaciones no llegan en iOS

Este documento explica cómo verificar y solucionar problemas con notificaciones push en iOS.

---

## ✅ VERIFICACIÓN COMPLETA (Sigue estos pasos EN ORDEN)

### 1. **Abrir el proyecto en Xcode**
```bash
cd ios
open Runner.xcworkspace  # ⚠️ IMPORTANTE: Abrir el .xcworkspace, NO el .xcodeproj
```

---

### 2. **Verificar Signing & Capabilities**

1. En Xcode, selecciona el proyecto **Runner** en el navegador izquierdo
2. Selecciona el target **Runner** (debajo del proyecto)
3. Ve a la pestaña **"Signing & Capabilities"**

**Debes ver estas capabilities:**

#### ✅ **Push Notifications**
- Si NO aparece, click en **"+ Capability"** arriba a la izquierda
- Busca **"Push Notifications"** y añádela
- Debe aparecer un checkbox: `☑️ Push Notifications`

#### ✅ **Background Modes**
- Si NO aparece, añádela con **"+ Capability"**
- Marca el checkbox: `☑️ Remote notifications`
- Otros checkboxes pueden estar desmarcados

---

### 3. **Verificar Provisioning Profile**

En la misma pestaña **"Signing & Capabilities"**:

1. Busca la sección **"Signing (Debug)"** o **"Signing (Release)"**
2. Verifica que:
   - ✅ **Team**: Tu equipo de desarrollo de Apple
   - ✅ **Provisioning Profile**: Debe decir "Automatic" o el nombre de tu profile
   - ⚠️ Si hay errores en rojo, resuélvelos (puede que necesites regenerar el provisioning profile)

**Si ves errores como "Provisioning profile doesn't support Push Notifications":**
1. Ve a https://developer.apple.com/account/resources/profiles/list
2. Elimina los provisioning profiles viejos de esta app
3. En Xcode, ve a **Preferences → Accounts → Download Manual Profiles**
4. O simplemente deja que Xcode lo maneje automáticamente

---

### 4. **Verificar Bundle ID**

1. En Xcode, ve a **General** tab
2. Verifica que el **Bundle Identifier** sea: `com.rgioia.dolarargentina`

---

### 5. **Verificar en Apple Developer Portal**

1. Ve a https://developer.apple.com/account/resources/identifiers/list
2. Busca tu Bundle ID: `com.rgioia.dolarargentina`
3. Click en él
4. Verifica que **"Push Notifications"** esté:
   - ✅ Enabled
   - Con un checkbox verde

**Si NO está enabled:**
1. Marca el checkbox de **"Push Notifications"**
2. Click **"Save"**
3. Vuelve a Xcode y limpia/rebuildeа la app

---

### 6. **Limpiar y Recompilar**

Después de hacer cambios, SIEMPRE limpia:

```bash
# En terminal
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get

# Luego compila en Release mode (CRÍTICO para testear notificaciones)
flutter build ios --release
```

O en Xcode:
1. **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)

---

### 7. **Probar en Dispositivo REAL**

⚠️ **IMPORTANTE**: Las notificaciones push **NO funcionan en simuladores iOS**.

1. Conecta un iPhone/iPad físico
2. Instala la app en **Release mode** o **Profile mode**
3. Acepta los permisos de notificaciones cuando te lo pida
4. Envía una notificación de prueba desde tu backend

---

## 🔍 **VERIFICAR LOGS EN XCODE**

Después de instalar la app, busca estos logs en la consola de Xcode:

### ✅ **Logs correctos (todo funcionando):**
```
✅ Firebase inicializado correctamente desde Flutter
🔥 Inicializando FCM inmediatamente para capturar APNs token...
📱 Inicializando FCM (notificaciones habilitadas)
📱 iOS APNs token registrado y pasado a Firebase Messaging
   Token (primeros 20 chars): a1b2c3d4e5f6g7h8i9j0...
✅ FCM inicializado correctamente
3️⃣ Token FCM: ✅ Disponible (152 caracteres)
4️⃣ Suscripción al topic "all_users": Verificando...
   ✅ Suscripción al topic verificada
```

### ❌ **Logs problemáticos:**

**Si ves:**
```
❌ CRÍTICO: Error al registrar para notificaciones remotas
```
→ **Problema**: No tienes Push Notifications capability o el provisioning profile no lo soporta.
→ **Solución**: Sigue los pasos 2, 3 y 5 de arriba.

**Si ves:**
```
3️⃣ Token FCM: ❌ No disponible
```
→ **Problema**: Firebase no pudo obtener el token FCM.
→ **Causas posibles**:
  - APNs token no llegó a Firebase
  - `GoogleService-Info.plist` no está correctamente configurado
  - Problema con Firebase Console (APNs Key no subido o incorrecto)

**Si ves:**
```
⚠️ No se pudo verificar suscripción: [some error]
```
→ Puede ser normal si estás offline o Google Play Services (Android) no está disponible.
→ En iOS, verifica que tengas conexión a internet.

---

## 🔥 **VERIFICAR FIREBASE CONSOLE**

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto: **dolar-argentina-c7939**
3. Ve a **⚙️ Configuración del proyecto → Cloud Messaging**
4. Desplázate a **"Apple app configuration"**
5. Debe mostrar:
   ```
   ✅ APNs Authentication Key uploaded
   Key ID: B69DL59F44
   Team ID: 93QAZPHZ99
   ```

**Si NO aparece el APNs Key:**
→ Ve al README principal para instrucciones de cómo subir el APNs Key (.p8)

---

## 🧪 **PROBAR NOTIFICACIONES**

### Desde Firebase Console (Prueba rápida):
1. Ve a **Messaging** en el menú izquierdo
2. Click en **"Create your first campaign"** o **"New notification"**
3. Título: "Test"
4. Texto: "Probando notificaciones iOS"
5. Click **"Send test message"**
6. Pega tu FCM token (lo puedes ver en los logs de Xcode)
7. Click **"Test"**

### Desde tu backend (Python script):
```bash
python enviar_cierre.py
```

---

## 📋 **CHECKLIST FINAL**

Antes de dar por perdido, verifica:

- [ ] ¿Abriste `Runner.xcworkspace` (no `.xcodeproj`)?
- [ ] ¿Tienes **Push Notifications** capability en Xcode?
- [ ] ¿Tienes **Background Modes → Remote notifications** habilitado?
- [ ] ¿Tu provisioning profile soporta push notifications?
- [ ] ¿El Bundle ID en Xcode coincide con el de Apple Developer?
- [ ] ¿Push Notifications está habilitado en Apple Developer Portal?
- [ ] ¿Subiste el APNs Key (.p8) a Firebase Console?
- [ ] ¿Estás probando en un dispositivo REAL (no simulador)?
- [ ] ¿Compilaste en Release/Profile mode (no Debug)?
- [ ] ¿Aceptaste los permisos de notificaciones cuando te lo pidió?
- [ ] ¿Ves el log "📱 iOS APNs token registrado..." en Xcode?
- [ ] ¿Ves el log "✅ Suscripción al topic verificada" en Xcode?

---

## 🆘 **SI NADA FUNCIONA**

1. **Elimina la app del dispositivo**
2. **En Xcode: Product → Clean Build Folder (⇧⌘K)**
3. **Elimina carpetas de caché:**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock build DerivedData
   pod install
   cd ..
   flutter clean
   flutter pub get
   ```
4. **Recompila en Release:**
   ```bash
   flutter build ios --release
   ```
5. **Instala desde Xcode en un dispositivo real**
6. **Verifica TODOS los logs en la consola de Xcode**
7. **Espera 5-10 minutos** (Firebase puede tardar en propagar el APNs token)
8. **Envía una notificación de prueba**

---

## 📚 **RECURSOS ÚTILES**

- [Firebase iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Apple Push Notifications](https://developer.apple.com/notifications/)
- [APNs Key Setup](https://firebase.google.com/docs/cloud-messaging/ios/client#upload_your_apns_authentication_key)


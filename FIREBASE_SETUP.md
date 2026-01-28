# Configuración de Firebase Cloud Messaging (FCM)

Este documento explica cómo configurar Firebase Cloud Messaging para recibir notificaciones push del backend.

## ✅ Implementación Completada

La integración de FCM ya está implementada en el código:
- ✅ Dependencias agregadas (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`)
- ✅ Servicio FCM creado (`lib/services/fcm_service.dart`)
- ✅ Integración en `main.dart`
- ✅ Manejo de notificaciones en foreground, background y cuando la app está cerrada
- ✅ Navegación automática al tocar notificaciones

## 📋 Pasos para Configurar Firebase

### 1. Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o selecciona el existente `dolar-argentina-c7939`
3. Asegúrate de que Cloud Messaging esté habilitado

### 2. Configurar Android

#### 2.1. Agregar App Android

1. En Firebase Console, ve a **Project Settings** → **Your apps**
2. Haz clic en **Add app** → **Android**
3. Ingresa el **Package name**: `com.dolarargentina.dolar_argentina_app`
4. Descarga el archivo `google-services.json`
5. Coloca `google-services.json` en `android/app/`

#### 2.2. Verificar Configuración

El plugin de Google Services ya está configurado en:
- `android/build.gradle.kts` (classpath)
- `android/app/build.gradle.kts` (plugin)

### 3. Configurar iOS

#### 3.1. Agregar App iOS

1. En Firebase Console, ve a **Project Settings** → **Your apps**
2. Haz clic en **Add app** → **iOS**
3. Ingresa el **Bundle ID**: (debe coincidir con el de Xcode)
4. Descarga el archivo `GoogleService-Info.plist`
5. Coloca `GoogleService-Info.plist` en `ios/Runner/`

#### 3.2. Configurar Capabilities en Xcode

1. Abre `ios/Runner.xcworkspace` en Xcode
2. Selecciona el target **Runner**
3. Ve a **Signing & Capabilities**
4. Agrega **Push Notifications**
5. Agrega **Background Modes** y habilita:
   - ✅ Remote notifications

#### 3.3. Configurar APNs (Apple Push Notification Service)

Para producción, necesitarás:
- Un certificado APNs o una clave APNs desde Apple Developer
- Subir el certificado/clave a Firebase Console → **Project Settings** → **Cloud Messaging** → **Apple app configuration**

### 4. Verificar Permisos

#### Android (`android/app/src/main/AndroidManifest.xml`)

Los permisos necesarios ya están presentes:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

#### iOS (`ios/Runner/Info.plist`)

Los permisos se solicitan automáticamente en el código mediante `requestPermission()`.

## 🧪 Testing

### Verificar que la App se Suscribe Correctamente

1. Ejecuta la app
2. Revisa los logs en la consola:
   ```
   ✅ Suscrito al topic: all_users
   📱 Token FCM: [token aquí]
   ✅ FCM Service inicializado correctamente
   ```

### Enviar Notificación de Prueba

El backend tiene un script `test_push_notification.py` para enviar notificaciones de prueba. Una vez que la app esté corriendo:

1. Ejecuta el script desde el backend
2. Verifica que la notificación llegue a la app
3. Toca la notificación y verifica que navegue a home

### Estados de la App a Probar

- ✅ **Foreground**: La app muestra una notificación local cuando llega un push
- ✅ **Background**: La app muestra la notificación en el sistema, al tocarla navega a home
- ✅ **Cerrada**: La app se abre y navega a home cuando se toca la notificación

## 📱 Topic de Suscripción

La app se suscribe automáticamente al topic: **`all_users`**

Este topic es el que usa el backend para enviar notificaciones a todos los usuarios.

## 🔍 Debugging

### Ver Logs

Los logs importantes incluyen:
- `✅ Suscrito al topic: all_users` - Suscripción exitosa
- `📨 Notificación recibida en foreground:` - Notificación en foreground
- `📨 Usuario tocó notificación` - Usuario interactuó con la notificación
- `🧭 Navegando según tipo:` - Navegación según tipo de notificación

### Problemas Comunes

#### "Error al inicializar Firebase"
- Verifica que `google-services.json` (Android) o `GoogleService-Info.plist` (iOS) estén presentes
- Verifica que el package name / bundle ID coincida con Firebase Console

#### "Permisos de notificaciones denegados"
- En iOS, los permisos se solicitan automáticamente la primera vez
- Si el usuario denegó permisos, debe ir a Configuración del dispositivo para habilitarlos

#### "Notificaciones no llegan"
- Verifica que el topic sea exactamente `"all_users"` (minúsculas, guión bajo)
- Verifica que el backend esté enviando al topic correcto
- Revisa los logs del backend para errores de envío

#### "La navegación no funciona"
- Verifica que `navigatorKey` esté configurado en el router
- Revisa los logs para ver si hay errores de navegación

## 📚 Recursos

- [Firebase Cloud Messaging Flutter](https://firebase.flutter.dev/docs/messaging/overview)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Console](https://console.firebase.google.com/)

## ⚠️ Notas Importantes

1. **Archivos de configuración**: `google-services.json` y `GoogleService-Info.plist` contienen información sensible. NO los subas a repositorios públicos sin precaución.

2. **Permisos iOS**: En iOS, los permisos se solicitan la primera vez que se ejecuta la app. Si el usuario los deniega, debe habilitarlos manualmente desde Configuración.

3. **Topic exacto**: El topic debe ser exactamente `"all_users"` (sin espacios, minúsculas, guión bajo). Cualquier diferencia hará que las notificaciones no lleguen.

4. **Testing en iOS**: Para probar notificaciones push en iOS, necesitas un dispositivo físico (no funciona en simulador) o configurar APNs correctamente.

5. **Producción**: Antes de publicar, asegúrate de:
   - Usar los App IDs reales de Firebase (no los de test)
   - Configurar APNs para iOS
   - Probar en dispositivos reales


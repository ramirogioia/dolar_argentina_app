# Build Android AAB para Google Play Store

## ¿Qué hace falta?

1. **Keystore de release** (solo una vez) – para firmar el AAB.
2. **Archivo `key.properties`** (solo una vez) – con las rutas y contraseñas; no se sube al repo.
3. **Ejecutar el script** – genera el AAB firmado.

---

## 1. Crear el keystore (solo la primera vez)

En la carpeta del proyecto (o en `android/`):

```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Te va a pedir:
- Contraseña del keystore (guardala bien).
- Nombre, organización, etc. (pueden ser cualquiera para identificación).
- Contraseña de la key (puede ser la misma que la del keystore).

**Importante:** El archivo `upload-keystore.jks` y las contraseñas son **irreemplazables**. Si los perdés, no podés publicar actualizaciones de la misma app en Play Store. Guardalos en un lugar seguro (y no los subas al repo; ya están en `.gitignore`).

---

## 2. Crear `android/key.properties`

Creá el archivo `android/key.properties` con este contenido (reemplazando con tus valores):

```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DE_LA_KEY
keyAlias=upload
storeFile=../upload-keystore.jks
```

(La ruta `storeFile` es relativa a `android/app/`. Si creaste el keystore en `android/`, usá `../upload-keystore.jks`.)

**No subas `key.properties` ni el `.jks` al repositorio** (ya están en `.gitignore`).

---

## 3. Generar el AAB

Desde la raíz del proyecto:

```bash
./android/build_release_aab.sh
```

O directamente:

```bash
flutter build appbundle --release
```

El AAB queda en:

```
build/app/outputs/bundle/release/app-release.aab
```

---

## 4. Subir a Play Store

1. Entrá a [Google Play Console](https://play.google.com/console).
2. Elegí la app (o creá una nueva).
3. Producción, Prueba interna o Prueba cerrada → Crear nueva versión.
4. Subí `app-release.aab`.
5. Completá la ficha de la versión y enviá a revisión.

---

## Resumen

| Qué | Dónde |
|-----|--------|
| Keystore | `android/upload-keystore.jks` (o donde lo hayas creado) |
| Credenciales | `android/key.properties` (no commitear) |
| AAB generado | `build/app/outputs/bundle/release/app-release.aab` |
| Script | `./android/build_release_aab.sh` |

Si no existe `key.properties`, el script usa firma debug y el AAB se genera igual, pero **Play Store no acepta builds con firma debug para producción**. Para publicar hace falta el keystore de release y `key.properties` configurado.

---

## Checklist: Notificaciones y publicidad en release

Antes de subir el AAB, conviene verificar que en release todo esté bien para notificaciones y AdMob.

### Notificaciones ✅

- **AndroidManifest**: `POST_NOTIFICATIONS` declarado (Android 13+).  
- **FCM**: Icono por defecto configurado (`com.google.firebase.messaging.default_notification_icon`).  
- **Firebase**: `google-services.json` en `android/app/` (incluido en el build).  
- **Código**: En release se usa el mismo FCM (topic `all_users`); el permiso se pide con `requestNotificationsPermission()` en Android 13+.

No hace falta configurar nada más para notificaciones en el build release.

### Publicidad (AdMob) ✅ / ⚠️

- **App ID** en `AndroidManifest.xml`: `ca-app-pub-6119092953994163~3815613465` (app Android en AdMob).  
- **Modo release**: En release (`kReleaseMode`) se usan Ad Unit IDs reales; en debug, IDs de prueba.  
- **Banner home**: `ca-app-pub-6119092953994163/5181773243`.  
- **Banner calculadora**: `ca-app-pub-6119092953994163/7548189933`.

### Resumen

| Tema            | Estado en el proyecto |
|-----------------|------------------------|
| Permisos notis  | ✅ POST_NOTIFICATIONS en manifest |
| FCM / Firebase  | ✅ google-services.json + icono notificación |
| AdMob App ID    | ✅ En manifest |
| Ads en release  | ✅ kReleaseMode → IDs reales |
| Ad Unit Android | ⚠️ Mismo ID que iOS; cambiar si en AdMob tenés app Android con otro ID |

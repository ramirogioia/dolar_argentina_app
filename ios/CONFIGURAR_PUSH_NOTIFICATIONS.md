# Configurar Push Notifications en Xcode (SOLO UNA VEZ)

## El Problema

Las notificaciones push NO funcionan en iOS (TestFlight/App Store) porque la capability "Push Notifications" no está configurada en el proyecto de Xcode.

Aunque el código esté bien y Firebase tenga la clave APNs, si usas `signingStyle: automatic` (como en `ExportOptions.plist`), Xcode genera el provisioning profile **basándose en las capabilities del proyecto**. Sin la capability configurada → el provisioning profile no incluye Push Notifications → iOS rechaza las notificaciones.

## La Solución (5 minutos, solo una vez)

### Paso 1: Abrir el proyecto en Xcode

```bash
cd ios
open Runner.xcworkspace
```

### Paso 2: Configurar las Capabilities

1. En Xcode, click en **Runner** (el proyecto azul en el panel izquierdo, arriba del todo)
2. Selecciona el **target Runner** (debajo del proyecto, tiene un ícono de app)
3. Ve a la pestaña **"Signing & Capabilities"** (arriba)

### Paso 3: Añadir Push Notifications

1. Click en **"+ Capability"** (esquina superior izquierda de la pestaña)
2. Busca **"Push Notifications"** en el buscador
3. Click en **"Push Notifications"** para añadirla
4. Debe aparecer una nueva sección con un checkbox: ☑️ **Push Notifications**

### Paso 4: Añadir Background Modes

1. Click otra vez en **"+ Capability"**
2. Busca **"Background Modes"**
3. Click para añadirla
4. En la sección que aparece, marca el checkbox: ☑️ **Remote notifications**

### Paso 5: Guardar y cerrar

- Xcode guarda automáticamente (verás que el archivo `project.pbxproj` se modifica)
- **Cierra Xcode** (ya no lo necesitas)

### Paso 6: Hacer el build normalmente

```bash
cd ios
./build_archive.sh
```

Ahora el provisioning profile automático **incluirá Push Notifications**, y las notificaciones funcionarán en TestFlight/App Store.

## Verificar si ya está configurado

Para verificar sin abrir Xcode:

```bash
cd ios
grep -A 5 "com.apple.Push" Runner.xcodeproj/project.pbxproj
```

Si ves algo como:

```
com.apple.Push = {
    enabled = 1;
};
```

→ **YA ESTÁ BIEN** ✅

Si NO aparece nada → **DEBES configurarlo en Xcode** ⚠️

## Por qué es necesario

El flujo de capabilities en iOS:

1. **Entitlements file** (`Runner.entitlements`): declara lo que la app *quiere*
   - Ya tienes: `aps-environment = production` ✅

2. **Xcode project capabilities**: declara qué funcionalidades usa la app
   - **FALTA**: Push Notifications capability ❌

3. **Provisioning Profile**: declara lo que la app *puede hacer* (generado por Apple/Xcode)
   - Con `automatic signing`: se genera basándose en las capabilities del paso 2
   - Sin la capability → el profile no incluye Push → iOS rechaza notificaciones ❌

Configurar la capability en Xcode (paso 2) hace que el provisioning profile (paso 3) incluya Push Notifications.

## Después de configurar

- **La primera vez**: Abre Xcode y configura (arriba)
- **Siempre después**: Solo ejecuta `./build_archive.sh`
- El provisioning profile automático ya incluirá Push Notifications
- Las notificaciones funcionarán en TestFlight y App Store ✅

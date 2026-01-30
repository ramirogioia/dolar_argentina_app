# Simular tablet en Android Studio para capturas (dimensiones tipo iPad)

Así creás un emulador de **tablet Android** con tamaño de pantalla parecido al iPad 12.9"/13" y sacás capturas que después podés redimensionar a las medidas que pide App Store para iPad.

**Dimensiones que pide App Store para iPad 12.9"/13":**
- 2064 × 2752 px o 2048 × 2732 px (portrait)
- 2752 × 2064 px o 2732 × 2048 px (landscape)

---

## 1. Abrir el Device Manager

1. Abrí **Android Studio**.
2. **Tools → Device Manager** (o el ícono de teléfono/tablet en la barra de herramientas).
3. Clic en **Create Device** (o "Create Virtual Device").

---

## 2. Elegir o crear el hardware (tablet)

### Opción A: Usar una tablet que ya existe

1. En la izquierda, elegí **Tablet**.
2. Elegí por ejemplo **Pixel Tablet** (2560×1600, 10.95") o **Medium Tablet** (2560×1600).
3. Clic en **Next**.

### Opción B: Crear un perfil con tamaño tipo iPad (recomendado)

1. En la izquierda, elegí **Tablet**.
2. Clic en **New Hardware Profile** (abajo a la izquierda).
3. Completá:
   - **Name:** p. ej. `Tablet iPad 12.9`
   - **Screen size:** 12.9" (diagonal).
   - **Resolution:** 2048 × 2732 px (portrait) o 2732 × 2048 (landscape).
   - **Density:** xxhdpi (420) o la que proponga.
4. **Finish**.
5. Seleccioná ese perfil en la lista y **Next**.

---

## 3. Imagen del sistema

1. Elegí una **System Image** (p. ej. **API 34** – Tiramisu o la más reciente con descarga).
2. Si dice "Download" al lado, descargala.
3. **Next**.

---

## 4. Configurar el AVD y terminar

1. Dejá el nombre del AVD (o cambialo, p. ej. "Tablet 12.9").
2. Opcional: **Show Advanced Settings** y revisá RAM, etc.
3. **Finish**.

---

## 5. Ejecutar la tablet y la app

1. En Device Manager, hacé clic en **Play** (▶) del emulador que creaste.
2. Esperá a que arranque la tablet.
3. En la terminal (en la carpeta del proyecto Flutter):
   ```bash
   flutter run
   ```
   O en Android Studio: **Run → Run 'app'** y elegí ese emulador.
4. La app se abre en la tablet.

---

## 6. Sacar las capturas

1. Con la app abierta en el emulador:
   - En la barra lateral del emulador, ícono de **cámara** (Take screenshot), o
   - Menú **...** (Extended controls) → **Snapshot / Screenshot**, o
   - En algunos: **Ctrl + S** (Windows/Linux) o **Cmd + S** (Mac).
2. Las capturas suelen guardarse en la carpeta que te indique el emulador (o en `~/Desktop` según la versión).
3. Cambiá entre **portrait** y **landscape** con el botón de rotar del emulador y repetí para las pantallas que necesites.

---

## 7. Redimensionar a las dimensiones de App Store (iPad)

Las capturas de Android no tendrán exactamente 2048×2732 o 2064×2752. Para dejarlas en una de las medidas que pide Apple:

**En Mac (terminal):**
```bash
# Portrait 2048 × 2732
sips -z 2732 2048 captura.png

# Portrait 2064 × 2752
sips -z 2752 2064 captura.png

# Landscape 2732 × 2048
sips -z 2048 2732 captura.png

# Landscape 2752 × 2064
sips -z 2064 2752 captura.png
```

Guardá las redimensionadas en una carpeta (p. ej. `store_screenshots_apple/ipad/`) y subilas en App Store Connect como capturas de iPad.

---

## Resumen

| Paso | Dónde |
|------|--------|
| Device Manager | Tools → Device Manager |
| Crear tablet | Create Device → Tablet (o New Hardware Profile 12.9", 2048×2732) |
| System Image | API 34 (o la última) |
| Ejecutar app | `flutter run` eligiendo ese emulador |
| Captura | Ícono cámara en emulador o Extended controls |
| Redimensionar | `sips -z alto ancho archivo.png` para 2048×2732, etc. |

**Nota:** Las capturas serán de la **interfaz Android** (barra de estado y navegación de Android). Para capturas 100 % de aspecto iOS/iPad hay que usar Xcode y el simulador de iPad. Esta guía sirve para tener composición y contenido de tablet y luego ajustar tamaño para App Store.

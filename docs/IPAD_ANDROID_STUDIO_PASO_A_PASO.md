# Paso a paso: tablet en Android Studio para capturas iPad 12.9"/13"

Dimensiones que pide App Store para iPad 12.9"/13":
- **Portrait:** 2064 × 2752 px o 2048 × 2732 px
- **Landscape:** 2752 × 2064 px o 2732 × 2048 px

---

## Paso 1: Abrir Device Manager

1. Abrí **Android Studio**.
2. Menú **Tools** → **Device Manager** (o el ícono de teléfono/tablet en la barra superior).
3. Clic en **Create Device** (botón que suele decir "Create Virtual Device" o tener un ícono +).

---

## Paso 2: Crear un perfil de hardware (tablet con tamaño iPad)

1. En la ventana **Select Hardware**, a la izquierda elegí la categoría **Tablet**.
2. Abajo a la izquierda, clic en **New Hardware Profile**.
3. En el formulario que se abre, completá exactamente:

   | Campo | Valor |
   |-------|--------|
   | **Name** | `Tablet iPad 13` (o el nombre que quieras) |
   | **Screen size** | `12.9` (pulgadas, diagonal) |
   | **Resolution** – Width | `2048` |
   | **Resolution** – Height | `2732` |
   | **Density** | Dejá el que proponga (ej. **xxhdpi** o **420**) |

4. Clic en **Finish**.
5. En la lista de dispositivos, **seleccioná** el perfil que acabás de crear (`Tablet iPad 13`).
6. Clic en **Next**.

*(Si preferís usar 2064×2752, en Resolution poné Width: 2064, Height: 2752. El resto igual.)*

---

## Paso 3: Elegir la imagen del sistema (Android)

1. En **System Image**, elegí una versión de Android (ej. **API 34** – "UpsideDownCake" o "Tiramisu").
2. Si al lado dice **Download**, hacé clic para descargarla y esperá a que termine.
3. Clic en **Next**.

---

## Paso 4: Confirmar el AVD y crear

1. Dejá el **AVD Name** (ej. `Tablet_iPad_13`) o cambialo si querés.
2. Opcional: **Show Advanced Settings** para ajustar RAM, etc.
3. Clic en **Finish**.

El emulador queda creado en la lista del Device Manager.

---

## Paso 5: Iniciar la tablet

1. En **Device Manager**, buscá el emulador que creaste (ej. `Tablet_iPad_13`).
2. Clic en el botón **Play** (▶) al lado del nombre.
3. Esperá a que arranque Android en la tablet (puede tardar un poco la primera vez).

---

## Paso 6: Abrir tu app en la tablet

1. En la carpeta del proyecto Flutter, en la terminal:
   ```bash
   flutter run
   ```
2. Cuando pregunte el dispositivo, elegí el emulador de la tablet (ej. `Tablet_iPad_13`).
   
   O desde Android Studio: **Run** → **Run 'app'** y en el selector de dispositivos elegí la tablet.

La app **Dólar ARG** se abre en la tablet.

---

## Paso 7: Sacar las capturas

1. Con la app abierta en el emulador:
   - En la **barra lateral derecha** del emulador, clic en el ícono de **cámara** (Take screenshot), **o**
   - Clic en los **tres puntos (...)** → **Snapshot** / **Screenshot**.
2. La captura se guarda (suele ser en el escritorio o en la carpeta que indique el emulador).
3. Para **portrait**: si la tablet está en horizontal, rotala con el botón de **rotar** del emulador hasta que quede vertical y sacá la captura.
4. Para **landscape**: dejá la tablet en horizontal y sacá la captura.
5. Repetí para cada pantalla que necesites (Home, Ajustes, etc.) hasta tener hasta **10 capturas** y hasta **3 vistas previas** si las usás.

---

## Paso 8: Redimensionar a las dimensiones exactas de App Store (opcional)

Si las capturas no tienen exactamente 2048×2732 o 2064×2752, en **Mac** podés redimensionarlas en la terminal:

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

Guardá las imágenes finales en una carpeta (ej. `store_screenshots_apple/ipad_13/`) y subilas en App Store Connect en la sección **iPad – Pantalla de 13"**.

---

## Resumen rápido

| Paso | Acción |
|------|--------|
| 1 | Tools → Device Manager → Create Device |
| 2 | Tablet → New Hardware Profile → 12.9", 2048×2732 → Finish → Next |
| 3 | System Image API 34 (Download si hace falta) → Next |
| 4 | Finish |
| 5 | Play ▶ en el emulador |
| 6 | `flutter run` y elegir la tablet |
| 7 | Ícono cámara en el emulador para cada captura (portrait/landscape) |
| 8 | Redimensionar con `sips` si hace falta y subir a App Store Connect |

**Nota:** Las capturas tendrán la interfaz de **Android** (barras del sistema Android). Para capturas con aspecto 100 % iPad hay que usar Xcode y el simulador de iPad. Este método sirve para tener el contenido y la composición de tablet y luego cumplir con las dimensiones que pide Apple.

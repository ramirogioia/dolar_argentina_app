# Capturas de iPad para App Store

Android Studio **no** simula iPad ni iOS. Para capturas de tablet Apple tenés que usar **Xcode** (Mac).

## Dimensiones que acepta App Store para iPad 12.9" / 13"

- **2064 × 2752 px** (portrait)
- **2752 × 2064 px** (landscape)
- **2048 × 2732 px** (portrait)
- **2732 × 2048 px** (landscape)

---

## 1. Abrir el proyecto en Xcode (Mac)

1. En la Mac, abrí el proyecto Flutter.
2. Entrá a la carpeta **`ios`** del proyecto.
3. Abrí **`Runner.xcworkspace`** con Xcode (doble clic o "Abrir con Xcode").
   - No uses `Runner.xcodeproj` si tenés CocoaPods; usá el `.xcworkspace`.

---

## 2. Correr la app en el simulador de iPad

1. En Xcode, arriba a la izquierda, en el selector de **scheme**, elegí **Runner**.
2. En el selector de **dispositivo** (al lado del scheme), hacé clic y elegí un iPad:
   - **iPad Pro 13-inch (M4)** (13")
   - **iPad Pro 12.9-inch (6th generation)** (12.9")
   - Cualquier iPad Pro 12.9" o 13" que aparezca en la lista.
3. Si no ves iPads en la lista:
   - Menú **Xcode → Settings** (o **Preferences**) → **Platforms** (o **Components** en versiones viejas).
   - Instalá **iOS** con una versión reciente.
   - Luego **Window → Devices and Simulators → Simulators** y verificá que exista un iPad Pro 12.9" o 13".
4. Pulsá **Run** (▶) o `Cmd + R`.
5. Esperá a que compile y se abra el simulador con la app en iPad.

---

## 3. Sacar las capturas en el simulador

1. Con la app abierta en el iPad en el simulador, elegí la orientación:
   - **Portrait:** menú del simulador **Device → Rotate Left** (o **Rotate Right**) hasta que quede vertical.
   - **Landscape:** igual hasta que quede horizontal.
2. Captura de pantalla:
   - **`Cmd + S`** guarda la captura en el **Escritorio** (por defecto).
   - O **File → Save Screen** en el menú del simulador.
3. Repetí para las pantallas que necesites (home, ajustes, etc.) y para portrait/landscape según lo que pida App Store.

---

## 4. Redimensionar a las dimensiones exactas (si hace falta)

Las capturas del simulador pueden no coincidir exactamente con 2064×2752 o 2048×2732. Si App Store las rechaza por tamaño:

- **Portrait:** redimensionar a **2064 × 2752** o **2048 × 2732**.
- **Landscape:** redimensionar a **2752 × 2064** o **2732 × 2048**.

En Mac podés usar **Preview** (abrir imagen → Herramientas → Ajustar tamaño) o en terminal:

```bash
# Ejemplo: dejar una imagen en 2064×2752 (portrait)
sips -z 2752 2064 ruta/a/captura.png
```

Para 2752×2064 (landscape):

```bash
sips -z 2064 2752 ruta/a/captura.png
```

---

## Resumen

| Qué necesitás        | Dónde        |
|----------------------|-------------|
| Simular iPad / iOS   | **Xcode** (Mac), no Android Studio |
| Capturas iPad 12.9"/13" | Simulador de iPad en Xcode → `Cmd + S` |
| Dimensiones App Store | 2064×2752, 2752×2064, 2048×2732, 2732×2048 |

Android Studio solo sirve para emuladores **Android** (teléfonos y tablets Android). Para vistas previa y capturas de **iPad** en App Store Connect hace falta Xcode y el simulador de iOS.

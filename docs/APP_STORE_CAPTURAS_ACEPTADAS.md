# Cómo hacer que App Store acepte las capturas (como Impostor)

La captura de **Impostor** que te aceptaron en iOS tiene algo que las de Dólar ARG no: **se ve la barra de estado y el notch** (el “hueco” del dispositivo). Parece una captura de pantalla real de un teléfono.

Las de Dólar ARG se sacaron con **modo inmersivo** (sin barra de estado ni barra de navegación). Apple a veces rechaza capturas que no parecen de un dispositivo real.

---

## 1. Sacar las capturas CON barra de estado (como Impostor)

Para que se parezcan a la de Impostor que pasó:

1. **Desactivar temporalmente el modo inmersivo**  
   En el código, en `main.dart`, cambiá a:
   ```dart
   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
   ```
   (y en `splash_page.dart` también `SystemUiMode.edgeToEdge` si lo tenés en `immersiveSticky`).
2. **Compilá y ejecutá** la app en un emulador o dispositivo.
3. **Sacá las capturas** con la barra de estado (hora, batería, señal) y, en Android, la barra de navegación visibles.
4. Cuando termines de sacar las capturas para el Store, volvé a poner `SystemUiMode.immersiveSticky` si querés seguir con pantalla limpia.

Así las capturas “se ven” como de un teléfono real, como la de Impostor.

---

## 2. Usar el slot y las dimensiones correctas

- **iPhone 6.5"** → subir imágenes de **1242 × 2688 px** (las de `store_screenshots_apple/iphone_6_5/`).
- **iPhone 6.7"** → subir imágenes de **1284 × 2778 px** (las de `store_screenshots_apple/` raíz).

No mezcles: para el slot “iPhone 6.5”” solo 1242×2688; para “iPhone 6.7”” solo 1284×2778.

---

## 3. Formato de archivo

- **Formato:** PNG (o el que pida App Store Connect).
- **Perfil de color:** sRGB (en Mac: Preview → Herramientas → Asignar perfil → sRGB).
- **Sin transparencia** en las capturas.

---

## 4. Resumen de diferencias Impostor vs nuestras capturas

| Aspecto              | Impostor (aceptada)     | Dólar ARG (rechazadas)     |
|----------------------|-------------------------|----------------------------|
| Barra de estado      | Visible (notch/barra)   | Ocultas (modo inmersivo)   |
| Aspecto “dispositivo”| Sí                      | No                         |
| Dimensiones          | Correctas para el slot  | Correctas (1242×2688)      |

Lo más importante a replicar: **que se vea la barra de estado / notch** como en Impostor. Desactivar modo inmersivo, sacar de nuevo las capturas, y subir esas (en 1242×2688 o 1284×2778 según el slot) con PNG y sRGB.

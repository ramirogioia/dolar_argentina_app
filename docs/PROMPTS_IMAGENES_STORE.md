# Prompts para imágenes del Store — Dólar ARG

Usá estos prompts en DALL·E, Midjourney, Ideogram o similar. Ajustá el tamaño final según lo que pida cada store (feature graphic, banner, etc.).

---

## iPhone 6.5" Display — Capturas correlacionadas

**Dimensión exacta para App Store:** **1242 × 2688 px** (portrait).

Las capturas pueden **correlacionarse** entre sí: un conjunto de 3 (o más) donde cada una destaca un beneficio, con un **título arriba** y la captura dentro de un **marco de iPhone**, sobre **fondo oscuro**, como en el ejemplo de FACEBANK.

### Estilo del ejemplo (a replicar)

- **Fondo:** Negro o muy oscuro.
- **Por cada “slide”:** Bloque con título en color (celeste/teal #D9EDF7 o similar), texto en blanco o oscuro, ancho completo.
- **Debajo del título:** Marco blanco de iPhone 6.5" con la captura dentro.
- **Dentro del marco:** La captura de la app con **barra de estado visible** (hora, señal, batería, notch).
- **Correlación:** Cada imagen = un mensaje (ej. pantalla principal, tipos de dólar, notificaciones).

### Títulos sugeridos para Dólar ARG (correlacionados)

1. **Cotizaciones en tiempo real**  
   *Blue, oficial, cripto, tarjeta, MEP y CCL*

2. **Elegí banco y plataforma**  
   *Compará dólar oficial por banco y cripto por exchange*

3. **Avisos de apertura y cierre**  
   *Notificaciones del mercado del dólar*

*(Podés usar estos en Figma/Canva arriba de cada screenshot, o como base para el prompt de cada imagen.)*

### Prompt para una “slide” (título + marco iPhone + app)

```
App store screenshot layout for "Dólar ARG" app, iPhone 6.5 inch display style. Top: horizontal band with headline text "Cotizaciones en tiempo real" in white on teal/light blue background (#D9EDF7). Below: white iPhone frame with rounded corners and notch at top, containing an in-app screenshot showing dollar exchange rates on light blue background, with iOS status bar visible (time, signal, battery). Overall background black. Single slide, portrait orientation. Minimal, professional, finance app. Dimensions 1242x2688 pixels.
```

Variar solo el **headline** y la **descripción de la pantalla** para cada una de las 3:

- Slide 1: headline "Cotizaciones en tiempo real" / pantalla con lista de tipos de dólar (blue, oficial, cripto).
- Slide 2: headline "Elegí banco y plataforma" / pantalla con dropdown de banco o de exchange.
- Slide 3: headline "Avisos de apertura y cierre" / pantalla de Ajustes con notificaciones activadas.

### Cómo armarlo con capturas reales (recomendado)

1. Sacar 3 capturas de la app en **1242×2688** (emulador 6.5" o redimensionar).
2. En Figma/Canva: fondo negro, para cada una agregar arriba un rectángulo celeste con el título (tipografía bold, blanco).
3. Opcional: poner cada captura dentro de un marco de iPhone (mockup) para que se vea el notch y los bordes.
4. Exportar cada “slide” en **1242×2688** y subir al slot **iPhone 6.5" Display** en App Store Connect.

---

## Identidad de la app (referencia)

- **Nombre:** Dólar ARG
- **Qué hace:** Cotizaciones del dólar en Argentina en tiempo real (blue, oficial, cripto, tarjeta, MEP, CCL).
- **Colores:** Azul principal (#2196F3), fondo celeste claro (#D9EDF7), blanco, toques verde/rojo para variaciones.
- **Estilo:** Limpio, moderno, confiable, sin saturar.

---

## 1. Banner / Feature graphic (horizontal, para store)

```
App store promotional banner for "Dólar ARG", a clean finance app that shows real-time US dollar exchange rates in Argentina. Style: minimal and professional. Central element: a stylized icon combining US dollar symbol and Argentine flag (blue and white, sun), on a soft light blue (#D9EDF7) background with subtle gradient. Accent color: modern blue (#2196F3). No text except optional app name "Dólar ARG". Flat design, no 3D, mobile app store quality. 16:9 or 1024x500.
```

---

## 2. Icono / logo en contexto (para redes o promo)

```
Minimal app icon for a currency app "Dólar ARG": stylized dollar sign merged with Argentine flag (celeste and white stripes, sun). Modern flat design, soft light blue background, clean edges. Style: iOS/Android app icon, professional, trustworthy. No text. Square format.
```

---

## 3. Escena “cotizaciones en tiempo real”

```
Clean, modern illustration for a finance app showing real-time dollar exchange rates. Soft light blue background, floating minimal elements: subtle dollar symbols, upward and downward trend lines in light blue and soft green/red. Central focus: a simple phone mockup with a clean currency/dashboard UI. Style: flat design, professional, Argentina finance app. No realistic photos. 1:1 or 4:5.
```

---

## 4. Variante solo logo + fondo (para splash o header)

```
Minimal promotional image for "Dólar ARG" app. Large stylized icon in center: US dollar and Argentine flag combined, flat design. Background: soft gradient from light blue (#D9EDF7) to white. One accent line or curve in blue (#2196F3). No people, no text. Clean, app store quality.
```

---

## 5. Prompt corto universal (cuando tengas el logo como referencia)

```
App store banner for Dólar ARG: [describe tu logo: ej. "dollar bill with Argentine flag"]. Light blue background, blue accents, minimal flat design, professional finance app, no text, high quality for Google Play and App Store.
```

---

## Tips

- **iPhone 6.5" Display:** Subir capturas en **1242 × 2688 px**. Si armás “slides” con título + marco, exportar cada una en ese tamaño.
- **Correlación:** Las 3 (o más) capturas deben verse como una serie: mismo estilo de título, mismo marco, mismo fondo oscuro; solo cambia el mensaje y la pantalla de la app.
- **Si la herramienta acepta imagen de referencia:** Subí `app_icon_final.png` o `app_icon_apple.png` y pedí "same style and colors, in a horizontal banner for app store" (o "feature graphic 1024x500").
- **Tamaños útiles:** Feature graphic Android 1024×500; Apple puede pedir 1280×720 o similares para previews.
- **Sin texto:** Mejor generar sin texto y agregar "Dólar ARG" o tagline después en Figma/Canva para controlar fuente y posición.

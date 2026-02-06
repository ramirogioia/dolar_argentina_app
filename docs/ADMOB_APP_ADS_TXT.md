# app-ads.txt para AdMob (verificación "Dólar Argentina iOS")

AdMob no verifica la app hasta que el archivo **app-ads.txt** esté en tu **sitio web de desarrollador** con el contenido correcto.

**Archivo en este repo:** en la raíz del proyecto está **`app-ads.txt`** con la línea que pide AdMob. No lo sacás de ningún lado: ya está creado. Solo tenés que subir el repo a GitHub, activar GitHub Pages y usar esa URL (ver abajo "Opción A – GitHub Pages con este repo").

---

## ¿Qué es el “dominio” y dónde meto el archivo?

**Dominio** = la dirección de un **sitio web** que sea tuyo. Por ejemplo: `giftera-store.com`, `ramirogioia.com`, `mitienda.com`, etc. No es la app, no es tu compu: es una **página en internet** que se abre en el navegador.

**Dónde metés el archivo:** en **ese sitio web**, de forma que cualquiera pueda entrar a:

`https://TU-SITIO-WEB.com/app-ads.txt`

y ver el contenido del archivo.

---

### Si YA tenés un sitio web (ej. giftera-store.com)

1. Entrá al panel donde administrás ese sitio (hosting, cPanel, Vercel, Netlify, etc.).
2. Subí el archivo **app-ads.txt** a la **raíz** del sitio (donde está el index o la página principal), no dentro de una carpeta.
3. Comprobá que se vea en: `https://tu-dominio.com/app-ads.txt`.

Ese **mismo dominio** tiene que estar puesto en **App Store Connect** como “Sitio web del desarrollador” (donde configuraste la app). Si no coincide, AdMob no verifica.

---

### Si NO tenés ningún sitio web

Tenés que tener **alguna** URL pública para que AdMob pueda leer el archivo. Opciones sencillas:

**Opción A – GitHub Pages con este repo (gratis)**  
El archivo `app-ads.txt` ya está en la raíz del repo (no hace falta crearlo en otro lado).

1. Subí el repo a GitHub (o hacé push si ya existe).  
2. En GitHub: **Settings** → **Pages** → Source = "Deploy from a branch", branch = `main`, folder = `/ (root)` → Save.  
3. La URL del sitio queda: `https://TU-USUARIO.github.io/dolar_argentina_app/`. El archivo: `https://TU-USUARIO.github.io/dolar_argentina_app/app-ads.txt` (reemplazá TU-USUARIO por tu usuario de GitHub).  
4. En **App Store Connect** → tu app → Información de la app → "Sitio web del desarrollador" = `https://TU-USUARIO.github.io/dolar_argentina_app`.  
5. Comprobá la URL del archivo en el navegador; después en AdMob → "Verificar si hay actualizaciones".

*(Si preferís otro repo solo para app-ads:)*  
1. Creá una cuenta en GitHub si no tenés.  
2. Creá un repositorio nuevo (ej. `mi-app-ads`).  
3. Subí un archivo llamado **app-ads.txt** con la línea que te da AdMob.  
4. Activá GitHub Pages para ese repo. La URL queda tipo: `https://tuusuario.github.io/mi-app-ads/app-ads.txt`.  
5. En **App Store Connect** → tu app → Información de la app, poné como “Sitio web del desarrollador”: `https://tuusuario.github.io/mi-app-ads` (o la URL que te dé GitHub Pages).  
6. En AdMob, verificá que `https://tuusuario.github.io/mi-app-ads/app-ads.txt` se abra y muestre la línea. Después en AdMob hacé clic en **“Verificar si hay actualizaciones”**.

**Opción B – Firebase Hosting (gratis)**  
1. En Firebase Console, activá Hosting para tu proyecto.  
2. Subí una carpeta que tenga solo el archivo **app-ads.txt** en la raíz.  
3. Firebase te da una URL tipo: `https://tu-proyecto.web.app`. El archivo quedará en `https://tu-proyecto.web.app/app-ads.txt`.  
4. En **App Store Connect** poné como sitio del desarrollador: `https://tu-proyecto.web.app`.  
5. Comprobá la URL del archivo en el navegador y después “Verificar si hay actualizaciones” en AdMob.

**Opción C – Cualquier hosting que ya uses**  
Si tenés email con dominio (ej. info@giftera-store.com), a veces el proveedor te da un espacio web. Entrá a ese panel, subí **app-ads.txt** a la raíz del sitio y usá ese mismo dominio en App Store Connect y en AdMob.

---

## Qué hacer (paso a paso)

### 1. Crear el archivo app-ads.txt

Creá un archivo de texto llamado **app-ads.txt** (sin otro nombre, sin .html ni nada).  
Dentro del archivo poné **solo esta línea** (la que da AdMob):

```
google.com, pub-6119092953994163, DIRECT, f08c47fec0942fa0
```

Copiá y pegá tal cual; no cambies espacios ni comas.

### 2. Subir el archivo a la raíz de tu sitio de desarrollador

- El archivo tiene que estar en la **raíz** del dominio.
- La URL final tiene que ser: **https://TUDOMINIO.com/app-ads.txt**  
  Ejemplo: si tu sitio es `https://giftera-store.com`, el archivo debe estar en `https://giftera-store.com/app-ads.txt`.

**Importante (AdMob lo exige):** El dominio tiene que ser **el mismo** que pusiste en **App Store Connect** como “Sitio web del desarrollador” / “Developer Website”. Si en la App Store figura otro dominio, AdMob no lo va a aceptar. Revisá en App Store Connect → tu app → Información de la app → URL del sitio web.

- Si **no tenés** sitio: podés usar **Firebase Hosting**, **Vercel**, **Netlify** o cualquier hosting con un dominio que controles, y después poner **ese mismo dominio** en App Store Connect como sitio del desarrollador.

### 3. Comprobar que se ve bien

Abrí en el navegador: `https://tudominio.com/app-ads.txt`  
Tiene que mostrarse la línea:  
`google.com, pub-6119092953994163, DIRECT, f08c47fec0942fa0`

### 4. Pedir de nuevo la verificación en AdMob

En la pantalla donde AdMob dice “No pudimos verificar Dólar Argentina (iOS)”:

1. Hacé clic en el botón azul **“Verificar si hay actualizaciones”**.
2. AdMob va a revisar que el archivo exista y tenga el formato correcto. Puede tardar unos minutos o hasta 24–48 horas.

---

## Resumen del contenido (referencia)

- **Línea exacta que pide AdMob:**  
  `google.com, pub-6119092953994163, DIRECT, f08c47fec0942fa0`
- **Dónde va:** raíz del sitio del desarrollador → `https://tudominio.com/app-ads.txt`
- **Condición:** el dominio debe coincidir con el “Sitio web del desarrollador” en App Store Connect.

## 3. Link de la app en el App Store

- **URL (Argentina):** https://apps.apple.com/ar/app/d%C3%B3lar-argentina/id6758462259  
- **URL corta (por Apple ID):** https://apps.apple.com/app/id6758462259  
- **Apple ID de la app:** 6758462259  

Usá cualquiera de las dos URLs cuando AdMob pida el link de la tienda.

## 4. Después de publicar app-ads.txt

1. Verificá que `https://tudominio.com/app-ads.txt` se abra en el navegador y muestre la línea correcta.
2. En AdMob, en la verificación de la app, usá **"Verificar si hay actualizaciones"**.
3. La verificación puede tardar hasta 24–48 horas.

## Referencias

- [Configuración app-ads.txt (AdMob)](https://support.google.com/admob/answer/9363762)
- [Problemas con app-ads.txt](https://support.google.com/admob/answer/9675354)

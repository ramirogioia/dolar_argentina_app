# 🔐 Configuración de Keystore para Android

## ⚠️ IMPORTANTE

**El keystore es CRÍTICO para actualizar tu app en Google Play Store.**
- Si lo pierdes, **NO podrás actualizar la app** (tendrás que publicar una nueva)
- **Guárdalo en un lugar SEGURO** (password manager, backup encriptado, etc.)
- **NUNCA lo subas a Git** (ya está en .gitignore)

---

## 📋 SITUACIÓN ACTUAL

Tu app actualmente usa el **debug keystore** para builds de release:
```kotlin
signingConfig = signingConfigs.getByName("debug")  // ❌ No es para producción
```

Esto funciona para testing, pero **NO es válido para Google Play Store**.

---

## 🚀 OPCIÓN 1: Ya tienes un keystore

Si ya creaste un keystore antes y lo tienes guardado:

### 1. Copiar el keystore al proyecto
```bash
# Copia tu keystore a:
android/app/upload-keystore.jks
# O el nombre que le hayas dado
```

### 2. Crear archivo `android/key.properties`
```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DE_LA_KEY
keyAlias=TU_KEY_ALIAS
storeFile=upload-keystore.jks
```

**⚠️ IMPORTANTE:** Este archivo contiene passwords. **NO lo subas a Git** (ya está en .gitignore).

### 3. Configurar build.gradle.kts
Ya está configurado (ver `android/app/build.gradle.kts`).

### 4. Listo! Puedes compilar:
```bash
flutter build appbundle --release
# O
flutter build apk --release
```

---

## 🆕 OPCIÓN 2: Crear un keystore nuevo

### 1. Crear el keystore
```bash
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Te pedirá:**
- **Password del keystore** (guárdala bien!)
- **Password de la key** (puede ser la misma)
- **Nombre completo, organización, etc.** (puedes poner lo que quieras)

**Ejemplo:**
```
Enter keystore password: [tu password]
Re-enter new password: [tu password]
What is your first and last name?
  [Unknown]: Ramiro Gioia
What is the name of your organizational unit?
  [Unknown]: Development
What is the name of your organization?
  [Unknown]: Dolar Argentina
What is the name of your City or Locality?
  [Unknown]: Buenos Aires
What is the name of your State or Province?
  [Unknown]: Buenos Aires
What is the two-letter country code for this unit?
  [Unknown]: AR
Is CN=... correct?
  [no]: yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
        for: CN=Ramiro Gioia, OU=Development, O=Dolar Argentina, L=Buenos Aires, ST=Buenos Aires, C=AR
Enter key password for <upload>
        (RETURN if same as keystore password): [Enter para usar la misma]
```

### 2. Crear archivo `android/key.properties`
```bash
cd android
nano key.properties
# O usa tu editor favorito
```

**Contenido:**
```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DE_LA_KEY
keyAlias=upload
storeFile=app/upload-keystore.jks
```

**Reemplaza:**
- `TU_PASSWORD_DEL_KEYSTORE` → La password que pusiste al crear el keystore
- `TU_PASSWORD_DE_LA_KEY` → La password de la key (o la misma si usaste la misma)
- `upload` → El alias que usaste (o el que quieras)

### 3. Verificar que build.gradle.kts esté configurado
Ya debería estar configurado. Si no, ver instrucciones abajo.

### 4. Compilar
```bash
flutter build appbundle --release
# O
flutter build apk --release
```

---

## 📁 ESTRUCTURA DE ARCHIVOS

Después de configurar, deberías tener:

```
android/
├── key.properties          ← Contiene passwords (NO subir a Git)
├── app/
│   ├── upload-keystore.jks  ← El keystore (NO subir a Git)
│   └── build.gradle.kts     ← Ya configurado para leer key.properties
```

---

## 🔍 VERIFICAR QUE FUNCIONA

### Compilar en release:
```bash
flutter build appbundle --release
```

**Si funciona correctamente:**
- ✅ No pedirá passwords manualmente
- ✅ Generará `build/app/outputs/bundle/release/app-release.aab`
- ✅ El AAB estará firmado con tu keystore

**Si falla:**
- ❌ Verifica que `key.properties` tenga las passwords correctas
- ❌ Verifica que `upload-keystore.jks` esté en `android/app/`
- ❌ Verifica que el alias en `key.properties` coincida con el del keystore

---

## 🔐 SEGURIDAD

### ✅ HACER:
- Guardar el keystore en un lugar seguro (password manager, backup encriptado)
- Guardar las passwords en un password manager
- Hacer backup del keystore en múltiples lugares seguros
- Documentar el alias y passwords (en lugar seguro)

### ❌ NO HACER:
- Subir el keystore a Git (ya está en .gitignore)
- Subir `key.properties` a Git (ya está en .gitignore)
- Compartir el keystore públicamente
- Perder el keystore (no podrás actualizar la app)

---

## 🆘 SI PERDISTE EL KEYSTORE

**Si perdiste el keystore y ya publicaste la app en Google Play:**

1. **NO puedes actualizar la app existente** con un keystore nuevo
2. **Opciones:**
   - Contactar a Google Play Support (pueden ayudar en casos excepcionales)
   - Publicar una nueva app con nuevo package name
   - Si tienes backup, restaurarlo

**Por eso es CRÍTICO guardar el keystore de forma segura.**

---

## 📝 NOTAS

- El keystore es válido por 10,000 días (~27 años) por defecto
- Puedes usar el mismo keystore para múltiples apps (aunque no es recomendado)
- El alias puede ser cualquier nombre (ej: "upload", "release", "production")
- Las passwords pueden ser diferentes para keystore y key, o la misma

---

## 🔄 COMPARTIR CON OTRO DESARROLLADOR

Si necesitas que otro desarrollador compile la app:

1. **Comparte el keystore** (de forma segura, encriptado):
   ```bash
   # Enviar: android/app/upload-keystore.jks
   ```

2. **Comparte las passwords** (de forma segura, password manager o mensaje encriptado):
   - Password del keystore
   - Password de la key
   - Alias usado

3. **El otro desarrollador:**
   - Copia el keystore a `android/app/upload-keystore.jks`
   - Crea `android/key.properties` con las passwords
   - Puede compilar normalmente

---

**Última actualización:** 2026-02-06



# Certificado para exportar IPA (App Store / TestFlight)

Si `./ios/build_archive.sh` falla con **"No signing certificate 'iOS Distribution' found"** o similar, necesitás instalar el certificado de distribución.

---

## 1. Crear / descargar el certificado

1. Entrá a [developer.apple.com/account](https://developer.apple.com/account)
2. **Certificates, Identifiers & Profiles** → **Certificates**
3. **+** para crear uno nuevo
4. Elegí **Apple Distribution** (para App Store / TestFlight)
5. Continuá y generá la solicitud CSR (Certificate Signing Request):
   - En Mac: **Keychain Access** → menú **Keychain Access** → **Certificate Assistant** → **Request a Certificate From a Certificate Authority**
   - Email: tu email de Apple ID
   - Common Name: ej. "Dólar ARG Distribution"
   - Saved to disk → Guardá el `.certSigningRequest`
6. Subí el `.certSigningRequest` en la web de Apple
7. **Download** el certificado `.cer`
8. **Doble clic** en el `.cer` para instalarlo en el Keychain de login

---

## 2. Verificar que se instaló

En la terminal:

```bash
security find-identity -v -p codesigning
```

Deberías ver algo como:

```
1) XXXXX "Apple Distribution: Tu Nombre (93QAZPHZ99)"
    1 valid identities found
```

o

```
1) XXXXX "iOS Distribution: Tu Nombre (93QAZPHZ99)"
    1 valid identities found
```

Si ves `0 valid identities found`, el certificado no está instalado o está en otro keychain.

---

## 3. Si ExportOptions usa un nombre distinto

El `ExportOptions.plist` tiene `signingCertificate: "iOS Distribution"`. Si tu certificado aparece como `"Apple Distribution: ..."`, probá cambiar en `ios/ExportOptions.plist`:

```xml
<key>signingCertificate</key>
<string>Apple Distribution</string>
```

---

## 4. Xcode: cuenta y perfiles

Si además ves "No accounts" o "Invalid trust settings":

1. Abrí Xcode: `open -a Xcode ios/Runner.xcworkspace`
2. **Xcode** → **Settings** (⌘,) → **Accounts**
3. Agregá tu Apple ID (Team 93QAZPHZ99)
4. Click en **Download Manual Profiles**
5. Cerrá Xcode y volvé a ejecutar `./ios/build_archive.sh`

---

## 5. Después del export

Cuando el IPA se genere en `build/ipa/`, verificá que incluya Push:

```bash
./ios/verify_ipa_push.sh
```

Debería decir que el IPA incluye `aps-environment` (necesario para notificaciones en iOS).

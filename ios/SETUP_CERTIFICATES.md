# Configuración de Certificados para iOS Build

## Problema
`xcodebuild` necesita certificados de code signing para exportar el IPA. Si ves "0 valid identities found", necesitas instalar los certificados.

## Solución 1: Descargar desde Apple Developer Portal (Recomendado)

### Paso 1: Acceder al Portal
1. Ve a https://developer.apple.com/account
2. Inicia sesión con tu Apple ID (el que tiene el Team ID: 93QAZPHZ99)

### Paso 2: Descargar Certificado de Distribution
1. Ve a **Certificates, Identifiers & Profiles**
2. Click en **Certificates** en el menú lateral
3. Click en el **+** (crear nuevo) o busca uno existente de tipo **Apple Distribution**
4. Si no existe, créalo:
   - Selecciona **Apple Distribution**
   - Sube un Certificate Signing Request (CSR) - ver abajo cómo generarlo
5. Descarga el certificado (archivo `.cer`)

### Paso 3: Generar CSR (si necesitas crear certificado nuevo)
```bash
# Abrir Keychain Access
open -a "Keychain Access"

# O desde terminal:
# 1. Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
# 2. Email: tu-email@example.com
# 3. Common Name: Tu Nombre
# 4. CA Email: (dejar vacío)
# 5. Saved to disk: ✓
# 6. Guardar como CertificateSigningRequest.certSigningRequest
```

### Paso 4: Instalar el Certificado
```bash
# Doble click en el archivo .cer descargado
# O desde terminal:
open /ruta/al/certificado.cer

# El certificado se instalará automáticamente en el keychain
```

### Paso 5: Verificar Instalación
```bash
security find-identity -v -p codesigning
# Deberías ver algo como:
# 1) ABC123... "Apple Distribution: Tu Nombre (93QAZPHZ99)"
```

## Solución 2: Usar Xcode (Más Fácil)

Si puedes abrir Xcode brevemente:

```bash
# Abrir Xcode
open -a Xcode ios/Runner.xcworkspace

# En Xcode:
# 1. Xcode > Settings (⌘,) > Accounts
# 2. Click en "+" > Apple ID
# 3. Ingresa tu Apple ID y contraseña
# 4. Selecciona el Team 93QAZPHZ99
# 5. Click en "Download Manual Profiles"
# 6. Xcode descargará automáticamente certificados y profiles
```

## Solución 3: Usar Otra Máquina

Si tienes otra Mac con Xcode configurado:
1. Exporta el archive desde esa máquina
2. O copia los certificados (exportar desde Keychain en la Mac con certificados e importar en esta)

## Después de Instalar Certificados

Una vez instalados, vuelve a ejecutar:
```bash
cd ios
./build_archive.sh
```

El export debería funcionar ahora.

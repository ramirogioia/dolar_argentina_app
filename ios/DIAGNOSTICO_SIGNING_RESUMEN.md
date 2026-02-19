# Diagnóstico: por qué falla el export y qué hacer

## Lo que encontré

### 1. Perfil de provisioning ✅

Tenés **un solo perfil** para esta app: **"Dólar ARG App Store"**, y tiene **Push** (`aps-environment`). Ese es el correcto.

### 2. Certificados ❌

En tu Mac hay **0 certificados de Distribution** disponibles para firmar. Por eso falla el export con:

```
No signing certificate "iOS Distribution" found
```

### 3. Automatic vs manual

- **Automatic**: Xcode elige perfil y certificado. Como no tenés certificado local, el export falla. En teoría podría usar certificados en la nube, pero con `xcodebuild` por línea de comandos no está claro que eso funcione.
- **Manual**: Nos permite forzar el perfil "Dólar ARG App Store" (con Push), pero igual hace falta un certificado local que coincida con ese perfil.

## Conclusión: sí, hace falta el certificado

Hay que instalar el certificado **Apple Distribution** en tu Mac. No alcanza con el perfil.

Cuando lo instales:
- **Firma automática**: debería volver a funcionar; Xcode usará tu cert y el único perfil que tenés (con Push).
- **Firma manual**: podés usarla para forzar explícitamente "Dólar ARG App Store" y asegurarte de usar el perfil correcto.

## Pasos para instalarlo

1. Ir a [developer.apple.com/account](https://developer.apple.com/account) → Certificates
2. Si ya tenés un cert "Apple Distribution" → Download
3. Si no tenés → Create → Apple Distribution → generar CSR en Keychain Access → subir CSR → Download
4. En el Mac → doble clic en el `.cer` descargado para instalarlo en el Keychain

## Alternativa: exportar desde Xcode (GUI)

Si el certificado está en la nube o en Xcode:

1. Abrir el proyecto: `open -a Xcode ios/Runner.xcworkspace`
2. Product → Archive
3. Distribute App → App Store Connect → Upload

A veces la GUI usa certificados en la nube cuando la línea de comandos no puede.

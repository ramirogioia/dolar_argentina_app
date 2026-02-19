# Checklist pre-release (antes de generar el IPA)

## 1. Versión

- [ ] `pubspec.yaml`: versión actualizada (ej. `1.2.4+17`)

## 2. Build

```bash
flutter clean
./ios/build_archive.sh
```

Si el export falla con "No signing certificate":
- Abrí `ios/ExportOptions.plist`
- Probá `signingStyle: automatic` (sin `provisioningProfiles`)  
  o agregá `signingCertificate: Apple Distribution`

## 3. Verificar el IPA

```bash
./ios/verify_ipa_push.sh
```

Debe mostrar:
- ✅ Perfil incluye Push (aps-environment)
- ✅ Binario firmado con aps-environment
- ✅ GoogleService-Info.plist presente

## 4. Subir a TestFlight

1. Abrí **Transporter** (Mac App Store)
2. Arrastrá `build/ipa/dolar_argentina_app.ipa`
3. Esperá que termine el upload

## 5. En el iPhone

1. Desinstalá la app
2. Reiniciá el iPhone
3. Instalá el build nuevo desde TestFlight
4. Al abrir, aceptá notificaciones
5. Ajustes → Debug: copiá el log si sigue fallando

## 6. Firebase (cuando el token funcione)

- Firebase Console → Cloud Messaging → Configuración de apps de Apple
- Subí la clave APNs (.p8) si no la tenés

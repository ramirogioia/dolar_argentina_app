# Push iOS: opciones si sigue sin funcionar

Si después de subir el IPA a TestFlight y reinstalar la app el error 3000 ("no aps-environment") persiste, estas son las opciones restantes.

---

## 1. Verificar qué IPA estás instalando

- En **TestFlight**, cuando instalás, mirá el **número de build** (ej. 1.2.4 (16)).
- En **Ajustes** de la app, la versión debe coincidir con el build que subiste.
- Si hay varios builds, asegurate de instalar el más reciente.

---

## 2. Verificación exhaustiva del IPA

Antes de subir, ejecutá:

```bash
./ios/verify_ipa_push.sh
```

Revisá que:
- **Perfil** tenga `aps-environment = production`
- **Binario** (codesign) tenga `aps-environment` en sus entitlements
- Si el binario NO tiene aps-environment pero el perfil sí, el export puede estar usando un perfil distinto. Probá el paso 3.

---

## 3. Forzar perfil con Push (manual)

En `ios/ExportOptions.plist` ya está configurado:
- `signingStyle: manual`
- `provisioningProfiles`: `com.rgioia.dolarargentina` → `"Dólar ARG App Store"`

Si el export falla con "No signing certificate", agregá:

```xml
<key>signingCertificate</key>
<string>Apple Distribution</string>
```

(o `iOS Distribution` si tu certificado aparece así en Keychain).

---

## 4. Android vs iOS – entornos

- **Android**: FCM no distingue dev/prod para el token. El mismo token sirve en debug y release.
- **iOS**: APNs tiene dos entornos: **sandbox** (debug) y **production** (TestFlight/App Store). El build de TestFlight usa `aps-environment = production` y eso está bien.
- Las notificaciones que envías desde el backend/Firebase van al mismo topic `all_users`. Si Android las recibe, el backend está bien. El problema en iOS es que no se obtiene el token APNs (error 3000), no el envío.

---

## 5. Firebase – clave APNs (.p8)

Cuando el token APNs llegue bien, vas a necesitar la clave .p8 en Firebase para que FCM pueda enviar a iOS:

- **Firebase Console** → Configuración → Cloud Messaging → Configuración de apps de Apple
- Subí la clave .p8 (creada en developer.apple.com → Keys → Apple Push Notifications)
- Sin esto, aunque el token funcione, las notificaciones no llegarán a iOS.

---

## 6. Build desde Xcode (alternativa)

Si el script falla o querés comparar:

1. Abrí Xcode: `open -a Xcode ios/Runner.xcworkspace`
2. Product → Archive
3. Distribute App → App Store Connect → Upload
4. Revisá en Xcode que el perfil de firma sea el correcto (con Push).

---

## 7. Regenerar perfil de distribución

1. **developer.apple.com** → Profiles → buscá "Dólar ARG App Store"
2. Edit → Regenerate → Download
3. Doble clic en el .mobileprovision para instalarlo
4. En Xcode: Settings → Accounts → Download Manual Profiles
5. Volvé a ejecutar `./ios/build_archive.sh`

---

## 8. Checklist rápido

| Qué | Dónde |
|-----|-------|
| App ID con Push | developer.apple.com → Identifiers → com.rgioia.dolarargentina |
| Perfil Distribution con Push | Profiles → Dólar ARG App Store |
| aps-environment = production | ios/Runner/Runner.entitlements |
| GoogleService-Info.plist en bundle | verify_ipa_push.sh → sección 4 |
| Clave .p8 en Firebase | Firebase Console → Cloud Messaging |

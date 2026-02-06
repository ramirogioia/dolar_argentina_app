# Cómo hacer el release

La versión se define en **`pubspec.yaml`**:

```yaml
version: 1.2.0+4   # 1.2.0 = versión visible (versionName / CFBundleShortVersionString)
                   # 4 = build number (versionCode / CFBundleVersion)
```

Android e iOS toman esta versión al hacer `flutter build`. No hace falta tocar `build.gradle` ni Xcode a mano.

## Antes del release

1. **Actualizar versión en `pubspec.yaml`**
   - Incrementar versión (ej. 1.2.0 → 1.2.1 o 1.3.0) y build number (ej. +4 → +5).

2. **Completar `CHANGELOG.md`**
   - Bajar la sección `[1.1.0] - (pendiente)` y reemplazar por la fecha real.
   - Completar Agregado / Cambiado / Corregido según lo que incluyas en el release.

3. **Probar en dispositivo real**
   - `flutter run` en Android e iOS (o al menos uno).
   - Probar notificaciones, mailto de contacto, y que la versión se vea bien en Ajustes.

## Build para stores

**Android (AAB para Play Store):**
```bash
flutter build appbundle
```
Salida: `build/app/outputs/bundle/release/app-release.aab`

**iOS (para TestFlight / App Store):**
```bash
flutter build ios
```
Luego abrir `ios/Runner.xcworkspace` en Xcode y usar Product → Archive para subir a App Store Connect.

## Después del release

- Etiquetar en git: `git tag v1.2.0`
- Subir el tag: `git push origin v1.2.0`
- Para el próximo release: incrementar versión y/o build number en `pubspec.yaml` (ej. `1.2.0+5` para otra build de la misma versión, o `1.3.0+5` para una nueva versión).

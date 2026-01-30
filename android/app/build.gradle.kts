plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rgioia.dolarargentina"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Habilitar core library desugaring (requerido por flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.rgioia.dolarargentina"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("x86_64", "arm64-v8a")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    // Core library desugaring (requerido por flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// Aplicar Google Services y Crashlytics solo si existe google-services.json
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    println("✅ google-services.json encontrado, aplicando plugins de Firebase")
} else {
    println("⚠️ google-services.json no encontrado. Firebase no funcionará en Android hasta que agregues el archivo.")
    println("   Descarga el archivo desde Firebase Console y colócalo en android/app/google-services.json")
}

flutter {
    source = "../.."
}

// Configurar tareas de compilación Java para suprimir warnings de Java 8 obsoleto
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.addAll(listOf(
        "-Xlint:-options",  // Suprimir warnings de Java 8 obsoleto
        "-Xlint:-deprecation",  // Suprimir warnings de APIs deprecadas
        "-Xlint:-unchecked"  // Suprimir warnings de operaciones unchecked
    ))
}

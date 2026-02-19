import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar key.properties para firma de release (no commitear; ver docs/ANDROID_RELEASE.md)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rgioia.dolarargentina"
    compileSdk = 35  // Para targetSdk 35 (requisito Play Store)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Habilitar core library desugaring (requerido por flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.rgioia.dolarargentina"
        minSdk = flutter.minSdkVersion
        targetSdk = 35  // Play Store requiere al menos API 35 (nov 2025)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("x86_64", "arm64-v8a")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

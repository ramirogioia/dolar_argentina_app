buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services plugin (necesario para Firebase)
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    // Configurar Java 17 para todos los subproyectos (plugins) y suprimir warnings
    afterEvaluate {
        // Configurar para proyectos Android
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
        
        // Configurar para tareas de compilación Java y suprimir warnings de Java 8 obsoleto
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
            // Suprimir warnings sobre Java 8 obsoleto y deprecated APIs
            options.compilerArgs.addAll(listOf(
                "-Xlint:-options",  // Suprimir warnings de Java 8 obsoleto
                "-Xlint:-deprecation"  // Suprimir warnings de APIs deprecadas
            ))
        }
        
        // Configurar para tareas de compilación Kotlin
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

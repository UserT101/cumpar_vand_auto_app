plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.gms.google-services") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- SOLUȚIA "INSTANT" PENTRU PLUGIN-URI ---
subprojects {
    // Această metodă se declanșează IMEDIAT ce un plugin este detectat,
    // evitând eroarea "It is too late to set compileSdk"
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        
        // Setăm SDK-ul direct pe proprietate, nu prin funcție
        android.compileSdk = 36
        
        android.defaultConfig {
            minSdk = 23
            targetSdk = 36
        }

        // Fix pentru namespace
        if (android.namespace == null) {
            android.namespace = "com.paul.auto.plugins.${project.name.replace("-", "_")}"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
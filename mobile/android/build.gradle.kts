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
    // Required by Flutter plugin loader / AGP evaluation order for this template.
    project.evaluationDependsOn(":app")
}

subprojects {
    configurations.configureEach {
        resolutionStrategy {
            // maplibre_gl 0.21 bundled Android 11.6.1 without PMTiles.
            // 11.9.0 is the first Android SDK with pmtiles:// (needed for DACH style).
            force("org.maplibre.gl:android-sdk:11.9.0")
        }
    }
}

// Force compileSdk 36 on Android library plugins (sentry_flutter etc. still pin 34).
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aetherride.aetherride_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.aetherride.aetherride_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // App Links hosts (must match /.well-known/assetlinks.json on that domain)
        // Override: -PappLinkHost=your.domain.com  (primary) / appLinkHostAlt
        val appLinkHost =
            (project.findProperty("appLinkHost") as String?)
                ?: "aetherride.vercel.app"
        val appLinkHostAlt =
            (project.findProperty("appLinkHostAlt") as String?)
                ?: "aetherride.app"
        manifestPlaceholders["appLinkHost"] = appLinkHost
        manifestPlaceholders["appLinkHostAlt"] = appLinkHostAlt
        ndk {
            // Ship arm64 (devices) + x86_64 (emulator) when present under jniLibs.
            abiFilters += listOf("arm64-v8a", "x86_64")
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
            // Prefer upload keystore; fall back to debug only for local smoke APKs.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs {
            // Prefer our packaged libc++_shared / protobuf over duplicates from plugins.
            pickFirsts += listOf("**/libc++_shared.so", "**/libprotobuf.so")
            // Android 15+ 16 KB page-size: keep native libs uncompressed so
            // the zip aligner can place them on 16 KB boundaries (AGP 8.5+/9).
            // Do NOT enable useLegacyPackaging — that compresses .so and breaks
            // 16 KB installability on devices with 16 KB pages.
            useLegacyPackaging = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Optional: copy cargo-built routing_core (+ protobuf / c++_shared) into jniLibs.
// Manual: ./scripts/routing/install-android-jni.sh
// Skipped when the cargo artifact is absent (does not fail the app build).
val routingCoreSo =
    file(
        "${project.projectDir}/../../packages/routing_core/native/target/" +
            "aarch64-linux-android/release/librouting_core.so",
    )
val routingJniDir = file("${project.projectDir}/src/main/jniLibs/arm64-v8a")

tasks.register<Exec>("installRoutingCoreJni") {
    workingDir = rootProject.projectDir.parentFile.parentFile
    commandLine("bash", "scripts/routing/install-android-jni.sh")
    inputs.file(routingCoreSo)
    outputs.dir(routingJniDir)
    onlyIf { routingCoreSo.exists() }
}

tasks.named("preBuild").configure {
    dependsOn("installRoutingCoreJni")
}

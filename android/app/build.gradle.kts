import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Written by the release workflow from repo secrets, and git-ignored. Absent on
// a developer machine, where the debug key is the right answer.
//
// The signing key must never change once a build has shipped: Android refuses
// to install an update signed with a different key, which would break in-app
// self-update for everyone who already has the app.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.xman4289.xdreamer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.xman4289.xdreamer"
        minSdk = 24                      // image_picker + video_player + gal
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // NOTE: `ndk.abiFilters` does NOT trim the Flutter engine. It is
            // packaged by the Flutter Gradle plugin, which ignores the filter —
            // verified: a build with arm64-v8a/armeabi-v7a filters still shipped
            // 19MB of lib/x86_64. Use `--target-platform` on the CLI instead;
            // the release workflow passes it. See README.
            signingConfig = if (keystoreProperties.containsKey("storeFile")) {
                signingConfigs.getByName("release")
            } else {
                // Keeps `flutter build apk --release` working locally. A build
                // signed this way must not be published — the updater would
                // then be unable to replace it.
                signingConfigs.getByName("debug")
            }

            // Bearer tokens and the API base URL live in this binary. Shrinking
            // and obfuscating does not make it secure — nothing secret is
            // compiled in — but it raises the cost of reading the API surface
            // straight out of a decompiled APK.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

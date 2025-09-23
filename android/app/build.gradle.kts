plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services (kept last is fine in plugins DSL)
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.gymmate"
    // Some plugins (e.g., mobile_scanner) require SDK 36. Compile with the highest available.
    compileSdk = 36
    // Match Firebase native SDK requirement
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.gymmate"
    // Firebase (Auth/Core/Firestore) require minSdk >= 23
    minSdk = 23
    // Target 35 is broadly compatible; you can raise to 36 when ready
    targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by some dependencies (e.g., flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring support for newer Java APIs on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

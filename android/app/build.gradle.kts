import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smartmuezzin.app"
    // 37, not Flutter's default 36: home_widget 0.8.1 pulls in
    // androidx.glance:glance-appwidget:1.3.0-alpha02, whose AAR metadata
    // requires compiling against Android API 37 or later
    // (:app:checkReleaseAarMetadata). targetSdk stays at Flutter's
    // default; only compileSdk is raised, which opts into no new
    // runtime behaviour.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications' AAR metadata
        // (:app:checkReleaseAarMetadata); its code uses java.time APIs
        // that need core library desugaring below minSdk 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.smartmuezzin.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Filled by CI from secrets (see .github/workflows/build-apk.yml).
            // Locally, create android/key.properties (git-ignored) with:
            //   storeFile=/path/to/upload-keystore.jks
            //   storePassword=...
            //   keyAlias=upload
            //   keyPassword=...
            if (file("key.properties").exists()) {
                val props = Properties()
                props.load(file("key.properties").inputStream())
                storeFile = file(props.getProperty("storeFile"))
                storePassword = props.getProperty("storePassword")
                keyAlias = props.getProperty("keyAlias")
                keyPassword = props.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Signed with the upload key when key.properties exists,
            // otherwise with the debug key so the APK still builds.
            signingConfig =
                if (file("key.properties").exists()) {
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
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

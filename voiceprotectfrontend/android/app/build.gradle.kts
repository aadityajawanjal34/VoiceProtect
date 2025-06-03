plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

android {
    namespace = "com.example.aadi"
    compileSdk = 35 // Replace flutter.compileSdkVersion with actual value
    ndkVersion = "27.0.12077973" // ✅ Explicitly set correct NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.aadi"
        minSdk = 21  // ✅ Set actual minSdk version
        targetSdk = 35 // ✅ Set actual targetSdk version
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Debug signing for now
        }
    }
}

flutter {
    source = "../.."
}

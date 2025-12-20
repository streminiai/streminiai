plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Updated to match Root definition
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.stremini_chatbot"
    compileSdk = 35 // 36 is likely Canary/Preview. 35 is Android 15 (current stable-ish).
    ndkVersion = "26.1.10909125" // Adjusted to a common stable NDK, or keep yours if installed.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Java 21 is very new for Android compilation, 17 is safer for now.
    }

    kotlinOptions {
        jvmTarget = "17" // Must match compileOptions above
    }

    defaultConfig {
        applicationId = "com.example.stremini_chatbot"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        vectorDrawables.useSupportLibrary = true
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    // 'packagingOptions' is deprecated in newer AGP, replaced by 'packaging' block
    packaging {
        resources {
            excludes += "META-INF/DEPENDENCIES"
            excludes += "META-INF/LICENSE"
            excludes += "META-INF/LICENSE.txt"
            excludes += "META-INF/NOTICE"
            excludes += "META-INF/NOTICE.txt"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.11.0")
    implementation("org.json:json:20231013")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("com.google.android.play:core:1.10.3")
    implementation("androidx.cardview:cardview:1.0.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}
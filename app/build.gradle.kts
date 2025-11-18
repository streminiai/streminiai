plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.stremniapp"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.stremniapp"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            // Turn off shrinking for now
            minifyEnabled false
            shrinkResources false

            // If you want proguard/shrinking later, enable these:
            // minifyEnabled true
            // shrinkResources true
            // proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source "../.."
}

dependencies {
    implementation "androidx.core:core-ktx:1.15.0"
    implementation "androidx.appcompat:appcompat:1.7.0"
    implementation "com.google.android.material:material:1.12.0"
}

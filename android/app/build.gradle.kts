plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace "com.example.medicinnect"
    compileSdk flutter.compileSdkVersion
            ndkVersion flutter.ndkVersion

            compileOptions {
                sourceCompatibility JavaVersion.VERSION_1_8
                        targetCompatibility JavaVersion.VERSION_1_8
            }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.example.medicinnect"
        minSdk 21
        targetSdk flutter.targetSdkVersion
                versionCode flutter.versionCode
                versionName flutter.versionName
                multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
                    minifyEnabled false
            shrinkResources false
        }
    }
}

flutter {
    source "../.."
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.23"
    implementation "androidx.multidex:multidex:2.0.1"
    implementation platform("com.google.firebase:firebase-bom:33.1.0")
    implementation "com.google.firebase:firebase-analytics"
}
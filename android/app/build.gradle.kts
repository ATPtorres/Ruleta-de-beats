plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

val installCheckBuild = providers.gradleProperty("beatRouletteInstallCheck")
    .map { it == "true" }
    .getOrElse(false)

android {
    namespace = "com.alemnt.beats.roulette"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = if (installCheckBuild) "com.alemnt.beats.roulette.pruebas" else "com.alemnt.beats.roulette"
        resValue("string", "app_name", if (installCheckBuild) "Beat Roulette Pruebas" else "Beat Roulette")
        minSdk = 29
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

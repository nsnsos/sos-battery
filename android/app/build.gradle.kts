import java.util.Properties
import java.io.FileInputStream

// 1. Đọc file key.properties bằng Java Properties (Chuẩn và an toàn nhất)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.sosbattery.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // 2. Cấu hình signingConfigs PHẢI nằm trước buildTypes
    signingConfigs {
        create("release") {
        storeFile = file("upload-keystore.jks")  // tên file keystore
        storePassword = "123456"  // password keystore
        keyAlias = "upload"  // alias bro nhập khi tạo
        keyPassword = "123456"  // password key (thường giống storePassword)
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sosbattery.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
